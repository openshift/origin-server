require 'rubygems'
require 'logger'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/environ'

module OpenShift
  # TODO use this expections when oo_spawn fails...
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

    def initialize(config, user)
      @config  = config
      @user    = user
      @timeout = 30
    end

    # Loads a cartridge from manifest for the given name.
    #
    # In this WIP, V2 cartridges are installed to and loaded
    # from 
    #
    # /usr/libexec/openshift/cartridges/v2
    #
    # The planned path on disk that V2 cartridges 
    # will be installed to in the end-state of this WIP is
    #
    # /usr/libexec/openshift/v2/cartridges
    #
    # We need to determine whether CARTRIDGE_BASE_PATH can safely
    # be used in V2 code.  It points directly to
    #
    # /usr/libexec/openshift/cartridges
    #
    # TODO: Caching?
    def get_cartridge(cart_name)
      begin
        manifest_path = File.join(@config.get('CARTRIDGE_BASE_PATH'), 'v2', cart_name, 'metadata', 'manifest.yml')
        manifest = YAML.load_file(manifest_path)
        return OpenShift::Runtime::Cartridge.new(manifest)
      rescue => e
        logger.error(e.backtrace)
        raise "Failed to load cart manifest from #{manifest_path} for cart #{cart_name} in gear #{@user.uuid}: #{e.message}"
      end
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
      cartridge_name = 'N/A'
      process_cartridges do |path|
        begin
          cartridge_name = File.basename(path)
          cartridge_teardown(cartridge_name)
        rescue Utils::ShellExecutionException => e
          logger.warn("Cartridge teardown operation failed on gear #{@user.uuid} for cartridge #{cartridge_name}: #{e.message} (rc=#{e.rc})")
        end
      end

      # Ensure we're not in the gear's directory
      Dir.chdir(@config.get("GEAR_BASE_DIR")) {
        @user.destroy
      }
    end

    # tidy() -> nil
    #
    # Run tidy operation on each cartridge on a gear
    #
    # tidy()
    def tidy
      begin
        do_control('tidy')
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

      OpenShift::Utils::Sdk.mark_new_sdk_app(@user.homedir)
      OpenShift::Utils::Cgroups::with_cgroups_disabled(@user.uuid) do
        create_cartridge_directory(cartridge_name)
        create_standard_env_vars(cartridge_name)
        create_private_endpoints(cartridge_name)

        Dir.chdir(@user.homedir) do
          unlock_gear(cartridge_name) do |c|
            output << cartridge_setup(c)
            populate_gear_repo(c, template_git_url)
          end
        end

        process_erb_templates(cartridge_name)

        do_control('start', cartridge_name)
        OpenShift::FrontendHttpServer.new(@user.container_uuid, @user.container_name, @user.namespace).reload_httpd
      end

      logger.info "configure output: #{output}"
      output
    end

    # deconfigure(cartridge_name) -> nil
    #
    # Remove cartridge from gear
    #
    # deconfigure('php-5.3')
    def deconfigure(cartridge_name)
      delete_private_endpoints(cartridge_name)
      OpenShift::Utils::Cgroups::with_cgroups_disabled(@user.uuid) do
        do_control('stop', cartridge_name)
        unlock_gear(cartridge_name) { |c| cartridge_teardown(c) }
        delete_cartridge_directory(cartridge_name)
      end

      OpenShift::FrontendHttpServer.new(@user.container_uuid, @user.container_name, @user.namespace).reload_httpd

      nil
    end

    # unlock_gear(cartridge_name) -> nil
    #
    # Prepare the given cartridge for the cartridge author
    #
    #   v2_cart_model.unlock_gear('php-5.3')
    def unlock_gear(cartridge_name)
      files = lock_files(cartridge_name)
      begin
        do_unlock_gear(files)
        yield cartridge_name
      ensure
        do_lock_gear(files)
      end
      nil
    end

    # lock_files(cartridge_name) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to manipulate
    #
    #   v2_cart_model.lock_files("php-5.3")
    def lock_files(cartridge_name)
      locked_files = File.join(cartridge_name, 'metadata', 'locked_files.txt')
      return Array.new unless File.exist? locked_files

      files = Array.new
      File.readlines(locked_files).each do |line|
        line.chomp!
        case
          when line.end_with?('/*')
            files << Dir.glob(File.join(@user.homedir, line)).select { |f| File.file?(f) }
          when FILENAME_BLACKLIST.include?(line)
            # forbidden name used
          when !(line.start_with?('.') || line.start_with?(cartridge_name) || line.start_with?('app-root'))
            # out of bounds
          else
            files << File.join(@user.homedir, line)
        end
      end
      files
    end

    # do_unlock_gear(array of file names) -> nil
    #
    # Take the given array of file system entries and prepare them for the cartridge author
    #
    #   v2_cart_model.do_unlock_gear(entries)
    def do_unlock_gear(entries)
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
        Utils.oo_spawn(
            "chown #{@user.uid}:#{@user.gid} #{entry};
             chcon unconfined_u:object_r:openshift_var_lib_t:#{mcs_label} #{entry}",
             expected_exitstatus: 0
        )
      end
      nil
    end

    # do_lock_gear(array of file names) -> nil
    #
    # Take the given array of file system entries and prepare them for the application developer
    #    v2_cart_model.do_lock_gear(entries)
    def do_lock_gear(entries)
      mcs_label = @user.get_mcs_label(@user.uid)

      # It is expensive doing one file at a time but...
      # ...it allows reporting on the failed command at the file level
      # ...we don't have to worry about the length of argv
      entries.each do |entry|
        Utils.oo_spawn(
            "chown root:root #{entry};
             chcon system_u:object_r:openshift_var_lib_t:#{mcs_label} #{entry}",
             expected_exitstatus: 0
        )
      end
      nil
    end

    def create_standard_env_vars(cart_name)
    # TODO: determine which env vars to create
    #  LOG_DIR
    #  add bin directory to PATH


    end

    # create_cartridge_directory(cartridge name) -> nil
    #
    # Create the cartridges home directory
    #
    #   v2_cart_model.create_cartridge_directory('php-5.3')
    def create_cartridge_directory(cartridge_name)
      logger.info("Creating cartridge directory for #{cartridge_name}")
      # TODO: resolve correct location of v2 carts
      base = File.join(@config.get('CARTRIDGE_BASE_PATH'), 'v2', cartridge_name)

      Utils.oo_spawn("/bin/cp -ad #{base} .",
                     chdir:               @user.homedir,
                     expected_exitstatus: 0)
      Utils.oo_spawn(
          "chcon -R --reference=#{@user.homedir} #{File.join(@user.homedir, cartridge_name)}",
          expected_exitstatus: 0)
      logger.info("Created cartridge directory for #{cartridge_name}")
      nil
    end

    def delete_cartridge_directory(cartridge_name)
      File.rm_r(File.join(@user.homedir, cartridge_name))
    end

    def populate_gear_repo(cartridge_name, template_git_url = nil)
      logger.info "Creating gear repo for #{cartridge_name}"
      repo = ApplicationRepository.new(@user)
      if template_git_url.nil?
        repo.populate_from_cartridge(cartridge_name)
      else
        raise NotImplementedError('populating repo from URL unsupported')
      end
      logger.info "Created gear repo for #{cartridge_name}"
    end

    # process_erb_templates(cartridge_name) -> nil
    #
    # Search cartridge for any remaining <code>erb</code> files render them
    def process_erb_templates(cartridge_name)
      logger.info "Processing ERB templates for #{cartridge_name}"
      env = Utils::Environ.for_gear(@user.homedir)
      render_erbs(env, File.join(@user.homedir, cartridge_name, '**'))
    end

    #  cartridge_setup(cartridge_name, version=nil) -> buffer
    #
    #  Returns the results from calling the cartridge's setup script.
    #  Includes <code>--version</code> if provided.
    #  Raises exception if script fails
    #
    #   stdout = cartridge_setup('php-5.3')
    def cartridge_setup(cartridge_name, version=nil)
      logger.info "Running setup for #{cartridge_name}"
      # FIXME: Where?
      # setup IP Addresses

      gear_env = Utils::Environ.load('/etc/openshift/env',
                                     File.join(@user.homedir, '.env'))

      cartridge_home     = File.join(@user.homedir, cartridge_name)
      cartridge_env_home = File.join(cartridge_home, 'env')

      cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))
      render_erbs(cartridge_env, cartridge_env_home)
      cartridge_env = gear_env.merge(Utils::Environ.load(cartridge_env_home))

      setup = File.join(cartridge_home, 'bin', 'setup')
      setup << "--version=#{version}" if version

      out, err, rc = Utils.oo_spawn(setup,
                                    env:             cartridge_env,
                                    unsetenv_others: true,
                                    chdir:           @user.homedir,
                                    uid:             @user.uid)

      raise Utils::ShellExecutionException.new(
                "Failed to execute: #{setup} for #{@user.uuid} in #{@user.homedir}",
                rc, out, err) unless 0 == rc
      logger.info("Ran setup for #{cartridge_name} for user #{@user.uuid} in #{cartridge_home}")
      logger.info("Setup output: #{out}")
      out
    end

    # render_erbs(program environment as a hash, erb_path_glob) -> nil
    #
    # Using the path globbing provided + '/*.erb', run <code>erb</code> against each template tile.
    # See <code>Dir.glob</code> and <code>OpenShift::Utils.oo_spawn</code>
    #
    #   v2_cart_model.render_erbs({HOMEDIR => '/home/no_place_like'}, '/var/lib/...cartridge/env.*erb')
    def render_erbs(env, path_glob)
      path_glob << '/*.erb'
      Dir.glob(path_glob).select { |f| File.file?(f) }.each do |file|
        # FIXME: need to determine path to correct erb. oo-ruby?
        Utils.oo_spawn(%Q{erb -S 2 -- #{file} > #{file.chomp('.erb')}},
                       env:             env,
                       unsetenv_others: true,
                       chdir:           @user.homedir,
                       uid:             @user.uid,
                       expected_status: 0)
        File.delete(file)
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

      # FIXME: Will anyone retry if this reports error, or should we remove from disk no matter what?
      out, _, _      = Utils.oo_spawn(teardown,
                                      env:             env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid,
                                      expected_status: 0)
      FileUtils.rm_r(cartridge_home)
      logger.info("Removed #{cartridge_name} for user #{@user.uuid} from #{cartridge_home}")
      out
    end

    # Allocates and assigns private IP/port entries for a cartridge
    # based on endpoint metadata for the cartridge.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors
    # here are considered fatal.
    def create_private_endpoints(cart_name)
      logger.info "Creating private endpoints for #{cart_name}"
      cart = get_cartridge(cart_name)

      allocated_ips = {}

      cart.endpoints.each do |endpoint|
        # Reuse previously allocated IPs of the same name. When recycling
        # an IP, double-check that it's not bound to the target port, and
        # bail if it's unexpectedly bound.
        unless allocated_ips.has_key?(endpoint.private_ip_name)
          # Allocate a new IP for the endpoint
          private_ip = find_open_ip(endpoint.private_port)

          if private_ip == nil
            raise "No IP was available to create endpoint for cart #{cart.name} in gear #{@user.uuid}: "\
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

        logger.info("Created private endpoint for cart #{cart.name} in gear #{@user.uuid}: "\
          "[#{endpoint.private_ip_name}=#{private_ip}, #{endpoint.private_port_name}=#{endpoint.private_port}]")
      end

      logger.info "Created private endpoints for #{cart_name}"
    end

    # TODO: How should this be implemented?
    def delete_private_endpoints(cart_name)
      raise "Not implemented"
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
        cart_name = File.basename(cart_path)
        cart      = get_cartridge(cart_name)

        cart.endpoints.each do |endpoint|
          # TODO: If the private IP variable exists but the value isn't in
          # the environment, what should happen?
          ip = env[endpoint.private_ip_name]
          allocated_ips << ip unless ip == nil
        end
      end

      allocated_ips
    end

    # Run code block against each cartridge in gear
    #
    # @param  [block]  Code block to process cartridge
    # @yields [String] cartridge directory for each cartridge in gear
    def process_cartridges(cartridge_name = nil) # : yields cartridge_path
      unless cartridge_name.nil?
        cart_dir = File.join(@user.homedir, cartridge_name)
        yield cart_dir if File.exist?(cart_dir)
        return
      end

      # TODO: temporary hack to deal w/ version ambiguity and 'mock' cart.
      Dir[File.join(@user.homedir, "*")].each do |cart_dir|
        next if cart_dir.end_with?('app-root') ||
            (not File.directory? cart_dir)
        yield cart_dir
      end
    end

    # Execute action using each cartridge's control script in gear
    def do_control(action, cartridge_name=nil)
      buffer       = ''
      gear_env     = Utils::Environ.load('/etc/openshift/env', File.join(@user.homedir, '.env'))
      action_hooks = File.join(@user.homedir, %w{app-root runtime repo .openshift action_hooks})

      pre_action = File.join(action_hooks, "pre_#{action}")
      if File.executable?(pre_action)
        out, err, rc = Utils.oo_spawn(pre_action,
                                      env:             gear_env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid)
        buffer << out
        raise Utils::ShellExecutionException.new(
                  "Failed to execute: '#{pre_action}' for #{@user.uuid} application #{@user.app_name}",
                  rc, buffer, err
              ) if rc != 0
      end

      process_cartridges(cartridge_name) { |path|
        cartridge_env = gear_env.merge(Utils::Environ.load(File.join(path, 'env')))

        control = File.join(path, 'bin', 'control')
        unless File.executable? control
          # TODO: This may not be an error for plugin cartridges...
          raise "Corrupt cartridge: #{control} must exist and be executable"
        end

        cartridge   = File.basename(path)
        pre_action  = File.join(action_hooks, "pre_#{action}_#{cartridge}")
        post_action = File.join(action_hooks, "post_#{action}_#{cartridge}")

        command = 'set -e;'
        command << "source #{pre_action};  " if File.exist? pre_action
        command << "#{control} #{action}   "
        command << "; source #{post_action}" if File.exist? post_action

        out, err, rc = Utils.oo_spawn(command,
                                      env:             cartridge_env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid)
        buffer << out

        raise Utils::ShellExecutionException.new(
                  "Failed to execute: 'control #{action}' for #{path}", rc, buffer, err
              ) if rc != 0
      }

      post_action = File.join(action_hooks, "post_#{action}")
      if File.executable?(post_action)
        out, err, rc = Utils.oo_spawn(post_action,
                                      env:             gear_env,
                                      unsetenv_others: true,
                                      chdir:           @user.homedir,
                                      uid:             @user.uid)
        buffer << out
        raise Utils::ShellExecutionException.new(
                  "Failed to execute: '#{post_action}' for #{@user.uuid} application #{@user.app_name}",
                  rc, buffer, err
              ) if rc != 0
      end
      buffer
    end
  end
end
