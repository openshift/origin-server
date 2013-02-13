require 'rubygems'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  class V2CartridgeModel
    def initialize(config, user, gear, logger = nil)
      @config = config
      @user = user
      @gear = gear
      @logger = logger ||= Logger.new(STDOUT)
      @timeout = 30
    end

    def get_cart_manifest_path(cart_name)
      File.join(@config.get('CARTRIDGE_BASE_PATH'), cart_name, 'metadata', 'manifest.yml')
    end

    def destroy(skip_hooks = false)
      # TODO: honor skip_hooks
      Dir.entries(@user.homedir).each do |gear_subdir|
        teardown_hook = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'bin', 'teardown')

        next unless File.exists?(teardown_hook)

        begin
          # Execute the hook in the context of the gear user
          @logger.debug("Executing cart teardown hook #{teardown_hook} in gear #{@gear.uuid} as user #{@user.uid}:#{@user.gid}")
          run_as(@user.uid, @user.gid, teardown_hook, gear_dir, false, 0, @timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          @logger.warn("Cartridge tidy operation failed on gear #{@gear.uuid} for cart #{gear_dir}: #{e.message} (rc=#{e.rc})")
        end
      end

      @user.destroy
    end

    def tidy
      # TODO: introduce better implementation using Cartridge model class
      Dir.entries(@user.homedir).each do |gear_subdir|
        tidy_script = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'bin', 'control') + ' tidy'
          
        next unless File.exists?(tidy_script)

        begin
          # Execute the hook in the context of the gear user
          @logger.debug("Executing cart tidy script #{tidy_script} in gear #{@gear.uuid} as user #{@user.uid}:#{@user.gid}")
          run_as(@user.uid, @user.gid, tidy_script, gear_dir, false, 0, @timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          @logger.warn("Cartridge tidy operation failed on gear #{@gear.uuid} for cart #{gear_dir}: #{e.message} (rc=#{e.rc})")
        end
      end
    end

    def add_cart(cart)
      OpenShift::Utils::Sdk.mark_new_sdk_app(@user.homedir)

      # Disable cgroups
      # Acquire IP and expose
      # Create standard env vars
      # Create initial cart directory
      # Setup gear git repo (add to unix user?)
      # Populate gear git repo if cartridge provides template.
      # Process cart ERB templates (still necessary?)
      
    end

    def remove_cart(cart)

    end

    # Allocates and assigns private IP/port entries for a cartridge
    # based on endpoint metadata for the cartridge.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors
    # here are considered fatal.
    def create_private_endpoints(cart_name)
      cart = @gear.get_cartridge(cart_name)

      allocated_ips = {}

      cart.endpoints.each do |endpoint|
        # Reuse previously allocated IPs of the same name. When recycling
        # an IP, double-check that it's not bound to the target port, and
        # bail if it's unexpectedly bound.
        unless allocated_ips.has_key?(endpoint.private_ip_name)
          # Allocate a new IP for the endpoint
          private_ip = find_open_ip(endpoint.private_port)

          if private_ip == nil
            raise "No IP was available to create endpoint for cart #{cart.name} in gear #{@gear.uuid}: "\
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
        
        @logger.info("Created private endpoint for cart #{cart.name} in gear #{@gear.uuid}: "\
          "[#{endpoint.private_ip_name}=#{private_ip}, #{endpoint.private_port_name}=#{endpoint.private_port}]")
      end
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

      open_ip = nil

      for host_ip in 1..127
        candidate_ip = UnixUser.get_ip_addr(@user.uid.to_i, host_ip)

        # Skip the IP if it's already assigned to an endpoint
        next if allocated_ips.include?(candidate_ip)

        # Check to ensure the IP/port is not currently bound to another process
        next if address_bound?(candidate_ip, port)
        
        open_ip = candidate_ip
        break
      end

      return open_ip
    end

    # Returns true if the given IP and port are currently unbound
    # according to lsof, otherwise false.
    def address_bound?(ip, port)
      out, err, rc = shellCmd("/usr/sbin/lsof -i @#{ip}:#{port}")
      return rc != 0
    end

    # Returns an array containing all currently allocated endpoint private
    # IP addresses assigned to carts within the current gear, or an empty
    # array if none are currently defined.
    def get_allocated_private_ips
      env = Utils::Environ::for_gear(@user.homedir)

      allocated_ips = []

      # Collect all existing endpoint IP allocations
      @cart_model.process_cartridges do |cart_path|
        cart_name = File.basename(cart_path)
        cart = get_cartridge(cart_name)

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
    def process_cartridges
      Dir[File.join(@user.homedir, "*-*")].each do |cart_dir|
        next if "app-root" == cart_dir ||
            (not File.directory? cart_dir)
        yield cart_dir
      end
    end

    # Execute action using each cartridge's control script in gear
    def do_control(action, cart_name=nil)
      buffer       = ''
      gear_env     = Utils::Environ.load('/etc/openshift/env', File.join(user.homedir, '.env'))
      action_hooks = File.join(user.homedir, %w{app-root runtime repo .openshift action_hooks})

      pre_action = File.join(action_hooks, "pre_#{action}")
      if File.executable?(pre_action)
        out, _, _ = Utils.oo_spawn(pre_action,
                                   env:                 gear_env,
                                   unsetenv_others:     true,
                                   chdir:               user.homedir,
                                   expected_exitstatus: 0)
        buffer << out
      end

      @cart_model.process_cartridges { |path|
        cartridge_env = gear_env.merge(Utils::Environ.load(File.join(path, "env")))

        control = Files.join(path, %w{bin control})
        unless File.executable? control
          raise "Corrupt cartridge: #{control} must exist and be executable"
        end

        cartridge   = File.basename(path)
        pre_action  = File.join(action_hooks, "pre_#{action}_#{cartridge}")
        post_action = File.join(action_hooks, "post_#{action}_#{cartridge}")

        command = ''
        command << "source #{pre_action};  " if File.exist? pre_action
        command << "#{control} #{action}   "
        command << "; source #{post_action}" if File.exist? post_action

        out, _, _ = Utils.oo_spawn(command,
                                   env:                 cartridge_env,
                                   unsetenv_others:     true,
                                   chdir:               user.homedir,
                                   expected_exitstatus: 0)
        buffer << out
      }

      post_action = File.join(action_hooks, "post_#{action}")
      if File.executable?(post_action)
        out, _, _ = Utils.oo_spawn(post_action,
                                   env:                 gear_env,
                                   unsetenv_others:     true,
                                   chdir:               user.homedir,
                                   expected_exitstatus: 0)
        buffer << out
      end
      buffer
    end
  end
end
