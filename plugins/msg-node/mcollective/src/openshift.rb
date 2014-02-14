require 'rubygems'
require 'open4'
require 'pp'
require 'json'
require 'zlib'
require 'base64'
require 'etc'
require 'openshift-origin-node'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/utils/hourglass'
require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-common/utils/file_needs_sync'
require 'shellwords'
require 'facter'
require 'stringio'

module MCollective
  module Agent
    class Openshift<RPC::Agent
      # Metadata moved to openshift.ddl

      activate_when do
        @@config = ::OpenShift::Config.new

        PathUtils.flock('/var/lock/oo-cartridge-repository') do
          @@cartridge_repository = ::OpenShift::Runtime::CartridgeRepository.instance

          Dir.glob(PathUtils.join(@@config.get('CARTRIDGE_BASE_PATH'), '*')).each do |path|
            begin
              manifest = @@cartridge_repository.install(path)
              Log.instance.info("Installed cartridge (#{manifest.cartridge_vendor}, #{manifest.name}, #{manifest.version}, #{manifest.cartridge_version}) from #{path}")
            rescue Exception => e
              Log.instance.warn("Failed to install cartridge from #{path}. #{e.message}")
            end
          end
        end

        Log.instance.info(
            "#{@@cartridge_repository.count} cartridge(s) installed in #{@@cartridge_repository.path}")

        begin
          if path = @@config.get('AGENT_EXTENSION')
            require path
            include ::Openshift::AgentExtension
            agent_startup
          end
        rescue Exception => e
          Log.instance.error e.message
          Log.instance.error e.backtrace.inspect
        end

        true
      end

      def startup_hook
        # If meta[:timeout] is not set Node operations will fail as default is too low
        @hourglass_timeout = (meta[:timeout] * 0.65).ceil
        Log.instance.info(
            "Node transaction timeout is #{@hourglass_timeout}, mcollective timeout is #{meta[:timeout]}")
      end

      def before_processing_hook(msg, connection)
        # Set working directory to a 'safe' directory to prevent Dir.chdir
        # calls with block from changing back to a directory which doesn't exist.
        Log.instance.debug('Changing working directory to /tmp')
        Dir.chdir('/tmp')
      end


      def echo_action
        validate :msg, String
        reply[:msg] = request[:msg]
      end

      def cleanpwd(arg)
        arg.gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]').gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]')
      end

      def get_facts_action
        reply[:output] = {}
        request[:facts].each do |fact|
          reply[:output][fact.to_sym] = MCollective::Util.get_fact(fact)
        end
      end

      # Handles all incoming messages. Validates the input, executes the action, and constructs
      # a reply.
      def cartridge_do_action
        Log.instance.info("cartridge_do_action call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        Log.instance.info("cartridge_do_action validation = #{request[:cartridge]} #{request[:action]} #{request[:args]}")

        validate :cartridge, :shellsafe
        validate :action, :shellsafe

        action = request[:action]
        args   = request[:args] ||= {}

        args['--with-hourglass'] = OpenShift::Runtime::Utils::Hourglass.new(@hourglass_timeout)

        # Do the action execution
        exitcode, output, addtl_params = execute_action(action, args)

        if args['--with-container-uuid']
          report_quota(output, args['--with-container-uuid'])
          if report_resource(output, args['--with-app-name'])
            exitcode = 222
          end
        end

        reply[:exitcode]     = exitcode
        reply[:output]       = output
        reply[:addtl_params] = addtl_params
        args.delete('--with-hourglass')

        if exitcode == 0
          Log.instance.info("cartridge_do_action reply (#{exitcode}):\n------\n#{cleanpwd(output)}\n------)")
        else
          Log.instance.info("cartridge_do_action failed (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
          reply.fail! "cartridge_do_action failed #{exitcode}. Output #{output}"
        end
      end

      # Dispatches the given action to a method on the agent.
      #
      # Returns [exitcode, output] from the resulting action execution.
      def execute_action(action, args)
        start = Time.now
        action_method = "oo_#{action.gsub('-', '_')}"

        logger_context_entries = {
          action_method: action_method,
          request_id: args['--with-request-id'],
          container_uuid: args['--with-container-uuid'],
          app_uuid: args['--with-app-uuid']
        }

        exitcode = 0
        output   = ""
        addtl_params = nil

        if not self.respond_to?(action_method)
          exitcode = 127
          output   = "Unsupported action: #{action}/#{action_method}"
        else
          Log.instance.info("Executing action [#{action}] using method #{action_method} with args [#{args}]")
          begin
            logger_context_entries.each {|k, v| OpenShift::Runtime::NodeLogger.context[k] = v.to_s if v}

            exitcode, output, addtl_params = self.send(action_method.to_sym, args)
          rescue Exception => e
            report_exception e
            Log.instance.error("Unhandled action execution exception for action [#{action}]: #{e.message}")
            Log.instance.error(e.backtrace)
            exitcode = 127
            output   = "An internal exception occurred processing action #{action}: #{e.message}"
          ensure
            logger_context_entries.each {|k, v| OpenShift::Runtime::NodeLogger.context.delete(k)}
          end
          Log.instance.info("Finished executing action [#{action}] (#{exitcode}) Time to execute #{Time.now - start}")
        end

        return exitcode, output, addtl_params
      end

      # report approaching quota overage.
      #
      def report_quota(buffer, uuid)
        watermark = @@config.get('QUOTA_WARNING_PERCENT', '90.0').to_f
        ::OpenShift::Runtime::Node.check_quotas(uuid, watermark).each do |line|
          buffer << "\nCLIENT_MESSAGE: #{line}\n"
        end
      end

      def report_resource(buffer, app_name = '<app>')
        buffer.match(/Resource temporarily unavailable/) do
          buffer << "\nCLIENT_MESSAGE: Resources unavailable for operation. You may need to run 'rhc force-stop-app -a #{app_name}' and retry.\n"
          return true
        end
        false
      end

      # Executes a list of jobs sequentially, adding the exitcode and output
      # from execute_action to each job following the execution.
      #
      # The actual message reply object is set with an exitcode of 0 and
      # output containing the job list (in which the individual execution
      # results are embedded).
      #
      # BZ 876942: Disable threading until we can explore proper concurrency management
      def execute_parallel_action
        start = Time.now
        Log.instance.info("execute_parallel_action call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")

        hourglass = OpenShift::Runtime::Utils::Hourglass.new(@hourglass_timeout)

        quota_reported = false
        joblist        = request[config.identity]
        joblist.each do |parallel_job|

          job                      = parallel_job[:job]
          action                   = job[:action]
          args                     = job[:args]
          args['--with-hourglass'] = hourglass

          exitcode, output, addtl_params = execute_action(action, args)

          if args['--with-container-uuid']
            if !quota_reported && !['app-state-show'].include?(action)
              report_quota(output, args['--with-container-uuid'])
              quota_reported = true
            end

            if report_resource(output, args['--with-app-name'])
              exitcode = 222
            end
          end

          parallel_job[:result_exit_code]    = exitcode
          parallel_job[:result_stdout]       = output
          parallel_job[:result_addtl_params] = addtl_params
          args.delete('--with-hourglass')
        end

        Log.instance.info("execute_parallel_action call - duration: #{Time.now - start} - #{joblist}")
        reply[:output]   = joblist
        reply[:exitcode] = 0
      end

      #
      # Upgrade between versions
      #
      def upgrade_action
        Log.instance.info("upgrade_action call / action=#{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :app_uuid, /^[a-zA-Z0-9]+$/
        validate :version, /^.+$/
        validate :namespace, /^.+$/
        uuid = request[:uuid]
        application_uuid = request[:app_uuid]
        namespace = request[:namespace]
        version = request[:version]
        ignore_cartridge_version = request[:ignore_cartridge_version] == 'true' ? true : false
        scalable = request[:scalable]
        hostname = Facter.value(:hostname)

        error_message = nil
        exitcode = 0

        begin
          require 'openshift-origin-node/model/upgrade'
          upgrader = OpenShift::Runtime::Upgrader.new(uuid, application_uuid, namespace, version, hostname, ignore_cartridge_version, scalable,
                                                      OpenShift::Runtime::Utils::Hourglass.new(@hourglass_timeout))
        rescue Exception => e
          report_exception e
          exitcode = 1
          error_message = "Failed to instantiate the upgrader; this is typically due to the gear being corrupt or missing its UNIX account.\n"\
                          "Exception: #{e.message}\n#{e.backtrace.join("\n")}"
        else
          begin
            result = upgrader.execute
          rescue LoadError => e
            report_exception e
            exitcode = 127
            error_message = "Upgrade not supported: #{e.message}"
          rescue OpenShift::Runtime::Utils::ShellExecutionException => e
            report_exception e
            exitcode = 2
            error_message = "Gear failed to upgrade due to an unhandled shell execution: #{e.message}\n#{e.backtrace.join("\n")}\n"\
                            "Stdout: #{e.stdout}\nStderr: #{e.stderr}"
          rescue Exception => e
            report_exception e
            exitcode = 3
            error_message = "Gear failed to upgrade due to an unhandled internal exception: #{e.message}\n#{e.backtrace.join("\n")}"
          end
        end

        Log.instance.info("upgrade_action (#{exitcode})\n------\n#{error_message}\n------)")

        reply[:output] = error_message
        reply[:exitcode] = exitcode
        reply[:upgrade_result_json] = JSON.dump(result) if result
        reply.fail! "upgrade_action failed with exit code #{exitcode}. Output: #{error_message}" unless exitcode == 0
      end

      #
      # Builds a new ApplicationContainer instance from the standard
      # argument payload which is expected for any message used for
      # gear/cart operations.
      #
      # Use this to get a new ApplicationContainer instance in all cases.
      #
      # A new OpenShift::Runtime::Hourglass will be initialized and passed
      # to the ApplicationContainerInstance to allow for timing consistency.
      # The hourglass will be initialized with a duration shorter than the
      # configured MCollective agent timeout.
      #
      def get_app_container_from_args(args)
        app_uuid     = args['--with-app-uuid'].to_s       if args['--with-app-uuid']
        app_name     = args['--with-app-name'].to_s       if args['--with-app-name']
        gear_uuid    = args['--with-container-uuid'].to_s if args['--with-container-uuid']
        gear_name    = args['--with-container-name'].to_s if args['--with-container-name']
        namespace    = args['--with-namespace'].to_s      if args['--with-namespace']
        quota_blocks = args['--with-quota-blocks']
        quota_files  = args['--with-quota-files']
        uid          = args['--with-uid']
        hourglass    = args['--with-hourglass'] || OpenShift::Runtime::Utils::Hourglass.new(@hourglass_timeout)

        quota_blocks = nil if quota_blocks && quota_blocks.to_s.empty?
        quota_files  = nil if quota_files && quota_files.to_s.empty?
        uid          = nil if uid && uid.to_s.empty?

        OpenShift::Runtime::ApplicationContainer.new(app_uuid, gear_uuid, uid, app_name, gear_name,
                                                     namespace, quota_blocks, quota_files, hourglass)
      end

      # Yields an ApplicationContainer constructed from the given args. No exceptions will be raised
      # and the method will return a tuple of a return code integer and output string.
      def with_container_from_args(args)
        output = ''
        begin
          container = get_app_container_from_args(args)
          yield(container, output)
          return 0, output
        rescue OpenShift::Runtime::Utils::ShellExecutionException => e
          report_exception e
          output << "\n" unless output.empty?
          output << "#{e.message}" if e.message
          output << "\n#{e.stdout}" if e.stdout.is_a?(String)
          output << "\n#{e.stderr}" if e.stderr.is_a?(String)
          return e.rc, output
        rescue Exception => e
          report_exception e
          Log.instance.error e.message
          Log.instance.error e.backtrace.join("\n")
          return 1, e.message
        end
      end

      def oo_app_create(args)
        output = ''
        begin
          token = args.key?('--with-secret-token') ? args['--with-secret-token'].to_s : nil
          generate_app_key = args.key?('--with-generate-app-key') ? args['--with-generate-app-key'] : false
          create_initial_deployment_dir = args.key?('--with-initial-deployment-dir') ? args['--with-initial-deployment-dir'] : true

          container = get_app_container_from_args(args)
          output = container.create(token, generate_app_key, create_initial_deployment_dir)
        rescue OpenShift::Runtime::UserCreationException => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue OpenShift::Runtime::GearCreationException => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 146, e.message
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_app_destroy(args)
        skip_hooks = args['--skip-hooks'] ? args['--skip-hooks'] : false
        output     = ""
        begin
          container    = get_app_container_from_args(args)
          out, err, rc = container.destroy(skip_hooks)
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          output << out
          output << err
          return rc, output
        end
      end

      def oo_update_configuration(args)
        config  = args['--with-config']
        auto_deploy = config['auto_deploy']
        deployment_branch = config['deployment_branch']
        keep_deployments = config['keep_deployments']
        deployment_type = config['deployment_type']

        with_container_from_args(args) do |container|
          container.set_auto_deploy(auto_deploy)
          container.set_deployment_branch(deployment_branch)
          container.set_keep_deployments(keep_deployments)
          container.set_deployment_type(deployment_type)
        end
      end

      def oo_deploy(args)
        hot_deploy = args['--with-hot-deploy']
        force_clean_build = args['--with-force-clean-build']
        ref = args['--with-ref']
        artifact_url = args['--with-artifact-url']
        out = StringIO.new
        err = StringIO.new
        addtl_params = nil

        rc, output = with_container_from_args(args) do |container|
          container.deploy(hot_deploy: hot_deploy, force_clean_build: force_clean_build, ref: ref, artifact_url: artifact_url, out: out, err: err)
          addtl_params = {deployments: container.calculate_deployments}
        end

        return rc, output, addtl_params
      end

      def oo_activate(args)
        deployment_id  = args['--with-deployment-id']
        out = StringIO.new
        err = StringIO.new
        addtl_params = nil

        rc, output = with_container_from_args(args) do |container|
          container.activate(deployment_id: deployment_id, out: out, err: err)
          addtl_params = {deployments: container.calculate_deployments}
        end

        return rc, output, addtl_params
      end

      def oo_authorized_ssh_key_add(args)
        ssh_key  = args['--with-ssh-key']
        key_type = args['--with-ssh-key-type']
        comment  = args['--with-ssh-key-comment']

        with_container_from_args(args) do |container|
          container.add_ssh_keys([{:content => ssh_key, :type => key_type, :comment => comment}])
        end
      end

      def oo_authorized_ssh_key_batch_add(args)
        ssh_keys  = args['--with-ssh-keys']

        with_container_from_args(args) do |container|
          container.add_ssh_keys(ssh_keys)
        end
      end

      def oo_authorized_ssh_key_remove(args)
        ssh_key = args['--with-ssh-key']
        key_type = args['--with-ssh-key-type']
        comment = args['--with-ssh-comment']

        with_container_from_args(args) do |container|
          container.remove_ssh_key(ssh_key, key_type, comment)
        end
      end

      def oo_authorized_ssh_key_batch_remove(args)
        ssh_keys  = args['--with-ssh-keys']

        with_container_from_args(args) do |container|
          container.remove_ssh_keys(ssh_keys)
        end
      end

      def oo_authorized_ssh_keys_replace(args)
        ssh_keys  = args['--with-ssh-keys'] || []

        begin
          container = get_app_container_from_args(args)
          container.replace_ssh_keys(ssh_keys)
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, ""
        end
      end

      def oo_broker_auth_key_add(args)
        iv    = args['--with-iv']
        token = args['--with-token']

        with_container_from_args(args) do |container|
          container.add_broker_auth(iv, token)
        end
      end

      def oo_broker_auth_key_remove(args)
        with_container_from_args(args) do |container|
          container.remove_broker_auth
        end
      end

      def oo_env_var_add(args)
        key   = args['--with-key']
        value = args['--with-value']

        with_container_from_args(args) do |container|
          container.add_env_var(key, value)
        end
      end

      def oo_env_var_remove(args)
        key = args['--with-key']

        with_container_from_args(args) do |container|
          container.remove_env_var(key)
        end
      end

      def oo_user_var_add(args)
        variables = {}
        if args['--with-variables']
          JSON.parse(args['--with-variables']).each {|env| variables[env['name']] = env['value']}
        end
        gears = args['--with-gears'] ? args['--with-gears'].split(';') : []

        if variables.empty? and gears.empty?
          return -1, "In #{__method__} at least user environment variables or gears must be provided for #{args['--with-app-name']}"
        end

        cmd_rc, cmd_output = 0, ''

        wrapper_rc, wrapper_output = with_container_from_args(args) do |container|
          cmd_rc, cmd_output = container.user_var_add(variables, gears)
        end

        if wrapper_rc == 0
          return cmd_rc, cmd_output
        else
          return wrapper_rc, wrapper_output
        end
      end

      def oo_user_var_remove(args)
        unless args['--with-keys']
          return -1, "In #{__method__} no user environment variable names provided for #{args['--with-app-name']}"
        end

        keys  = args['--with-keys'].split(' ')
        gears = args['--with-gears'] ? args['--with-gears'].split(';') : []

        cmd_rc, cmd_output = 0, ''

        wrapper_rc, wrapper_output = with_container_from_args(args) do |container|
          cmd_rc, cmd_output = container.user_var_remove(keys, gears)
        end
        
        if wrapper_rc == 0
          return cmd_rc, cmd_output
        else
          return wrapper_rc, wrapper_output
        end
      end

      def oo_user_var_list(args)
        keys = args['--with-keys'] ? args['--with-keys'].split(' ') : []

        output = ''
        begin
          container = get_app_container_from_args(args)
          list      = container.user_var_list(keys)
          output    = 'CLIENT_RESULT: ' + list.to_json
        rescue Exception => e
          report_exception e
          Log.instance.info "#{e.message}\n#{e.backtrace}"
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_cartridge_list(args)
        list_descriptors = true if args['--with-descriptors']
        porcelain = true if args['--porcelain']

        output = ""
        begin
          output = OpenShift::Runtime::Node.get_cartridge_list(list_descriptors, porcelain, false)
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_app_state_show(args)
        with_container_from_args(args) do |container, output|
          output << "\nCLIENT_RESULT: #{container.state.value}\n"
        end
      end

      def oo_get_quota(args)
        uuid = args['--uuid'].to_s if args['--uuid']

        output = ''
        begin
          q      = OpenShift::Runtime::Node.get_quota(uuid)
          output = [
            q[:device],
            q[:blocks_used].to_s, q[:blocks_quota].to_s, q[:blocks_limit].to_s,
            q[:inodes_used].to_s, q[:inodes_quota].to_s, q[:inodes_limit].to_s
          ]
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_set_quota(args)
        uuid = args['--uuid'].to_s if args['--uuid']
        blocks = args['--blocks']
        inodes = args['--inodes']

        output = ""
        begin
          output = OpenShift::Runtime::Node.set_quota(uuid, blocks, inodes)
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_force_stop(args)
        with_container_from_args(args) do |container|
          container.force_stop
        end
      end


      #
      # Instantiate the front-end class from the given arguments and
      # follow proper exception handling pattern.
      #
      def with_frontend_rescue_pattern
        output = ""
        begin
          yield(output)
        rescue OpenShift::Runtime::FrontendHttpServerExecException => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return e.rc, e.message + e.stdout + e.stderr
        rescue OpenShift::Runtime::FrontendHttpServerException => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          report_exception e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 1, e.message
        else
          return 0, output
        end
      end

      def with_frontend_from_args(args)
        container_uuid = args['--with-container-uuid'].to_s if args['--with-container-uuid']

        with_frontend_rescue_pattern do |o|
          frontend = OpenShift::Runtime::FrontendHttpServer.new(OpenShift::Runtime::ApplicationContainer.from_uuid(container_uuid))
          yield(frontend, o)
        end
      end

      def with_frontend_returns_data(args)
        with_frontend_from_args(args) do |f, o|
          r = yield(f, o)
          o << "CLIENT_RESULT: " + r.to_json + "\n"
        end
      end

      #
      # A frontend must be created before any other manipulations are
      # performed on it.
      #
      def oo_frontend_create(args)
        with_frontend_from_args(args) do |f, o|
          f.create
        end
      end

      def oo_frontend_destroy(args)
        with_frontend_from_args(args) do |f, o|
          f.destroy
        end
      end

      def oo_frontend_update_name(args)
        new_container_name = args['--with-new-container-name']
        with_frontend_from_args(args) do |f, o|
          f.update_name(new_container_name)
        end
      end

      def oo_frontend_reconnect(args)
        only_proxy_carts = args['--only-proxy-carts']
        with_container_from_args(args) do |container|
          final_carts = []
          container.cartridge_model.each_cartridge do |cart|
            if cart.web_proxy?
              final_carts << cart
            else
              container.cartridge_model.connect_frontend(cart) unless only_proxy_carts
            end
          end

          final_carts.each do |cart|
            container.cartridge_model.connect_frontend(cart, true)
          end
        end
      end

      #
      # The path-target-option is an array of the path, target and
      # options.  Multiple arrays may be specified and they are in
      # the form of: [ path(String), target(String), options(Hash) ]
      # ex: [ "", "127.0.250.1:8080", { "websocket" => 1 } ], ...
      #
      def oo_frontend_connect(args)
        path_target_options = args['--with-path-target-options']
        with_frontend_from_args(args) do |f, o|
          f.connect(*path_target_options)
        end
      end

      #
      # The paths are an array of the paths to remove.
      # ex: [ "", "/health", ... ]
      def oo_frontend_disconnect(args)
        paths = args['--with-paths']
        with_frontend_from_args(args) do |f, o|
          f.disconnect(*paths)
        end
      end

      def oo_frontend_connections(args)
        with_frontend_returns_data(args) do |f, o|
          f.connections.to_json
        end
      end

      def oo_frontend_idle(args)
        with_frontend_from_args(args) do |f, o|
          f.idle
        end
      end

      def oo_frontend_unidle(args)
        with_frontend_from_args(args) do |f, o|
          f.unidle
        end
      end

      def oo_frontend_check_idle(args)
        with_frontend_returns_data(args) do |f, o|
          f.idle?
        end
      end

      def oo_frontend_sts(args)
        max_age = args['--with-max-age']
        with_frontend_from_args(args) do |f, o|
          f.sts(max_age)
        end
      end

      def oo_frontend_no_sts(args)
        with_frontend_from_args(args) do |f, o|
          f.no_sts
        end
      end

      def oo_frontend_get_sts(args)
        with_frontend_returns_data(args) do |f, o|
          f.get_sts
        end
      end

      def oo_add_alias(args)
        alias_name = args['--with-alias-name']
        with_frontend_from_args(args) do |f, o|
          f.add_alias(alias_name)
        end
      end

      def oo_remove_alias(args)
        alias_name = args['--with-alias-name']
        with_frontend_from_args(args) do |f, o|
          f.remove_alias(alias_name)
        end
      end

      def oo_add_aliases(args)
        alias_names = args['--with-aliases']
        with_frontend_from_args(args) do |f, o|
          alias_names.each do |alias_name|
            f.add_alias(alias_name)
          end
        end
      end

      def oo_remove_aliases(args)
        alias_names = args['--with-aliases']
        with_frontend_from_args(args) do |f, o|
          alias_names.each do |alias_name|
            f.remove_alias(alias_name)
          end
        end
      end

      def oo_aliases(args)
        with_frontend_returns_data(args) do |f, o|
          f.aliases(alias_name)
        end
      end

      def oo_ssl_cert_add(args)
        ssl_cert     = args['--with-ssl-cert']
        priv_key     = args['--with-priv-key']
        server_alias = args['--with-alias-name']
        passphrase   = args['--with-passphrase']

        with_frontend_from_args(args) do |f, o|
          f.add_ssl_cert(ssl_cert, priv_key, server_alias, passphrase)
        end
      end

      def oo_ssl_cert_remove(args)
        server_alias = args['--with-alias-name']
        with_frontend_from_args(args) do |f, o|
          f.remove_ssl_cert(server_alias)
        end
      end

      def oo_ssl_certs(args)
        with_frontend_returns_data(args) do |f, o|
          f.ssl_certs
        end
      end

      def oo_frontend_to_hash(args)
        with_frontend_returns_data(args) do |f, o|
          f.to_hash
        end
      end

      # The backup is just a JSON encoded string
      #
      # TODO: Determine if its necessary to base64 encode
      # the output to protect from interpretation.
      #
      def oo_frontend_backup(args)
        oo_frontend_to_hash(args)
      end

      # Does an implicit instantiation of the FrontendHttpServer class.
      def oo_frontend_restore(args)
        backup = args['--with-backup']

        with_frontend_rescue_pattern do |o|
          OpenShift::Runtime::FrontendHttpServer.json_create({'data' => JSON.parse(backup)})
        end
      end

      def oo_tidy(args)
        with_container_from_args(args) do |container|
          container.tidy
        end
      end

      def oo_expose_port(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.create_public_endpoints(cart_name)
        end
      end

      def oo_conceal_port(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.delete_public_endpoints(cart_name)
        end
      end

      def oo_connector_execute(args)
        cart_name        = args['--cart-name']
        pub_cart_name    = args['--publishing-cart-name']
        hook_name        = args['--hook-name']
        connection_type  = args['--connection-type']
        input_args       = args['--input-args']

        with_container_from_args(args) do |container, output|
          output << container.connector_execute(cart_name, pub_cart_name, connection_type, hook_name, input_args)
        end
      end

      def oo_configure(args)
        cart_name        = args['--cart-name']
        template_git_url = args['--with-template-git-url']
        manifest         = args['--with-cartridge-manifest']

        with_container_from_args(args) do |container, output|
          output << container.configure(cart_name, template_git_url, manifest)
        end
      end

      def oo_post_configure(args)
        cart_name        = args['--cart-name']
        template_git_url = args['--with-template-git-url']

        deployments = nil

        rc, output = with_container_from_args(args) do |container, output|
          output << container.post_configure(cart_name, template_git_url)

          if container.cartridge_model.get_cartridge(cart_name).deployable?
            ::OpenShift::Runtime::Utils::Cgroups.new(container.uuid).boost do
              deployments = {deployments: container.calculate_deployments}
            end
          end
        end

        return rc, output, deployments
      end

      def oo_deconfigure(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.deconfigure(cart_name)
        end
      end

      def oo_unsubscribe(args)
        cart_name     = args['--cart-name']
        pub_cart_name = args['--publishing-cart-name']

        with_container_from_args(args) do |container, output|
          output << container.unsubscribe(cart_name, pub_cart_name).to_s
        end
      end

      def oo_deploy_httpd_proxy(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container|
          container.deploy_httpd_proxy(cart_name)
        end
      end

      def oo_remove_httpd_proxy(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container|
          container.remove_httpd_proxy(cart_name)
        end
      end

      def oo_restart_httpd_proxy(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container|
          container.restart_httpd_proxy(cart_name)
        end
      end

      def oo_start(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.start(cart_name)
        end
      end

      def oo_stop(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.stop(cart_name)
        end
      end

      def oo_restart(args)
        cart_name = args['--cart-name']
        options = {}
        options[:all] = true if args['--all']
        options[:parallel_concurrency_ratio] = args['--parallel_concurrency_ratio'].to_f if args['--parallel_concurrency_ratio']

        with_container_from_args(args) do |container, output|
          container.restart(cart_name, options)
        end
      end

      def oo_reload(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.reload(cart_name)
        end
      end

      def oo_status(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container, output|
          output << container.status(cart_name)
        end
      end

      def oo_threaddump(args)
        cart_name = args['--cart-name']

        output = ""
        begin
          container = get_app_container_from_args(args)
          output    = container.threaddump(cart_name)
        rescue OpenShift::Runtime::Utils::ShellExecutionException => e
          report_exception e
          Log.instance.info "#{e.message}\n#{e.backtrace}\n#{e.stderr}"
          return e.rc, "CLIENT_ERROR: action 'threaddump' failed #{e.message} #{e.stderr}"
        rescue Exception => e
          report_exception e
          Log.instance.info "#{e.message}\n#{e.backtrace}"
          return 1, e.message
        else
          return 0, output
        end
      end

      def oo_update_cluster(args)
        with_container_from_args(args) do |container|
          container.update_cluster(args['--proxy-gears'], args['--web-gears'], args['--rollback'], args['--sync-new-gears'])
        end
      end

      def oo_update_proxy_status(args)
        with_container_from_args(args) do |container|
          container.update_proxy_status(action: args['--action'],
                                        gear_uuid: args['--gear_uuid'],
                                        cartridge: args['--cart-name'],
                                        persist: args['--persist'])
        end
      end

      #
      # Set the district for a node
      #
      def set_district_action
        Log.instance.info("set_district call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        validate :uuid, /^[a-zA-Z0-9]+$/
        uuid = request[:uuid].to_s if request[:uuid]
        active = request[:active]
        first_uid = request[:first_uid]
        max_uid = request[:max_uid]

        begin
          district_home = PathUtils.join(@@config.get('GEAR_BASE_DIR'), '.settings')
          PathUtils.flock('/var/lock/oo-district-info') do
            FileUtils.mkdir_p(district_home)

            File.open(PathUtils.join(district_home, 'district.info'), 'w') { |f|
              f.write("#Do not modify manually!\nuuid='#{uuid}'\nactive='#{active}'\nfirst_uid=#{first_uid}\nmax_uid=#{max_uid}")
            }
          end

          Facter.add(:district_uuid) do
            setcode { uuid }
          end
          Facter.add(:district_active) do
            setcode { active }
          end
          Facter.add(:district_first_uid) do
            setcode { first_uid }
          end
          Facter.add(:district_max_uid) do
            setcode { max_uid }
          end

          reply[:output]   = "created/updated district #{uuid} with active = #{active}, first_uid = #{first_uid}, max_uid = #{max_uid}"
          reply[:exitcode] = 0
        rescue Exception => e
          report_exception e
          reply[:output]   = e.message
          reply[:exitcode] = 255
          reply.fail! "set_district failed #{reply[:exitcode]}.  Output #{reply[:output]}"
        end

        Log.instance.info("set_district (#{reply[:exitcode]})\n------\n#{reply[:output]}\n------)")
      end

      #
      # Set the district uid_limits for a node
      #
      def set_district_uid_limits_action
        Log.instance.info("set_district_uid_limits call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        first_uid = request[:first_uid]
        max_uid = request[:max_uid]

        begin
          district_home = PathUtils.join(@@config.get('GEAR_BASE_DIR'), '.settings')
          PathUtils.flock('/var/lock/oo-district-info') do
            district_info = PathUtils.join(district_home, 'district.info')
            text = File.read(district_info)

            new_first_uid = "first_uid=#{first_uid}"
            result = text.gsub!(/first_uid=\d+/, new_first_uid)
            text << "#{new_first_uid}\n" if result.nil?

            new_max_uid = "max_uid=#{max_uid}"
            result = text.gsub!(/max_uid=\d+/, new_max_uid)
            text << "#{new_max_uid}\n" if result.nil?

            File.open(district_info, 'w') {|f| f.puts text}
          end

          Facter.add(:district_first_uid) do
            setcode { first_uid }
          end
          Facter.add(:district_max_uid) do
            setcode { max_uid }
          end

          reply[:output]   = "updated district uid limits with first_uid = #{first_uid}, max_uid = #{max_uid}"
          reply[:exitcode] = 0
        rescue Exception => e
          reply[:output]   = e.message
          reply[:exitcode] = 255
          reply.fail! "set_district_uid_limits failed #{reply[:exitcode]}.  Output #{reply[:output]}"
        end

        Log.instance.info("set_district_uid_limits (#{reply[:exitcode]})\n------\n#{reply[:output]}\n------)")
      end

      #
      # Returns whether a gear is on a server
      #
      def has_gear_action
        validate :uuid, /^[a-zA-Z0-9]+$/

        uuid             = request[:uuid].to_s
        reply[:output]   = File.exist? PathUtils.join(@@config.get('GEAR_BASE_DIR'), uuid)
        reply[:exitcode] = 0
      end

      #
      # Returns whether an embedded app is on a server
      #
      def has_embedded_app_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :embedded_type, /^.+$/
        uuid             = request[:uuid].to_s if request[:uuid]
        embedded_type    = request[:embedded_type]
        reply[:output]   = File.exist? PathUtils.join(@@config.get('GEAR_BASE_DIR'), uuid, embedded_type)
        reply[:exitcode] = 0
      end

      #
      # Returns the entire set of env variables for a given gear uuid
      #
      def get_gear_envs_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        uuid             = request[:uuid].to_s if request[:uuid]
        dir              = OpenShift::Runtime::ApplicationContainer.from_uuid(uuid).container_dir
        env_hash         = OpenShift::Runtime::Utils::Environ.for_gear(dir)
        reply[:output]   = env_hash
        reply[:exitcode] = 0
      end

      #
      # Returns the public endpoints of all cartridges on the gear
      #
      def get_all_gears_endpoints_action
        gear_map = {}

        openshift_users.each do |gear_uuid, _|
          cont      = OpenShift::Runtime::ApplicationContainer.from_uuid(gear_uuid)
          env       = OpenShift::Runtime::Utils::Environ::for_gear(cont.container_dir)
          endpoints = []
          cont.cartridge_model.each_cartridge do |cart|
            cart.public_endpoints.each do |ep|
              endpoint_create_hash = {"cartridge_name"   => cart.name+'-'+cart.version,
                                      "external_port"    => env[ep.public_port_name],
                                      "internal_address" => env[ep.private_ip_name],
                                      "internal_port"    => ep.private_port,
                                      "protocols"        => ep.protocols,
                                      "type"             => []
              }

              if cart.web_proxy?
                endpoint_create_hash['protocols'] = cont.cartridge_model.primary_cartridge.public_endpoints.first.protocols
                endpoint_create_hash['type']      = ["load_balancer"]
              elsif cart.web_framework?
                endpoint_create_hash['type'] = ["web_framework"]
              elsif cart.categories.include? "database"
                endpoint_create_hash['type'] = ["database"]
              elsif cart.categories.include? "plugin"
                endpoint_create_hash['type'] = ["plugin"]
              else
                endpoint_create_hash['type'] = ["other"]
              end
              endpoint_create_hash['mappings'] = ep.mappings.map { |m| {"frontend" => m.frontend, "backend" => m.backend} } if ep.mappings
              endpoints << endpoint_create_hash
            end
          end
          gear_map[gear_uuid] = endpoints.dup if endpoints.length > 0
        end

        reply[:output]   = gear_map
        reply[:exitcode] = 0
      end

      #
      # Returns whether a uid or gid is already reserved on the system
      #
      def has_uid_or_gid_action
        uid  = request[:uid]

        begin
          Etc.getpwuid(uid)
          Etc.getgrgid(uid)
          reply[:output] = true
        rescue TypeError, ArgumentError
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end

      #
      # Returns whether the cartridge is present on a gear
      #
      def has_app_cartridge_action
        validate :app_uuid, /^[a-zA-Z0-9]+$/
        validate :gear_uuid, /^[a-zA-Z0-9]+$/
        validate :cartridge, /\A[a-zA-Z0-9\.\-\/_]+\z/

        gear_uuid = request[:gear_uuid].to_s if request[:gear_uuid]
        cart_name = request[:cartridge]

        begin
          container        = OpenShift::Runtime::ApplicationContainer.from_uuid(gear_uuid)
          cartridge        = container.get_cartridge(cart_name)
          reply[:output]   = (not cartridge.nil?)
          reply[:exitcode] = 0
        rescue RuntimeError => e
          Log.instance.error e.message
          reply[:output]   = false
          reply[:exitcode] = 0
        rescue Exception => e
          report_exception e
          Log.instance.error e.message
          Log.instance.error e.backtrace.join("\n")
          reply[:output]   = false
          reply[:exitcode] = 1
        end
        reply
      end

      #
      # Get all gears
      #
      def get_all_gears_action
        gear_map = {}

        openshift_users.each do |gear_uuid, gear_uid|
          if request[:with_broker_key_auth]
            next unless File.exists?(PathUtils.join(@@config.get('GEAR_BASE_DIR'), gear_uuid, '.auth', 'token'))
          end

          gear_map[gear_uuid] = gear_uid
        end

        reply[:output]   = gear_map
        reply[:exitcode] = 0
      end

      #
      # Get all sshkeys for all gears
      #
      def get_all_gears_sshkeys_action
        gear_map = {}

        openshift_users.each do |gear_uuid, _|
          gear_map[gear_uuid]  = []
          authorized_keys_file = PathUtils.join(@@config.get('GEAR_BASE_DIR'), gear_uuid, ".ssh", "authorized_keys")
          if File.exists?(authorized_keys_file) and not File.directory?(authorized_keys_file)
            File.open(authorized_keys_file, File::RDONLY) do |key_file|
              key_file.each_line do |line|
                begin
                  gear_map[gear_uuid] << "#{line.split[-1].chomp}::#{Digest::MD5.hexdigest(line.split[-2].chomp)}"
                rescue
                end
              end
            end
          end
        end
        reply[:output]   = gear_map
        reply[:exitcode] = 0
      end

      #
      # Get all gears
      #
      def get_all_active_gears_action
        active_gears = {}

        openshift_users.each do |gear_uuid, _|
          state_file = PathUtils.join(@@config.get('GEAR_BASE_DIR'), gear_uuid, 'app-root', 'runtime', '.state')
          if File.exist?(state_file)
            state                   = File.read(state_file).chomp
            active                  = !('idle' == state || 'stopped' == state)
            active_gears[gear_uuid] = nil if active
          end
        end
        reply[:output]   = active_gears
        reply[:exitcode] = 0
      end

      # find all unix users with the gear GECOS
      def openshift_users
        uuid_map = {}

        IO.readlines('/etc/passwd').each { |line|
          account, _, uid, _, gecos, _, _ = line.split(':')
          next unless gecos == @@config.get('GEAR_GECOS')
          uuid_map[account] = uid
        }
        uuid_map
      end

      ## Perform operation on CartridgeRepository
      def cartridge_repository_action
        Log.instance.info("action: #{request.action}_action, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        action            = request[:action]
        path              = request[:path]
        name              = request[:name]
        version           = request[:version]
        cartridge_version = request[:cartridge_version]

        reply[:output] = "#{action} succeeded for #{path}"
        begin
          case action
            when 'install'
              ::OpenShift::Runtime::CartridgeRepository.instance.install(path)
            when 'erase'
              ::OpenShift::Runtime::CartridgeRepository.instance.erase(name, version, cartridge_version)
            when 'list'
              reply[:output] = ::OpenShift::Runtime::CartridgeRepository.instance.to_s
            else
              reply.fail(
                  "#{action} is not implemented. openshift.ddl may be out of date.",
                  2)
              return
          end
        rescue Exception => e
          report_exception e
          Log.instance.info("cartridge_repository_action(#{action}): failed #{e.message}\n#{e.backtrace}")
          reply.fail!("#{action} failed for #{path} #{e.message}", 4)
        end
      end

      protected
        # No-op by default
        def report_exception(e)
        end
    end
  end
end
