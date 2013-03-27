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
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/path_utils'

module OpenShift
  # TODO use this exception when oo_spawn fails...
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

    FILENAME_BLACKLIST = %W{.ssh .sandbox .tmp .env}

    # FIXME: need to determine path to correct erb. oo-ruby?
    ERB_BINARY         = '/usr/bin/oo-ruby /opt/rh/ruby193/root/usr/bin/erb'


    def initialize(config, user)
      @config     = config
      @user       = user
      @timeout    = 30
      @cartridges = {}
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
    # Returns the +Cartridge+ in the gear whose +primary+ flag is set to true,
    #
    # Raises an exception if no such cartridge is present.
    def primary_cartridge
      each_cartridge do |cartridge|
        return cartridge if cartridge.primary?
      end

      raise "No primary cartridge found on gear #{@user.uuid}"
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
      cart_dir = Dir.glob(PathUtils.join(@user.homedir, "*-#{name}"))
      raise "Ambiguous cartridge name #{cart_name}: found #{cart_dir}:#{cart_dir.size}" if 1 < cart_dir.size

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
          raise "Failed to load cart manifest from #{cart_dir} for cart #{cart_name} in gear #{@user.uuid}: #{e.message}"
        end
      end

      @cartridges[cart_name]
    end

    

    # Load cartridge's local manifest from cartridge directory name
    def get_cartridge_from_directory(directory)
      unless @cartridges.has_key? directory
        cartridge_path = PathUtils.join(@user.homedir, directory)
        manifest_path  = PathUtils.join(cartridge_path, 'metadata', 'manifest.yml')
        raise "Cartridge manifest not found: #{manifest_path}" unless File.exist?(manifest_path)

        @cartridges[directory] = OpenShift::Runtime::Cartridge.new(manifest_path, @user.homedir)
      end
      @cartridges[directory]
    end

    # destroy() -> nil
    #
    # Remove all cartridges from a gear and delete the gear.  Accepts
    # and discards any parameters to comply with the signature of V1
    # require, which accepted a single argument.
    #
    # destroy()
    def destroy(*)
      logger.info('V2 destroy')

      buffer        = ''
      cartridge_dir = 'N/A'
      process_cartridges do |path|
        begin
          cartridge_dir = File.basename(path)
          buffer << cartridge_teardown(cartridge_dir)
        rescue Utils::ShellExecutionException => e
          logger.warn("Cartridge teardown operation failed on gear #{@user.uuid} for cartridge #{cartridge_dir}: #{e.message} (rc=#{e.rc})")

        end
      end

      # Ensure we're not in the gear's directory
      Dir.chdir(@config.get("GEAR_BASE_DIR")) {
        @user.destroy
      }

      # FIXME: V1 contract is there a better way?
      [buffer, '', 0]
    end

    # tidy() -> nil
    #
    # Run tidy operation on each cartridge on a gear
    #
    # tidy()
    def tidy
      begin
        do_control_with_directory('tidy')
      rescue Utils::ShellExecutionException => e
        logger.warn("Cartridge tidy operation failed on gear #{@user.uuid} for cart #{cartridge_name}: #{e.message} (rc=#{e.rc})")
      end
    end

    # configure(cartridge_name, template_git_url) -> stdout
    #
    # Add a cartridge to a gear
    #
    # configure('php-5.3')
    # configure('php-5.3', 'git://...')
    def configure(cartridge_name, template_git_url = nil)
      output = ''

      name, software_version = map_cartridge_name(cartridge_name)
      cartridge           = CartridgeRepository.instance.select(name, software_version)

      OpenShift::Utils::Sdk.mark_new_sdk_app(@user.homedir)
      OpenShift::Utils::Cgroups::with_cgroups_disabled(@user.uuid) do
        create_cartridge_directory(cartridge, software_version)
        create_private_endpoints(cartridge)

        Dir.chdir(@user.homedir) do
          unlock_gear(cartridge) do |c|
            output << cartridge_setup(c, software_version)
            populate_gear_repo(c.directory, template_git_url)

            process_erb_templates(c.directory)
          end

        end

        output << do_control_with_directory('start', cartridge_dir: cartridge.directory)
      end

      connect_frontend(cartridge)

      logger.info "configure output: #{output}"
      output
    end

    # deconfigure(cartridge_name) -> nil
    #
    # Remove cartridge from gear
    #
    # deconfigure('php-5.3')
    def deconfigure(cartridge_name)
      cartridge = get_cartridge(cartridge_name)
      delete_private_endpoints(cartridge)
      OpenShift::Utils::Cgroups::with_cgroups_disabled(@user.uuid) do
        do_control_with_directory('stop', cartridge_dir: cartridge.directory)
        unlock_gear(cartridge) { |c| cartridge_teardown(c.directory) }
        delete_cartridge_directory(cartridge)
      end

      nil
    end

    # unlock_gear(cartridge_name) -> nil
    #
    # Prepare the given cartridge for the cartridge author
    #
    #   v2_cart_model.unlock_gear('php-5.3')
    def unlock_gear(cartridge)
      files = lock_files(cartridge)
      begin
        do_unlock(files)
        yield cartridge
      ensure
        do_lock(files)
      end
      nil
    end

    # lock_files(cartridge_name) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to manipulate
    #
    #   v2_cart_model.lock_files("php-5.3")
    def lock_files(cartridge)
      locked_files = File.join(cartridge.directory, 'metadata', 'locked_files.txt')
      return [] unless File.exist? locked_files

      File.readlines(locked_files).each_with_object([]) do |line, memo|
        line.chomp!
        case
          when line.empty?
            # skip blank lines
          when line.end_with?('/*')
            memo << Dir.glob(File.join(@user.homedir, line)).select { |f| File.file?(f) }
          when FILENAME_BLACKLIST.include?(line)
            logger.info("#{cartridge.directory} attempted lock/unlock on black listed entry [#{line}]")
          when !(line.start_with?('.') || line.start_with?(cartridge.directory) || line.start_with?('app-root'))
            logger.info("#{cartridge.directory} attempted lock/unlock on out-of-bounds entry [#{line}]")
          else
            memo << File.join(@user.homedir, line)
        end
      end
    end

    # do_unlock_gear(array of file names) -> array
    #
    # Take the given array of file system entries and prepare them for the cartridge author
    #
    #   v2_cart_model.do_unlock_gear(entries)
    def do_unlock(entries)
      mcs_label = @user.get_mcs_label(@user.uid)

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
          Utils.oo_spawn(
              "chown #{@user.uid}:#{@user.gid} #{entry};
               chcon unconfined_u:object_r:openshift_var_lib_t:#{mcs_label} #{entry}",
              expected_exitstatus: 0
          )
        rescue Utils::ShellExecutionException => e
          raise OpenShift::FileUnlockError.new("Failed to unlock file system entry [#{entry}]: #{e.stderr}",
                                               entry)
        end
      end

      begin
        Utils.oo_spawn("chown #{@user.uid}:#{@user.gid} #{@user.homedir}", expected_exitstatus: 0)
      rescue Utils::ShellExecutionException => e
        raise OpenShift::FileUnlockError.new(
                  "Failed to unlock gear home [#{@user.homedir}]: #{e.stderr}",
                  @user.homedir)
      end
    end

    # do_lock_gear(array of file names) -> array
    #
    # Take the given array of file system entries and prepare them for the application developer
    #    v2_cart_model.do_lock_gear(entries)
    def do_lock(entries)
      mcs_label = @user.get_mcs_label(@user.uid)

      # It is expensive doing one file at a time but...
      # ...it allows reporting on the failed command at the file level
      # ...we don't have to worry about the length of argv
      entries.each do |entry|
        begin
          Utils.oo_spawn(
              "chown root:#{@user.gid} #{entry};
               chcon unconfined_u:object_r:openshift_var_lib_t:#{mcs_label} #{entry}",
              expected_exitstatus: 0)
        rescue Utils::ShellExecutionException => e
          raise OpenShift::FileLockError.new("Failed to lock file system entry [#{entry}]: #{e.stderr}",
                                             entry)
        end
      end

      begin
        Utils.oo_spawn("chown root:#{@user.gid} #{@user.homedir}", expected_exitstatus: 0)
      rescue Utils::ShellExecutionException => e
        raise OpenShift::FileLockError.new("Failed to lock gear home [#{@user.homedir}]: #{e.stderr}",
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

      entries = Dir.glob(cartridge.repository_path + '/*', File::FNM_DOTMATCH)
      entries.delete_if do |e|
        basename = File.basename(e)
        %w(usr . ..).include?(basename)
      end

      target = File.join(@user.homedir, cartridge.directory)
      FileUtils.mkpath target
      Utils.oo_spawn("/bin/cp -ad #{entries.join(' ')} #{target}",
                     expected_exitstatus: 0)

      write_environment_variable(cartridge, File.join(target, 'env'),
                                 dir:   target + File::SEPARATOR,
                                 ident: Runtime::Cartridge.build_ident(cartridge.cartridge_vendor,
                                                                       cartridge.name,
                                                                       software_version,
                                                                       cartridge.cartridge_version))

      usr_path = File.join(cartridge.repository_path, 'usr')
      FileUtils.symlink(usr_path, File.join(target, 'usr')) if File.exist? usr_path

      mcs_label = @user.get_mcs_label(@user.uid)

      @user.add_env_var("NAMESPACE", @user.namespace, true)
      @user.add_env_var('PRIMARY_CARTRIDGE_DIR', target + File::SEPARATOR, true) if cartridge.primary?

      env_path = PathUtils.join(@user.homedir, '.env')
      Utils.oo_spawn(
          "chown -R root:#{@user.gid} #{env_path};
           chcon -R unconfined_u:object_r:openshift_var_lib_t:#{mcs_label} #{env_path}",
          expected_exitstatus: 0
      )

      Utils.oo_spawn(
          "chown -R #{@user.uid}:#{@user.gid} #{target};
           chcon -R unconfined_u:object_r:openshift_var_lib_t:#{mcs_label} #{target}",
          expected_exitstatus: 0
      )

      Utils.oo_spawn(
          "chcon system_u:object_r:bin_t:s0 #{File.join(target, 'bin', '*')}",
          expected_exitstatus: 0
      )

      logger.info("Created cartridge directory #{@user.uuid}/#{cartridge.directory}")
      nil
    end

    ##
    # Write out cartridge environment variables
    def write_environment_variable(cartridge, path, *hash)
      FileUtils.mkpath(path) unless File.exist? path

      hash.first.each_pair do |k, v|
        name = "OPENSHIFT_#{cartridge.short_name.upcase}_#{k.to_s.upcase}"
        File.open(PathUtils.join(path, name), 'w', 0666) do |f|
          f.write(%Q(export #{name}='#{v}'))
        end
      end
    end


    def delete_cartridge_directory(cartridge)
      logger.info("Deleting cartridge directory for #{@user.uuid}/#{cartridge.directory}")
      # TODO: rm_rf correct?
      FileUtils.rm_rf(File.join(@user.homedir, cartridge.directory))
      logger.info("Deleted cartridge directory for #{@user.uuid}/#{cartridge.directory}")
    end

    def populate_gear_repo(cartridge_name, template_git_url = nil)
      logger.info "Creating gear repo for #{@user.uuid}/#{cartridge_name} from `#{template_git_url}`"
      repo = ApplicationRepository.new(@user)
      if template_git_url.nil?
        repo.populate_from_cartridge(cartridge_name)
        repo.deploy_repository
      else
        raise NotImplementedError.new('populating repo from URL unsupported')
      end
      logger.info "Created gear repo for  #{@user.uuid}/#{cartridge_name}"
    end

    # process_erb_templates(cartridge_name) -> nil
    #
    # Search cartridge for any remaining <code>erb</code> files render them
    def process_erb_templates(cartridge_name)
      logger.info "Processing ERB templates for #{cartridge_name}"
      env = Utils::Environ.for_gear(@user.homedir)
      render_erbs(env, File.join(@user.homedir, cartridge_name, '**'))
    end

    #  cartridge_setup(cartridge, software_version) -> buffer
    #
    #  Returns the results from calling the cartridge's setup script.
    #  Includes <code>--version</code> if provided.
    #  Raises exception if script fails
    #
    #   stdout = cartridge_setup(cartridge_obj)
    def cartridge_setup(cartridge, software_version)
      logger.info "Running setup for #{@user.uuid}/#{cartridge.directory}"

      gear_env = Utils::Environ.load('/etc/openshift/env',
                                     File.join(@user.homedir, '.env'))

      cartridge_home     = File.join(@user.homedir, cartridge.directory)
      cartridge_env_home = File.join(cartridge_home, 'env')

      cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))
      render_erbs(cartridge_env, cartridge_env_home)
      cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))

      setup = File.join(cartridge_home, 'bin', 'setup')
      setup << " --version #{software_version}"
      out, _, _ = Utils.oo_spawn(setup,
                                 env:                 cartridge_env,
                                 unsetenv_others:     true,
                                 chdir:               @user.homedir,
                                 uid:                 @user.uid,
                                 expected_exitstatus: 0)
      logger.info("Ran setup for #{@user.uuid}/#{cartridge.directory}\n#{out}")
      out
    end

    # render_erbs(program environment as a hash, erb_path_glob) -> nil
    #
    # Using the path globbing provided + '/*.erb', run <code>erb</code> against each template tile.
    # See <code>Dir.glob</code> and <code>OpenShift::Utils.oo_spawn</code>
    #
    #   v2_cart_model.render_erbs({HOMEDIR => '/home/no_place_like'}, '/var/lib/...cartridge/env')
    def render_erbs(env, path_glob)
      Dir.glob(path_glob + '/*.erb').select { |f| File.file?(f) }.each do |file|
        begin
          Utils.oo_spawn(%Q{#{ERB_BINARY} -S 2 -- #{file} > #{file.chomp('.erb')}},
                         env:             env,
                         unsetenv_others: true,
                         chdir:           @user.homedir,
                         uid:             @user.uid,
                         expected_status: 0)
        rescue Utils::ShellExecutionException => e
          logger.info("Failed to render ERB #{file}: #{e.stderr}")
        else
          File.delete(file)
        end
      end
      nil
    end

    # cartridge_teardown(cartridge_name) -> buffer
    #
    # Returns the output from calling the cartridge's teardown script.
    #  Raises exception if script fails
    #
    # stdout = cartridge_teardown('php-5.3')
    def cartridge_teardown(cartridge_name)
      cartridge_home = File.join(@user.homedir, cartridge_name)
      env            = Utils::Environ.for_cartridge(cartridge_home)
      teardown       = File.join(cartridge_home, 'bin', 'teardown')

      return "" unless File.exists? teardown
      return "#{teardown}: is not executable\n" unless File.executable? teardown

      # FIXME: Will anyone retry if this reports error, or should we remove from disk no matter what?
      out, _, _ = Utils.oo_spawn(teardown,
                                 env:             env,
                                 unsetenv_others: true,
                                 chdir:           @user.homedir,
                                 uid:             @user.uid,
                                 expected_status: 0)
      FileUtils.rm_r(cartridge_home)
      logger.info("Ran teardown for #{@user.uuid}/#{cartridge_name}")
      out
    end

    # Allocates and assigns private IP/port entries for a cartridge
    # based on endpoint metadata for the cartridge.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors
    # here are considered fatal.
    def create_private_endpoints(cartridge)
      logger.info "Creating private endpoints for #{@user.uuid}/#{cartridge.directory}"

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

        if address_bound?(private_ip, endpoint.private_port)
          raise "Couldn't create private endpoint #{endpoint.private_ip_name}(#{endpoint.private_port}) "\
            "because an existing process was bound to the IP (private_ip)"
        end

        @user.add_env_var(endpoint.private_port_name, endpoint.private_port)

        logger.info("Created private endpoint for cart #{cartridge.name} in gear #{@user.uuid}: "\
          "[#{endpoint.private_ip_name}=#{private_ip}, #{endpoint.private_port_name}=#{endpoint.private_port}]")
      end

      logger.info "Created private endpoints for #{@user.uuid}/#{cartridge.directory}"
    end

    def delete_private_endpoints(cartridge)
      logger.info "Deleting private endpoints for #{@user.uuid}/#{cartridge.directory}"

      cartridge.endpoints.each do |endpoint|
        @user.remove_env_var(endpoint.private_ip_name)
        @user.remove_env_var(endpoint.private_port_name)
      end

      logger.info "Deleted private endpoints for #{@user.uuid}#{cartridge.directory}"
    end

    # Finds the next IP address available for binding of the given port for
    # the current gear user. The IP is assumed to be available only if:
    #
    #   1. The IP is not already associated with an existing endpoint defined
    #      by any cartridge within the gear, and
    #   2. The IP/port is not already bound to a process according to lsof.
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

        # Check to ensure the IP/port is not currently bound to another process
        if address_bound?(candidate_ip, port)
          logger.debug("Candidate address #{candidate_ip}:#{port} is unallocated by the gear
            but is already bound to another process and will be skipped")
          next
        end

        open_ip = candidate_ip
        break
      end

      open_ip
    end

    # Returns true if the given IP and port are currently bound
    # according to lsof, otherwise false.
    def address_bound?(ip, port)
      _, _, rc = Utils.oo_spawn("/usr/sbin/lsof -i @#{ip}:#{port}")
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

    def connect_frontend(cartridge)
      frontend = OpenShift::FrontendHttpServer.new(@user.uuid, @user.container_name, @user.namespace)
      gear_env = Utils::Environ.for_gear(@user.homedir)

      begin
        # TODO: exception handling
        cartridge.endpoints.each do |endpoint|
          endpoint.mappings.each do |mapping|
            private_ip  = gear_env[endpoint.private_ip_name]
            backend_uri = "#{private_ip}:#{endpoint.private_port}#{mapping.backend}"
            options     = mapping.options ||= {}

            logger.info("Connecting frontend mapping for #{@user.uuid}/#{cartridge.name}: "\
                      "#{mapping.frontend} => #{backend_uri} with options: #{mapping.options}")
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
        next if cart_dir.end_with?('app-root') || cart_dir.end_with?('git') ||
            (not File.directory? cart_dir)
        yield cart_dir
      end
    end

    def build(cartridge)
      ApplicationRepository.new(@user).deploy_repository
      do_control("build", cartridge)
    end

    def deploy(cartridge)
      do_control("deploy", cartridge)
    end

    def do_control(action, cartridge, options={})
      case cartridge
        when String
          cartridge_dir = cartridge_directory(cartridge)
        when OpenShift::Runtime::Cartridge
          cartridge_dir = cartridge.directory
        else
          raise "Unsupported cartridge argument type: #{cartridge.class}"
      end

      options[:cartridge_dir] = cartridge_dir

      do_control_with_directory(action, options)
    end

    # :call-seq:
    #    V2CartridgeModel.new(...).connector_execute(cartridge_name, connector, args)
    #
    def connector_execute(cart_name, connector, args)
      env = Utils::Environ.for_gear(@user.homedir)

      cartridge = get_cartridge(cart_name)
      script    = PathUtils.join(@user.homedir, cartridge.directory, 'hooks', connector)

      unless File.executable?(script)
        msg = "ERROR: action '#{connector}' not found."
        raise Utils::ShellExecutionException.new(msg, 127, msg)
      end

      command      = script << " " << args
      out, err, rc = Utils.oo_spawn(command,
                                    env:             env,
                                    unsetenv_others: true,
                                    chdir:           @user.homedir,
                                    timeout:         60,
                                    uid:             @user.uid)
      if 0 == rc
        logger.info("(#{rc})\n------\n#{cleanpwd(out)}\n------)")
        return out
      end

      logger.info("ERROR: (#{rc})\n------\n#{cleanpwd(out)}\n------)")
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
    #   :cartridge_dir => path             : process all cartridges (if +nil+) or the provided cartridge
    #   :pre_action_hooks_enabled => true  : whether to process repo action hooks before +action+
    #   :post_action_hooks_enabled => true : whether to process repo action hooks after +action+
    #   :prefix_action_hooks => true       : if +true+, action hook names are automatically prefixed with
    #                                        'pre' and 'post' depending on their execution order.
    def do_control_with_directory(action, options={})
      cartridge_dir             = options[:cartridge_dir]
      pre_action_hooks_enabled  = options.has_key?(:pre_action_hooks_enabled)  ? options[:pre_action_hooks_enabled]  : true
      post_action_hooks_enabled = options.has_key?(:post_action_hooks_enabled) ? options[:post_action_hooks_enabled] : true
      prefix_action_hooks       = options.has_key?(:prefix_action_hooks)       ? options[:prefix_action_hooks]       : true

      logger.debug { "#{@user.uuid} #{action} against '#{cartridge_dir}'" }
      buffer       = ''
      gear_env     = Utils::Environ.load('/etc/openshift/env', File.join(@user.homedir, '.env'))
      action_hooks = File.join(@user.homedir, %w{app-root runtime repo .openshift action_hooks})

      if pre_action_hooks_enabled
        pre_action_hook = prefix_action_hooks ? "pre_#{action}" : action
        buffer << do_action_hook(pre_action_hook, gear_env)
      end

      process_cartridges(cartridge_dir) { |path|
        cartridge_env = gear_env.merge(Utils::Environ.load(File.join(path, 'env')))

        ident                            = cartridge_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
        _, software, software_version, _ = Runtime::Cartridge.parse_ident(cartridge_env[ident.first])
        hooks                            = cartridge_hooks(action_hooks, action, software, software_version)

        control = File.join(path, 'bin', 'control')

        command = ['set -e']
        command << hooks[:pre] unless hooks[:pre].empty?
        command << "#{control} #{action}" if File.executable? control
        command << hooks[:post] unless hooks[:post].empty?

        out, err, rc = Utils.oo_spawn(command.join('; '),
                                      env:             cartridge_env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid)
        buffer << out

        raise Utils::ShellExecutionException.new(
                  "Failed to execute: 'control #{action}' for #{path}", rc, buffer, err
              ) if rc != 0
      }

      if post_action_hooks_enabled
        post_action_hook = prefix_action_hooks ? "post_#{action}" : action
        buffer << do_action_hook(post_action_hook, gear_env)
      end
      
      buffer
    end

    ##
    # Executes the named +action+ from the user repo +action_hooks+ directory and returns the
    # stdout of the execution, or raises a +ShellExecutionException+ if the action returns a
    # non-zero return code.
    def do_action_hook(action, env)
      action_hooks_dir = File.join(@user.homedir, %w{app-root runtime repo .openshift action_hooks})
      action_hook = File.join(action_hooks_dir, action)
      out = ''

      if File.executable?(action_hook)
        out, err, rc = Utils.oo_spawn(action_hook,
                                      env:             env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid)
        raise Utils::ShellExecutionException.new(
                  "Failed to execute action hook '#{action}' for #{@user.uuid} application #{@user.app_name}",
                  rc, out, err
              ) if rc != 0
      end

      out
    end

    def cartridge_hooks(action_hooks, action, name, version)
      hooks = {pre: [], post: []}

      hooks.keys do |key|
        new_hook = PathUtils.join(action_hooks, "#{key}_#{action}_#{cartridge.directory}")
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
    # Returns the combined output of all +stop+ action executions as a +String+.
    def stop_gear(options={})
      buffer = ''
      each_cartridge do |cartridge|
        buffer << do_control('stop', cartridge)
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
    # # +options+: hash
    #   :primary_only   => [boolean]  : If +true+, only the primary cartridge will be started.
    #                                   Mutually exclusive with +secondary_only+.
    #   :secondary_only => [boolean]  : If +true+, all cartridges except the primary cartridge
    #                                   will be started. Mutually exclusive with +primary_only+.
    #
    # Returns the combined output of all +start+ action executions as a +String+.
    def start_gear(options={})
      if options[:primary_only] && options[:secondary_only]
        raise "The primary_only and secondary_only options are mutually exclusive"
      end

      buffer = ''
      each_cartridge do |cartridge|
        next if options[:primary_only] and not cartridge.primary?
        next if options[:secondary_only] and cartridge.primary?

        buffer << do_control('start', cartridge)
      end

      buffer
    end

    def cleanpwd(arg)
      arg.gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]').gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i,'\\1[HIDDEN]')
    end
  end
end
