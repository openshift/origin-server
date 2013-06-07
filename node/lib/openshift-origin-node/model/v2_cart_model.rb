#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require 'rubygems'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/model/pub_sub_connector'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/selinux'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/managed_files'
require 'openshift-origin-node/utils/sanitize'

module OpenShift
  class FileLockError < Exception
    attr_reader :filename

    def initialize(msg = nil, filename)
      super(msg)
      @filename = filename
    end
  end

  class FileUnlockError < Exception
    attr_reader :filename

    def initialize(msg = nil, filename)
      super(msg)
      @filename = filename
    end
  end

  class V2CartridgeModel
    include NodeLogger
    include ManagedFiles

    def initialize(config, user, state, hourglass)
      @config     = config
      @user       = user
      @state      = state
      @timeout    = 30
      @cartridges = {}
      @hourglass  = hourglass
    end

    def stop_lock
      File.join(@user.homedir, 'app-root', 'runtime', '.stop_lock')
    end

    def stop_lock?
      File.exists?(stop_lock)
    end

    ##
    # Yields a +Cartridge+ instance for each cartridge in the gear.
    def each_cartridge
      process_cartridges do |cartridge_dir|
        cartridge = get_cartridge_from_directory(File.basename(cartridge_dir))
        yield cartridge
      end
    end

    ##
    # Returns the primary +Cartridge+ in the gear as specified by the
    # +OPENSHIFT_PRIMARY_CARTRIDGE_DIR+ environment variable, or +Nil+ if
    # no primary cartridge is present.
    def primary_cartridge
      env              = Utils::Environ.for_gear(@user.homedir)
      primary_cart_dir = env['OPENSHIFT_PRIMARY_CARTRIDGE_DIR']

      raise "No primary cartridge detected in gear #{@user.uuid}" unless primary_cart_dir

      return get_cartridge_from_directory(File.basename(primary_cart_dir))
    end

    ##
    # Returns the +Cartridge+ in the gear whose +web_proxy+ flag is set to
    # true, nil otherwise
    def web_proxy
      each_cartridge do |cartridge|
        return cartridge if cartridge.web_proxy?
      end
      nil
    end

    ##
    # Detects and returns a builder +Cartridge+ in the gear if present, otherwise +nil+.
    def builder_cartridge
      builder_cart = nil
      each_cartridge do |c|
        if c.categories.include? 'ci_builder'
          builder_cart = c
          break
        end
      end
      builder_cart
    end

    # FIXME: Once Broker/Node protocol updated to provided necessary information this hack must go away
    def map_cartridge_name(cartridge_name)
      results = cartridge_name.scan(/([a-zA-Z\d-]+)-([\d\.]+)/).first
      raise "Invalid cartridge identifier '#{cartridge_name}': expected name-version" unless results && 2 == results.size
      results
    end

    def cartridge_directory(cart_name)
      name, _  = map_cartridge_name(cart_name)
      cart_dir = Dir.glob(PathUtils.join(@user.homedir, "#{name}"))
      raise "Ambiguous cartridge name #{cart_name}: found #{cart_dir}:#{cart_dir.size}" if 1 < cart_dir.size
      raise "Cartridge directory not found for #{cart_name}" if  1 > cart_dir.size

      File.basename(cart_dir.first)
    end

    # Load the cartridge's local manifest from the Broker token 'name-version'
    def get_cartridge(cart_name)
      unless @cartridges.has_key? cart_name
        cart_dir = ''
        begin
          cart_dir = cartridge_directory(cart_name)

          @cartridges[cart_name] = get_cartridge_from_directory(cart_dir)
        rescue Exception => e
          logger.error e.message
          logger.error e.backtrace.join("\n")
          raise "Failed to get cartridge '#{cart_name}' from #{cart_dir} in gear #{@user.uuid}: #{e.message}"
        end
      end

      @cartridges[cart_name]
    end

    # Load cartridge's local manifest from cartridge directory name
    def get_cartridge_from_directory(directory)
      raise "Directory name is required" if (directory == nil || directory.empty?)

      unless @cartridges.has_key? directory
        cartridge_path = PathUtils.join(@user.homedir, directory)
        manifest_path  = PathUtils.join(cartridge_path, 'metadata', 'manifest.yml')
        ident_path     = Dir.glob(PathUtils.join(cartridge_path, 'env', "OPENSHIFT_*_IDENT")).first

        raise "Cartridge manifest not found: #{manifest_path} missing" unless File.exists?(manifest_path)
        raise "Cartridge Ident not found: #{ident_path} missing" unless File.exists?(ident_path)

        _, _, version, _ = Runtime::Manifest.parse_ident(IO.read(ident_path))

        @cartridges[directory] = OpenShift::Runtime::Manifest.new(manifest_path, version, @user.homedir)
      end
      @cartridges[directory]
    end

    # destroy(skip_hooks = false) -> [buffer, '', 0]
    #
    # Remove all cartridges from a gear and delete the gear.  Accepts
    # and discards any parameters to comply with the signature of V1
    # require, which accepted a single argument.
    #
    # destroy() => ['', '', 0]
    def destroy(skip_hooks = false)
      logger.info('V2 destroy')

      buffer = ''
      unless skip_hooks
        each_cartridge do |cartridge|
          unlock_gear(cartridge, false) do |c|
            begin
              buffer << cartridge_teardown(c.directory, false)
            rescue Utils::ShellExecutionException => e
              logger.warn("Cartridge teardown operation failed on gear #{@user.uuid} for cartridge #{c.directory}: #{e.message} (rc=#{e.rc})")
            end
          end
        end
      end

      # Ensure we're not in the gear's directory
      Dir.chdir(@config.get("GEAR_BASE_DIR"))

      @user.destroy

      # FIXME: V1 contract is there a better way?
      [buffer, '', 0]
    end

    # tidy() -> nil
    #
    # Run tidy operation on each cartridge on a gear
    #
    # tidy()
    def tidy
      each_cartridge do |cartridge|
        begin
          output = do_control('tidy', cartridge)
        rescue Utils::ShellExecutionException => e
          logger.warn("Tidy operation failed for cartridge #{cartridge.name} on "\
                      "gear #{@user.uuid}: #{e.message} (rc=#{e.rc}), output=#{output}")
        end
      end
    end

    # configure(cartridge_name, template_git_url, manifest) -> stdout
    #
    # Add a cartridge to a gear
    #
    # configure('php-5.3')
    # configure('php-666', 'git://')
    # configure('php-666', 'git://', 'git://')
    def configure(cartridge_name, template_git_url = nil, manifest = nil)
      output                 = ''
      name, software_version = map_cartridge_name(cartridge_name)
      cartridge              = if manifest
                                 logger.debug("Loading from manifest...")
                                 Runtime::Manifest.new(manifest, software_version)
                               else
                                 CartridgeRepository.instance.select(name, software_version)
                               end

      OpenShift::Utils::Sdk.mark_new_sdk_app(@user.homedir)
      OpenShift::Utils::Cgroups::with_no_cpu_limits(@user.uuid) do
        create_cartridge_directory(cartridge, software_version)
        # Note: the following if statement will check the following criteria long-term:
        # 1. Is the app scalable?
        # 2. Is this the head gear?
        # 3. Is this the first time the platform has generated an ssh key?
        #
        # In the current state of things, the following check is sufficient to test all
        # of these criteria, and we do not have a way to explicitly check the first two
        # criteria.  However, it should be considered a TODO to add more explicit checks.
        if cartridge.web_proxy?
          output << generate_ssh_key(cartridge)
        end

        create_private_endpoints(cartridge)

        Dir.chdir(PathUtils.join(@user.homedir, cartridge.directory)) do
          unlock_gear(cartridge) do |c|
            output << cartridge_action(cartridge, 'setup', software_version, true)
            process_erb_templates(c)
            output << cartridge_action(cartridge, 'install', software_version)
            output << populate_gear_repo(c.directory, template_git_url) if cartridge.deployable?
          end

        end

        connect_frontend(cartridge)
      end

      logger.info "configure output: #{output}"
      return output
    rescue Utils::ShellExecutionException => e
      rc_override = e.rc < 100 ? 157 : e.rc
      raise Utils::Sdk.translate_shell_ex_for_client(e, rc_override)
    rescue => e
      ex =  RuntimeError.new(Utils::Sdk.translate_out_for_client(e.message, :error))
      ex.set_backtrace(e.backtrace)
      raise ex
    end

    def post_install(cartridge, software_version, options = {})
      output = cartridge_action(cartridge, 'post_install', software_version)
      options[:out].puts(output) if options[:out]
      output
    end

    def post_configure(cartridge_name)
      output = ''

      name, software_version = map_cartridge_name(cartridge_name)
      cartridge              = get_cartridge(name)

      OpenShift::Utils::Cgroups::with_no_cpu_limits(@user.uuid) do
        output << start_cartridge('start', cartridge, user_initiated: true)
        output << cartridge_action(cartridge, 'post_install', software_version)
      end

      logger.info("post-configure output: #{output}")
      output
    rescue Utils::ShellExecutionException => e
      raise Utils::Sdk.translate_shell_ex_for_client(e, 157)
    end

    # deconfigure(cartridge_name) -> nil
    #
    # Remove cartridge from gear with the following workflow:
    #
    #   1. Delete private endpoints
    #   2. Stop the cartridge
    #   3. Execute the cartridge `control teardown` action
    #   4. Disconnect the frontend for the cartridge
    #   5. Delete the cartridge directory
    #
    # If the cartridge stop or teardown operations fail, the error output will be
    # captured, but the frontend will still be disconnect and the cartridge directory
    # will be deleted.
    #
    # deconfigure('php-5.3')
    def deconfigure(cartridge_name)
      teardown_output = ''

      cartridge = get_cartridge(cartridge_name)
      delete_private_endpoints(cartridge)
      OpenShift::Utils::Cgroups::with_no_cpu_limits(@user.uuid) do
        begin
          stop_cartridge(cartridge, user_initiated: true)
          unlock_gear(cartridge, false) do |c|
            teardown_output << cartridge_teardown(c.directory)            
          end
        rescue Utils::ShellExecutionException => e
          teardown_output << Utils::Sdk::translate_out_for_client(e.stdout, :error)
          teardown_output << Utils::Sdk::translate_out_for_client(e.stderr, :error)
        ensure
          disconnect_frontend(cartridge)
          delete_cartridge_directory(cartridge)
        end
      end

      teardown_output
    end

    # unlock_gear(cartridge_name) -> nil
    #
    # Prepare the given cartridge for the cartridge author
    #
    #   v2_cart_model.unlock_gear('php-5.3')
    def unlock_gear(cartridge, relock = true)
      begin
        do_unlock(locked_files(cartridge))
        yield cartridge
      ensure
        do_lock(locked_files(cartridge)) if relock
      end
      nil
    end

    # do_unlock_gear(array of file names) -> array
    #
    # Take the given array of file system entries and prepare them for the cartridge author
    #
    #   v2_cart_model.do_unlock_gear(entries)
    def do_unlock(entries)
      mcs_label = Utils::SELinux.get_mcs_label(@user.uid)

      entries.each do |entry|
        if entry.end_with?('/')
          entry.chomp!('/')
          FileUtils.mkpath(entry, mode: 0755) unless File.exist? entry
        else
          # FileUtils.touch not used as it doesn't support mode
          File.new(entry, File::CREAT|File::TRUNC|File::WRONLY, 0644).close() unless File.exist?(entry)
        end
        # It is expensive doing one file at a time but...
        # ...it allows reporting on the failed command at the file level
        # ...we don't have to worry about the length of argv
        begin
          PathUtils.oo_chown(@user.uid, @user.gid, entry)
          Utils::SELinux.set_mcs_label(mcs_label, entry)
        rescue Exception => e
          raise OpenShift::FileUnlockError.new("Failed to unlock file system entry [#{entry}]: #{e}",
                                               entry)
        end
      end

      begin
        PathUtils.oo_chown(@user.uid, @user.gid, @user.homedir)
      rescue Exception => e
        raise OpenShift::FileUnlockError.new(
                  "Failed to unlock gear home [#{@user.homedir}]: #{e}",
                  @user.homedir)
      end
    end

    # do_lock_gear(array of file names) -> array
    #
    # Take the given array of file system entries and prepare them for the application developer
    #    v2_cart_model.do_lock_gear(entries)
    def do_lock(entries)
      mcs_label = Utils::SELinux.get_mcs_label(@user.uid)

      # It is expensive doing one file at a time but...
      # ...it allows reporting on the failed command at the file level
      # ...we don't have to worry about the length of argv
      entries.each do |entry|
        begin
          PathUtils.oo_chown(0, @user.gid, entry)
          Utils::SELinux.set_mcs_label(mcs_label, entry)
        rescue Exception => e
          raise OpenShift::FileLockError.new("Failed to lock file system entry [#{entry}]: #{e}",
                                             entry)
        end
      end

      begin
        PathUtils.oo_chown(0, @user.gid, @user.homedir)
      rescue Exception => e
        raise OpenShift::FileLockError.new("Failed to lock gear home [#{@user.homedir}]: #{e}",
                                           @user.homedir)
      end
    end

    # create_cartridge_directory(cartridge name) -> nil
    #
    # Create the cartridges home directory
    #
    #   v2_cart_model.create_cartridge_directory('php-5.3')
    def create_cartridge_directory(cartridge, software_version)
      logger.info("Creating cartridge directory #{@user.uuid}/#{cartridge.directory}")

      target = File.join(@user.homedir, cartridge.directory)
      CartridgeRepository.instantiate_cartridge(cartridge, target)

      ident = Runtime::Manifest.build_ident(cartridge.cartridge_vendor,
                                            cartridge.name,
                                            software_version,
                                            cartridge.cartridge_version)

      envs                                  = {}
      envs["#{cartridge.short_name}_DIR"]   = target + File::SEPARATOR
      envs["#{cartridge.short_name}_IDENT"] = ident

      write_environment_variables(File.join(target, 'env'), envs)

      envs.clear
      envs['namespace'] = @user.namespace if @user.namespace

      # If there's not already a primary cartridge on the gear, assume
      # the new cartridge is the primary.
      current_gear_env = Utils::Environ.for_gear(@user.homedir)
      unless current_gear_env['OPENSHIFT_PRIMARY_CARTRIDGE_DIR']
        envs['primary_cartridge_dir'] = target + File::SEPARATOR
        logger.info("Cartridge #{cartridge.name} recorded as primary within gear #{@user.uuid}")
      end

      unless envs.empty?
        write_environment_variables(File.join(@user.homedir, '.env'), envs)
      end

      # Gear level actions: Placed here to be off the V1 code path...
      old_path = File.join(@user.homedir, '.env', 'PATH')
      File.delete(old_path) if File.file? old_path

      secure_cartridge(cartridge.short_name, @user.uid, @user.gid, target)

      logger.info("Created cartridge directory #{@user.uuid}/#{cartridge.directory}")
      nil
    end

    def secure_cartridge(short_name, uid, gid=uid, cartridge_home)
      Dir.chdir(cartridge_home) do
        make_user_owned(cartridge_home)

        files = ManagedFiles::IMMUTABLE_FILES.collect do |file|
          file.gsub!('*', short_name)
          file if File.exist?(file)
        end || []
        files.compact!

        unless files.empty?
          PathUtils.oo_chown(0, gid, files)
          FileUtils.chmod(0644, files)
        end
      end
    end

    ##
    # Write out environment variables.
    def write_environment_variables(path, hash, prefix = true)
      FileUtils.mkpath(path) unless File.exist? path

      hash.each_pair do |k, v|
        name = k.to_s.upcase

        if prefix
          name = "OPENSHIFT_#{name}"
        end

        File.open(PathUtils.join(path, name), 'w', 0666) do |f|
          f.write(v)
        end
      end
    end

    def delete_cartridge_directory(cartridge)
      logger.info("Deleting cartridge directory for #{@user.uuid}/#{cartridge.directory}")
      # TODO: rm_rf correct?
      FileUtils.rm_rf(File.join(@user.homedir, cartridge.directory))
      logger.info("Deleted cartridge directory for #{@user.uuid}/#{cartridge.directory}")
    end

    # :call-seq:
    #   model.populate_gear_repo(cartridge name) => nil
    #   model.populate_gear_repo(cartridge name, application git template url) -> nil
    #
    # Populate the gear git repository with a sample application
    #
    #   model.populate_gear_repo('ruby-1.9')
    #   model.populate_gear_repo('ruby-1.9', 'http://rails-example.example.com')
    def populate_gear_repo(cartridge_name, template_url = nil)
      logger.info "Creating gear repo for #{@user.uuid}/#{cartridge_name} from `#{template_url}`"

      repo = ApplicationRepository.new(@user)
      if template_url.nil?
        repo.populate_from_cartridge(cartridge_name)
      else
        repo.populate_from_url(cartridge_name, template_url)
      end

      if repo.exist?
        repo.archive
        "CLIENT_DEBUG: The cartridge #{cartridge_name} deployed a template application"
      else
        "CLIENT_MESSAGE: The cartridge #{cartridge_name} did not provide template application"
      end
    end

    # process_erb_templates(cartridge_name) -> nil
    #
    # Search cartridge for any remaining <code>erb</code> files render them
    def process_erb_templates(cartridge)
      directory = PathUtils.join(@user.homedir, cartridge.name)
      logger.info "Processing ERB templates for #{cartridge.name}"

      env  = Utils::Environ.for_gear(@user.homedir, directory)
      erbs = processed_templates(cartridge).map { |x| PathUtils.join(@user.homedir, x) }
      render_erbs(env, erbs)
    end

    #  cartridge_action(cartridge, action, software_version, render_erbs) -> buffer
    #
    #  Returns the results from calling a cartridge's action script.
    #  Includes <code>--version</code> if provided.
    #  Raises exception if script fails
    #
    #   stdout = cartridge_action(cartridge_obj)
    def cartridge_action(cartridge, action, software_version, render_erbs=false)
      logger.info "Running #{action} for #{@user.uuid}/#{cartridge.directory}"

      cartridge_home = File.join(@user.homedir, cartridge.directory)
      action         = File.join(cartridge_home, 'bin', action)
      return "" unless File.exists? action

      gear_env           = Utils::Environ.for_gear(@user.homedir)
      cartridge_env_home = File.join(cartridge_home, 'env')

      cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))
      if render_erbs
        erbs = Dir.glob(cartridge_env_home + '/*.erb', File::FNM_DOTMATCH).select { |f| File.file?(f) }
        render_erbs(cartridge_env, erbs)
        cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))
      end

      action << " --version #{software_version}"
      out, _, _ = Utils.oo_spawn(action,
                                 env:                 cartridge_env,
                                 unsetenv_others:     true,
                                 chdir:               cartridge_home,
                                 uid:                 @user.uid,
                                 timeout:             @hourglass.remaining,
                                 expected_exitstatus: 0)
      logger.info("Ran #{action} for #{@user.uuid}/#{cartridge.directory}\n#{out}")
      out
    end

    # render_erbs(program environment as a hash, erbs) -> nil
    #
    # Run <code>erb</code> against each template file submitted
    #
    #   v2_cart_model.render_erbs({HOMEDIR => '/home/no_place_like'}, ['/var/lib/openshift/user/cart/foo.erb', ...])
    def render_erbs(env, erbs)
      erbs.each do |file|
        begin
          Utils.oo_spawn(%Q{/usr/bin/oo-erb -S 2 -- #{file} > #{file.chomp('.erb')}},
                         env:                 env,
                         unsetenv_others:     true,
                         chdir:               @user.homedir,
                         uid:                 @user.uid,
                         timeout:             @hourglass.remaining,
                         expected_exitstatus: 0)
        rescue Utils::ShellExecutionException => e
          logger.info("Failed to render ERB #{file}: #{e.stderr}")
        else
          File.delete(file)
        end
      end
      nil
    end

    # cartridge_teardown(cartridge_name, remove_cartridge_dir) -> buffer
    #
    # Returns the output from calling the cartridge's teardown script.
    #  Raises exception if script fails
    #
    # stdout = cartridge_teardown('php-5.3')
    def cartridge_teardown(cartridge_name, remove_cartridge_dir=true)
      cartridge_home = File.join(@user.homedir, cartridge_name)
      env            = Utils::Environ.for_gear(@user.homedir, cartridge_home)
      teardown       = File.join(cartridge_home, 'bin', 'teardown')

      return "" unless File.exists? teardown
      return "#{teardown}: is not executable\n" unless File.executable? teardown

      # FIXME: Will anyone retry if this reports error, or should we remove from disk no matter what?
      buffer, err, _ = Utils.oo_spawn(teardown,
                                      env:                 env,
                                      unsetenv_others:     true,
                                      chdir:               cartridge_home,
                                      uid:                 @user.uid,
                                      timeout:             @hourglass.remaining,
                                      expected_exitstatus: 0)

      buffer << err

      FileUtils.rm_r(cartridge_home) if remove_cartridge_dir
      logger.info("Ran teardown for #{@user.uuid}/#{cartridge_name}")
      buffer
    end

    # Expose an endpoint for a cartridge through the port proxy.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors
    # here are considered fatal.
    def create_public_endpoint(cartridge, endpoint, private_ip)
      proxy = OpenShift::FrontendProxyServer.new

      # Add the public-to-private endpoint-mapping to the port proxy
      public_port = proxy.add(@user.uid, private_ip, endpoint.private_port)

      @user.add_env_var(endpoint.public_port_name, public_port)

      logger.info("Created public endpoint for cart #{cartridge.name} in gear #{@uuid}: "\
        "[#{endpoint.public_port_name}=#{public_port}]")
    end

    # Allocates and assigns private IP/port entries for a cartridge
    # based on endpoint metadata for the cartridge.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors
    # here are considered fatal.
    def create_private_endpoints(cartridge)
      raise "Cartridge is required" unless cartridge
      return unless cartridge.endpoints && cartridge.endpoints.length > 0

      logger.info "Creating #{cartridge.endpoints.length} private endpoints for #{@user.uuid}/#{cartridge.directory}"

      allocated_ips = {}

      cartridge.endpoints.each do |endpoint|
        # Reuse previously allocated IPs of the same name. When recycling
        # an IP, double-check that it's not bound to the target port, and
        # bail if it's unexpectedly bound.
        unless allocated_ips.has_key?(endpoint.private_ip_name)
          # Allocate a new IP for the endpoint
          private_ip = find_open_ip(endpoint.private_port)

          if private_ip.nil?
            raise "No IP was available to create endpoint for cart #{cartridge.name} in gear #{@user.uuid}: "\
              "#{endpoint.private_ip_name}(#{endpoint.private_port})"
          end

          @user.add_env_var(endpoint.private_ip_name, private_ip)

          allocated_ips[endpoint.private_ip_name] = private_ip
        end

        private_ip = allocated_ips[endpoint.private_ip_name]

        @user.add_env_var(endpoint.private_port_name, endpoint.private_port)

        # Create the environment variable for WebSocket Port if it is specified
        # in the manifest.
        if endpoint.websocket_port_name && endpoint.websocket_port
          @user.add_env_var(endpoint.websocket_port_name, endpoint.websocket_port)
        end


        logger.info("Created private endpoint for cart #{cartridge.name} in gear #{@user.uuid}: "\
          "[#{endpoint.private_ip_name}=#{private_ip}, #{endpoint.private_port_name}=#{endpoint.private_port}]")

        # Expose the public endpoint if ssl_to_gear option is set
        if endpoint.options and endpoint.options["ssl_to_gear"]
          logger.info("ssl_to_gear option set for the endpoint")
          create_public_endpoint(cartridge, endpoint, private_ip)
        end
      end

      # Validate all the allocations to ensure they aren't already bound. Batch up the initial check
      # for efficiency, then do individual checks to provide better reporting before we fail.
      address_list = cartridge.endpoints.map { |e| {ip: allocated_ips[e.private_ip_name], port: e.private_port} }
      if !address_list.empty? && addresses_bound?(address_list)
        failures = ''
        cartridge.endpoints.each do |endpoint|
          if address_bound?(allocated_ips[endpoint.private_ip_name], endpoint.private_port)
            failures << "#{endpoint.private_ip_name}(#{endpoint.private_port})=#{allocated_ips[endpoint.private_ip_name]};"
          end
        end
        raise "Failed to create the following private endpoints due to existing process bindings: #{failures}" unless failures.empty?
      end
    end

    def delete_private_endpoints(cartridge)
      logger.info "Deleting private endpoints for #{@user.uuid}/#{cartridge.directory}"

      cartridge.endpoints.each do |endpoint|
        @user.remove_env_var(endpoint.private_ip_name)
        @user.remove_env_var(endpoint.private_port_name)
      end

      logger.info "Deleted private endpoints for #{@user.uuid}/#{cartridge.directory}"
    end

    # Finds the next IP address available for binding of the given port for
    # the current gear user. The IP is assumed to be available only if the IP is 
    # not already associated with an existing endpoint defined by any cartridge within the gear.
    #
    # Returns a string IP address in dotted-quad notation if one is available
    # for the given port, or returns nil if IP is available.
    def find_open_ip(port)
      allocated_ips = get_allocated_private_ips
      logger.debug("IPs already allocated for #{port} in gear #{@user.uuid}: #{allocated_ips}")

      open_ip = nil

      for host_ip in 1..127
        candidate_ip = UnixUser.get_ip_addr(@user.uid.to_i, host_ip)

        # Skip the IP if it's already assigned to an endpoint
        next if allocated_ips.include?(candidate_ip)

        open_ip = candidate_ip
        break
      end

      open_ip
    end

    # Returns true if the given IP and port are currently bound
    # according to lsof, otherwise false.
    def address_bound?(ip, port)
      _, _, rc = Utils.oo_spawn("/usr/sbin/lsof -i @#{ip}:#{port}", timeout: @hourglass.remaining)
      rc == 0
    end

    def addresses_bound?(addresses)
      command = "/usr/sbin/lsof"
      addresses.each do |addr|
        command << " -i @#{addr[:ip]}:#{addr[:port]}"
      end

      _, _, rc = Utils.oo_spawn(command, timeout: @hourglass.remaining)
      rc == 0
    end

    # Returns an array containing all currently allocated endpoint private
    # IP addresses assigned to carts within the current gear, or an empty
    # array if none are currently defined.
    def get_allocated_private_ips
      env = Utils::Environ::for_gear(@user.homedir)

      allocated_ips = []

      # Collect all existing endpoint IP allocations
      process_cartridges do |cart_path|
        cart_dir = File.basename(cart_path)
        cart     = get_cartridge_from_directory(cart_dir)

        cart.endpoints.each do |endpoint|
          # TODO: If the private IP variable exists but the value isn't in
          # the environment, what should happen?
          ip = env[endpoint.private_ip_name]
          allocated_ips << ip unless ip == nil
        end
      end

      allocated_ips
    end

    # disconnect cartridge from frontend proxy
    #
    # This is only called when a cartridge is removed from a cartridge not a gear delete
    def disconnect_frontend(cartridge)
      mappings = []
      cartridge.endpoints.each do |endpoint|
        endpoint.mappings.each do |mapping|
          mappings << mapping.frontend
        end
      end

      logger.info("Disconnecting frontend mapping for #{@user.uuid}/#{cartridge.name}: #{mappings.inspect}")
      unless mappings.empty?
        OpenShift::FrontendHttpServer.new(@user.uuid, @user.container_name, @user.namespace).disconnect(*mappings)
      end
    end

    def connect_frontend(cartridge)
      frontend       = OpenShift::FrontendHttpServer.new(@user.uuid, @user.container_name, @user.namespace)
      gear_env       = Utils::Environ.for_gear(@user.homedir)
      web_proxy_cart = web_proxy

      begin
        # TODO: exception handling
        cartridge.endpoints.each do |endpoint|
          endpoint.mappings.each do |mapping|
            private_ip  = gear_env[endpoint.private_ip_name]
            backend_uri = "#{private_ip}:#{endpoint.private_port}#{mapping.backend}"
            options     = mapping.options ||= {}

            if endpoint.websocket_port
              options["websocket_port"] = endpoint.websocket_port
            end

            # Make sure that the mapping does not collide with the default web_proxy mapping
            if mapping.frontend == "" and not cartridge.web_proxy? and web_proxy_cart
              logger.info("Skipping default mapping as web proxy owns it for the application")
              next
            end

            # Only web proxy cartridges can override the default mapping
            if mapping.frontend == "" && (!cartridge.web_proxy?) && (cartridge.name != primary_cartridge.name)
              logger.info("Skipping default mapping as primary cartridge owns it for the application")
              next
            end

            logger.info("Connecting frontend mapping for #{@user.uuid}/#{cartridge.name}: "\
                      "[#{mapping.frontend}] => [#{backend_uri}] with options: #{mapping.options}")
            frontend.connect(mapping.frontend, backend_uri, options)
          end
        end
      rescue Exception => e
        logger.warn("V2CartModel#connect_frontend: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      end
    end

    # Run code block against each cartridge in gear
    #
    # @param  [block]  Code block to process cartridge
    # @yields [String] cartridge directory for each cartridge in gear
    def process_cartridges(cartridge_dir = nil) # : yields cartridge_path
      if cartridge_dir
        cart_dir = File.join(@user.homedir, cartridge_dir)
        yield cart_dir if File.exist?(cart_dir)
        return
      end

      Dir[PathUtils.join(@user.homedir, "*")].each do |cart_dir|
        next if File.symlink?(cart_dir) || !File.exist?(PathUtils.join(cart_dir, "metadata", "manifest.yml"))
        yield cart_dir
      end if @user.homedir and File.exist?(@user.homedir)
    end

    def do_control(action, cartridge, options={})
      case cartridge
        when String
          cartridge_dir = cartridge_directory(cartridge)
        when OpenShift::Runtime::Manifest
          cartridge_dir = cartridge.directory
        else
          raise "Unsupported cartridge argument type: #{cartridge.class}"
      end

      options[:cartridge_dir] = cartridge_dir

      do_control_with_directory(action, options)
    end

    def short_name_from_full_cart_name(pub_cart_name)
      raise ArgumentError.new('pub_cart_name cannot be nil') unless pub_cart_name

      return pub_cart_name if pub_cart_name.index('-').nil?

      tokens = pub_cart_name.split('-')
      tokens.pop
      tokens.join('-')
    end

    # Let a cart perform some action when another cart is being removed
    # Today, it is used to cleanup environment variables
    def unsubscribe(cart_name, pub_cart_name)
      env_dir_path = File.join(@user.homedir, '.env', short_name_from_full_cart_name(pub_cart_name))
      FileUtils.rm_rf(env_dir_path)
    end

    def set_connection_hook_env_vars(cart_name, pub_cart_name, args)
      logger.info("Setting env vars for #{cart_name} from #{pub_cart_name}")
      logger.info("ARGS: #{args.inspect}")

      env_dir_path = File.join(@user.homedir, '.env', short_name_from_full_cart_name(pub_cart_name))
      FileUtils.mkpath(env_dir_path)

      envs = {}

      # Skip the first three arguments and jump to gear => "k1=v1\nk2=v2\n" hash map
      pairs = args[3].values[0].split("\n")

      pairs.each do |pair|
        k, v    = pair.strip.split("=")
        envs[k] = v
      end

      write_environment_variables(env_dir_path, envs, false)
    end

    # Convert env var hook arguments to shell arguments
    # TODO: document expected form of args
    def convert_to_shell_arguments(args)
      new_args = []
      args[3].each do |k, v|
        vstr = v.split("\n").map { |p| p + ";" }.join(' ')
        new_args.push "'#{k}'='#{vstr}'"
      end
      (args[0, 2] << Shellwords::shellescape(new_args.join(' '))).join(' ')
    end

    # :call-seq:
    #    V2CartridgeModel.new(...).connector_execute(cartridge_name, connection_type, connector, args) => String
    #
    def connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      raise ArgumentError.new('cart_name cannot be nil') unless cart_name

      cartridge    = get_cartridge(cart_name)
      env          = Utils::Environ.for_gear(@user.homedir, File.join(@user.homedir, cartridge.directory))
      env_var_hook = connection_type.start_with?("ENV:") && pub_cart_name

      # Special treatment for env var connection hooks
      if env_var_hook
        set_connection_hook_env_vars(cart_name, pub_cart_name, args)
        args = convert_to_shell_arguments(args)
      end

      conn = Runtime::PubSubConnector.new connection_type, connector

      if conn.reserved?
        begin
          return send(conn.action_name)
        rescue NoMethodError => e
          logger.debug "#{e.message}; falling back to script"
        end
      end

      cartridge_home = PathUtils.join(@user.homedir, cartridge.directory)
      script = PathUtils.join(cartridge_home, 'hooks', conn.name)

      unless File.executable?(script)
        if env_var_hook
          return "Set environment variables successfully"
        else
          msg = "ERROR: action '#{connector}' not found."
          raise Utils::ShellExecutionException.new(msg, 127, msg)
        end
      end

      command      = script << " " << args
      out, err, rc = Utils.oo_spawn(command,
                                    env:             env,
                                    unsetenv_others: true,
                                    chdir:           cartridge_home,
                                    timeout:         @hourglass.remaining,
                                    uid:             @user.uid)
      if 0 == rc
        logger.info("(#{rc})\n------\n#{Runtime::Utils.sanitize_credentials(out)}\n------)")
        return out
      end

      logger.info("ERROR: (#{rc})\n------\n#{Runtime::Utils.sanitize_credentials(out)}\n------)")
      raise OpenShift::Utils::ShellExecutionException.new(
                "Control action '#{connector}' returned an error. rc=#{rc}\n#{out}", rc, out, err)
    end

    # :call-seq:
    #   V2CartridgeModel.new(...).do_control_with_directory(action, options)  -> output
    #   V2CartridgeModel.new(...).do_control_with_directory(action)           -> output
    #
    # Call action on cartridge +control+ script. Run all pre/post hooks if found.
    #
    # +options+: hash
    #   :cartridge_dir => path             : Process all cartridges (if +nil+) or the provided cartridge
    #   :pre_action_hooks_enabled => true  : Whether to process repo action hooks before +action+
    #   :post_action_hooks_enabled => true : Whether to process repo action hooks after +action+
    #   :prefix_action_hooks => true       : If +true+, action hook names are automatically prefixed with
    #                                        'pre' and 'post' depending on their execution order.
    #   :out                               : An +IO+ object to which control script STDOUT should be directed. If
    #                                        +nil+ (the default), output is logged.
    #   :err                               : An +IO+ object to which control script STDERR should be directed. If
    #                                        +nil+ (the default), output is logged.
    def do_control_with_directory(action, options={})
      cartridge_dir             = options[:cartridge_dir]
      pre_action_hooks_enabled  = options.has_key?(:pre_action_hooks_enabled) ? options[:pre_action_hooks_enabled] : true
      post_action_hooks_enabled = options.has_key?(:post_action_hooks_enabled) ? options[:post_action_hooks_enabled] : true
      prefix_action_hooks       = options.has_key?(:prefix_action_hooks) ? options[:prefix_action_hooks] : true

      logger.debug { "#{@user.uuid} #{action} against '#{cartridge_dir}'" }
      buffer       = ''
      gear_env     = Utils::Environ.for_gear(@user.homedir)
      action_hooks = File.join(@user.homedir, %w{app-root runtime repo .openshift action_hooks})

      if pre_action_hooks_enabled
        pre_action_hook = prefix_action_hooks ? "pre_#{action}" : action
        hook_buffer     = do_action_hook(pre_action_hook, gear_env, options)
        buffer << hook_buffer if hook_buffer.is_a?(String)
      end

      process_cartridges(cartridge_dir) { |path|
        # Make sure this cartridge's env directory overrides that of other cartridge envs
        cartridge_env = gear_env.merge(Utils::Environ.load(File.join(path, 'env')))

        ident                            = cartridge_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
        _, software, software_version, _ = Runtime::Manifest.parse_ident(cartridge_env[ident.first])
        hooks                            = cartridge_hooks(action_hooks, action, software, software_version)

        control = File.join(path, 'bin', 'control')

        command = []
        command << hooks[:pre] unless hooks[:pre].empty?
        command << "#{control} #{action}" if File.executable? control
        command << hooks[:post] unless hooks[:post].empty?

        unless command.empty?
          command = ['set -e'] | command 

          out, err, rc = Utils.oo_spawn(command.join('; '),
                                      env:             cartridge_env,
                                      unsetenv_others: true,
                                      chdir:           path,
                                      uid:             @user.uid,
                                      timeout:         @hourglass.remaining,
                                      out:             options[:out],
                                      err:             options[:err])

          buffer << out if out.is_a?(String)
          buffer << err if err.is_a?(String)

          raise Utils::ShellExecutionException.new(
                  "Failed to execute: 'control #{action}' for #{path}", rc, out, err
                ) if rc != 0
        end
      }

      if post_action_hooks_enabled
        post_action_hook = prefix_action_hooks ? "post_#{action}" : action
        hook_buffer      = do_action_hook(post_action_hook, gear_env, options)
        buffer << hook_buffer if hook_buffer.is_a?(String)
      end

      buffer
    end

    ##
    # Executes the named +action+ from the user repo +action_hooks+ directory and returns the
    # stdout of the execution, or raises a +ShellExecutionException+ if the action returns a
    # non-zero return code.
    #
    # All hyphens in the +action+ will be replaced with underscores.
    def do_action_hook(action, env, options)
      action = action.gsub(/-/, '_')

      action_hooks_dir = File.join(@user.homedir, %w{app-root runtime repo .openshift action_hooks})
      action_hook      = File.join(action_hooks_dir, action)
      buffer           = ''

      if File.executable?(action_hook)
        out, err, rc = Utils.oo_spawn(action_hook,
                                      env:             env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid,
                                      timeout:         @hourglass.remaining,
                                      out:             options[:out],
                                      err:             options[:err])
        raise Utils::ShellExecutionException.new(
                  "Failed to execute action hook '#{action}' for #{@user.uuid} application #{@user.app_name}",
                  rc, out, err
              ) if rc != 0
      end

      buffer << out if out.is_a?(String)
      buffer << err if err.is_a?(String)

      buffer
    end

    def cartridge_hooks(action_hooks, action, name, version)
      hooks = {pre: [], post: []}

      hooks.each_key do |key|
        new_hook = PathUtils.join(action_hooks, "#{key}_#{action}_#{name}")
        old_hook = PathUtils.join(action_hooks, "#{key}_#{action}_#{name}-#{version}")

        hooks[key] << "source #{new_hook}" if File.exist? new_hook
        hooks[key] << "source #{old_hook}" if File.exist? old_hook
      end
      hooks
    end

    ##
    # Shuts down the gear by running the cartridge +stop+ control action for each cartridge 
    # in the gear.
    #
    # +options+: hash
    #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
    #                                   Default is +true+.
    #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
    #                                   +nil+ (the default), output is logged.
    #   :err                          : An +IO+ object to which control script STDERR should be directed. If
    #                                   +nil+ (the default), output is logged.
    #
    # Returns the combined output of all +stop+ action executions as a +String+.
    def stop_gear(options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      buffer = ''

      each_cartridge do |cartridge|
        buffer << stop_cartridge(cartridge, options)
      end

      buffer
    end

    ##
    # Starts up the gear by running the cartridge +start+ control action for each 
    # cartridge in the gear.
    #
    # By default, all cartridges in the gear are started. The selection of cartridges
    # to be started is configurable via +options+.
    #
    # +options+: hash
    #   :primary_only   => [boolean]  : If +true+, only the primary cartridge will be started.
    #                                   Mutually exclusive with +secondary_only+.
    #   :secondary_only => [boolean]  : If +true+, all cartridges except the primary cartridge
    #                                   will be started. Mutually exclusive with +primary_only+.
    #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
    #                                   Default is +true+.
    #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
    #                                   +nil+ (the default), output is logged.
    #   :err                          : An +IO+ object to which control script STDERR should be directed. If
    #                                   +nil+ (the default), output is logged.
    #
    # Returns the combined output of all +start+ action executions as a +String+.
    def start_gear(options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      if options[:primary_only] && options[:secondary_only]
        raise ArgumentError.new('The primary_only and secondary_only options are mutually exclusive options')
      end

      buffer = ''
      each_cartridge do |cartridge|
        next if options[:primary_only] and cartridge.name != primary_cartridge.name
        next if options[:secondary_only] and cartridge.name == primary_cartridge.name

        buffer << start_cartridge('start', cartridge, options)
      end

      buffer
    end

    ##
    # Starts a cartridge.
    #
    # Both application state and the stop lock are managed during the operation. If start
    # of the primary cartridge is invoked and +user_initiated+ is true, the stop lock is
    # created.
    #
    # +type+      : Type of start [start, restart, reload]
    # +cartridge+ : A +Cartridge+ instance or +String+ name of a cartridge.
    # +options+   : hash
    #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
    #                                   Default is +true+.
    #   :hot_deploy => [boolean]      : If +true+ and if +cartridge+ is the primary cartridge in the gear, the
    #                                   gear state will be set to +STARTED+ but the actual cartridge start operation
    #                                   will be skipped. Non-primary cartridges will be skipped with no state change.
    #                                   Default is +false+.
    #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
    #                                   +nil+ (the default), output is logged.
    #   :err                          : An +IO+ object to which control script STDERR should be directed. If
    #                                   +nil+ (the default), output is logged.
    #
    # Returns the output of the operation as a +String+ or raises a +ShellExecutionException+
    # if the cartridge script fails.
    def start_cartridge(type, cartridge, options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)
      options[:hot_deploy] = false if not options.has_key?(:hot_deploy)

      cartridge = get_cartridge(cartridge) if cartridge.is_a?(String)

      if not options[:user_initiated] and stop_lock?
        return "Not starting cartridge #{cartridge.name} because the application was explicitly stopped by the user"
      end

      if cartridge.name == primary_cartridge.name
        FileUtils.rm_f(stop_lock) if options[:user_initiated]
        @state.value = OpenShift::State::STARTED

        # Unidle the application, preferring to use the privileged operation if possible
        frontend = FrontendHttpServer.new(@user.uuid)
        if Process.uid == @user.uid
          frontend.unprivileged_unidle
        else
          frontend.unidle
        end
      end

      if options[:hot_deploy]
        output = "Not starting cartridge #{cartridge.name} because hot deploy is enabled"
        options[:out].puts(output) if options[:out]
        return output
      end

      do_control(type, cartridge, options)
    end

    ##
    # Stops a cartridge.
    #
    # Both application state and the stop lock are managed during the operation. If stop
    # of the primary cartridge is invoked and +user_initiated+ is true, the stop lock
    # is removed.
    #
    # +cartridge+ : A +Cartridge+ instance or +String+ name of a cartridge.
    # +options+   : hash
    #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
    #                                   Default is +true+.
    #   :hot_deploy => [boolean]      : If +true+, the stop operation is skipped for all cartridge types,
    #                                   the gear state is not modified, and the stop lock is never created.
    #                                   Default is +false+. 
    #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
    #                                   +nil+ (the default), output is logged.
    #   :err                          : An +IO+ object to which control script STDERR should be directed. If
    #                                   +nil+ (the default), output is logged.
    #
    # Returns the output of the operation as a +String+ or raises a +ShellExecutionException+
    # if the cartridge script fails.
    def stop_cartridge(cartridge, options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)
      options[:hot_deploy] = false if not options.has_key?(:hot_deploy)

      cartridge = get_cartridge(cartridge) if cartridge.is_a?(String)

      if options[:hot_deploy]
        output = "Not stopping cartridge #{cartridge.name} because hot deploy is enabled"
        options[:out].puts(output) if options[:out]
        return output
      end

      if not options[:user_initiated] and stop_lock?
        return "Not stopping cartridge #{cartridge.name} because the application was explicitly stopped by the user\n"
      end

      if cartridge.name == primary_cartridge.name
        create_stop_lock if options[:user_initiated]
        @state.value = OpenShift::State::STOPPED
      end

      do_control('stop', cartridge, options)
    end

    ##
    # Writes the +stop_lock+ file and changes its ownership to the gear user.
    def create_stop_lock
      unless stop_lock?
        mcs_label = Utils::SELinux.get_mcs_label(@user.uid)
        File.new(stop_lock, File::CREAT|File::TRUNC|File::WRONLY, 0644).close()
        PathUtils.oo_chown(@user.uid, @user.gid, stop_lock)
        Utils::SELinux.set_mcs_label(mcs_label, stop_lock)
      end
    end

    ##
    # Generate an RSA ssh key
    def generate_ssh_key(cartridge)
      ssh_dir        = File.join(@user.homedir, '.openshift_ssh')
      known_hosts    = File.join(ssh_dir, 'known_hosts')
      ssh_config     = File.join(ssh_dir, 'config')
      ssh_key        = File.join(ssh_dir, 'id_rsa')
      ssh_public_key = ssh_key + '.pub'

      FileUtils.mkdir_p(ssh_dir)
      make_user_owned(ssh_dir)

      Utils::oo_spawn("/usr/bin/ssh-keygen -N '' -f #{ssh_key}",
                      chdir:               @user.homedir,
                      uid:                 @user.uid,
                      gid:                 @user.gid,
                      timeout:             @hourglass.remaining,
                      expected_exitstatus: 0)

      FileUtils.touch(known_hosts)
      FileUtils.touch(ssh_config)

      make_user_owned(ssh_dir)

      FileUtils.chmod(0750, ssh_dir)
      FileUtils.chmod(0600, [ssh_key, ssh_public_key])
      FileUtils.chmod(0660, [known_hosts, ssh_config])

      @user.add_env_var('APP_SSH_KEY', ssh_key, true)
      @user.add_env_var('APP_SSH_PUBLIC_KEY', ssh_public_key, true)

      public_key_bytes = IO.read(ssh_public_key)
      public_key_bytes.sub!(/^ssh-rsa /, '')

      output = "APP_SSH_KEY_ADD: #{cartridge.directory} #{public_key_bytes}\n"
      # The BROKER_AUTH_KEY_ADD token does not use any arguments.  It tells the broker
      # to enable this gear to make REST API calls on behalf of the user who owns this gear.
      output << "BROKER_AUTH_KEY_ADD: \n"
      output
    end

    ##
    # Change the ownership and SELinux context of the target
    # to be owned as the user using the user's MCS labels
    def make_user_owned(target)
      mcs_label = Utils::SELinux.get_mcs_label(@user.uid)

      PathUtils.oo_chown_R(@user.uid, @user.gid, target)
      Utils::SELinux.set_mcs_label_R(mcs_label, target)
    end

    private
    ## special methods that are handled especially by the platform
    def publish_gear_endpoint
      begin
        # TODO:
        # There is some concern about how well-behaved Facter is
        # when it is require'd.
        # Instead, we use oo_spawn here to avoid it altogether.
        # For the long-term, then, figure out a way to reliably
        # determine the IP address from Ruby.
        out, err, status = Utils.oo_spawn('facter ipaddress',
                                          env:                 cartridge_env,
                                          unsetenv_others:     true,
                                          chdir:               @user.homedir,
                                          uid:                 @user.uid,
                                          timeout:             @hourglass.remaining,
                                          expected_exitstatus: 0)
        private_ip       = out.chomp
      rescue
        require 'socket'
        addrinfo     = Socket.getaddrinfo(Socket.gethostname, 80) # 80 is arbitrary
        private_addr = addrinfo.select { |info|
          info[3] !~ /^127/
        }.first
        private_ip   = private_addr[3]
      end

      env = Utils::Environ::for_gear(@user.homedir)

      output = "#{env['OPENSHIFT_GEAR_UUID']}@#{private_ip}:#{primary_cartridge.name};#{env['OPENSHIFT_GEAR_DNS']}"
      logger.debug output
      output
    end
  end
end
