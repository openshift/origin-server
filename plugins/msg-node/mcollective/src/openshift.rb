require 'rubygems'
require 'open4'
require 'pp'
require 'json'
require 'zlib'
require 'base64'
require 'openshift-origin-node'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/utils/hourglass'
require 'shellwords'
require 'facter'
require 'openshift-origin-common/utils/file_needs_sync'

module MCollective
  module Agent
    class Openshift<RPC::Agent
      metadata :name        => "OpenShift Agent",
               :description => "Agent to manage OpenShift services",
               :author      => "Mike McGrath",
               :license     => "ASL 2.0",
               :version     => "0.1",
               :url         => "http://www.openshift.com",
               :timeout     => 360

      activate_when do
        @cartridge_repository = ::OpenShift::CartridgeRepository.instance
        @cartridge_repository.load
        Log.instance.info(
            "#{@cartridge_repository.count} cartridge(s) installed in #{@cartridge_repository.path}")
        true
      end

      def before_processing_hook(msg, connection)
        # Set working directory to a 'safe' directory to prevent Dir.chdir
        # calls with block from changing back to a directory which doesn't exist.
        Log.instance.debug("Changing working directory to /tmp")
        Dir.chdir('/tmp')
      end

      def echo_action
        validate :msg, String
        reply[:msg] = request[:msg]
      end

      def cleanpwd(arg)
        arg.gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]').gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]')
      end

      # Handles all incoming messages. Validates the input, executes the action, and constructs
      # a reply.
      def cartridge_do_action
        Log.instance.info("cartridge_do_action call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")
        Log.instance.info("cartridge_do_action validation = #{request[:cartridge]} #{request[:action]} #{request[:args]}")
        validate :cartridge, /\A[a-zA-Z0-9\.\-\/_]+\z/
        validate :cartridge, :shellsafe
        valid_actions = %w(
          app-create
          app-destroy
          env-var-add
          env-var-remove
          broker-auth-key-add
          broker-auth-key-remove
          authorized-ssh-key-add
          authorized-ssh-key-remove
          ssl-cert-add
          ssl-cert-remove
          configure
          post-configure
          deconfigure
          unsubscribe
          tidy
          deploy-httpd-proxy
          remove-httpd-proxy
          restart-httpd-proxy
          info
          post-install
          post-remove
          pre-install
          reload
          restart
          start
          status
          stop
          force-stop
          add-alias
          remove-alias
          threaddump
          cartridge-list
          expose-port
          frontend-backup
          frontend-restore
          frontend-create
          frontend-destroy
          frontend-update-name
          frontend-connect
          frontend-disconnect
          frontend-connections
          frontend-idle
          frontend-unidle
          frontend-check-idle
          frontend-sts
          frontend-no-sts
          frontend-get-sts
          aliases
          ssl-cert-add
          ssl-cert-remove
          ssl-certs
          frontend-to-hash
          system-messages
          connector-execute
          get-quota
          set-quota
        )
        validate :action, /\A#{valid_actions.join("|")}\Z/
        validate :action, :shellsafe
        cartridge                  = request[:cartridge]
        action                     = request[:action]
        args                       = request[:args] ||= {}
        pid, stdin, stdout, stderr = nil, nil, nil, nil
        rc                         = nil
        output                     = ""

        # Do the action execution
        exitcode, output           = execute_action(action, args)

        reply[:exitcode] = exitcode
        reply[:output]   = output

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
        action_method = "oo_#{action.gsub('-', '_')}"
        request_id    = args['--with-request-id'].to_s if args['--with-request-id']

        exitcode = 0
        output   = ""

        if not self.respond_to?(action_method)
          exitcode = 127
          output   = "Unsupported action: #{action}/#{action_method}"
        else
          Log.instance.info("Executing action [#{action}] using method #{action_method} with args [#{args}]")
          begin
            OpenShift::NodeLogger.context[:request_id]    = request_id if request_id
            OpenShift::NodeLogger.context[:action_method] = action_method if action_method

            exitcode, output = self.send(action_method.to_sym, args)
          rescue => e
            Log.instance.error("Unhandled action execution exception for action [#{action}]: #{e.message}")
            Log.instance.error(e.backtrace)
            exitcode = 127
            output   = "An internal exception occured processing action #{action}: #{e.message}"
          ensure
            OpenShift::NodeLogger.context.delete(:request_id)
            OpenShift::NodeLogger.context.delete(:action_method)
          end
          Log.instance.info("Finished executing action [#{action}] (#{exitcode})")
        end

        return exitcode, output
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
        Log.instance.info("execute_parallel_action call / action: #{request.action}, agent=#{request.agent}, data=#{request.data.pretty_inspect}")

        joblist = request[config.identity]

        joblist.each do |parallel_job|
            job = parallel_job[:job]

            cartridge = job[:cartridge]
            action    = job[:action]
            args      = job[:args]

            exitcode, output = execute_action(action, args)

            parallel_job[:result_exit_code] = exitcode
            parallel_job[:result_stdout]    = output
        end

        Log.instance.info("execute_parallel_action call - #{joblist}")
        reply[:output]   = joblist
        reply[:exitcode] = 0
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
        app_uuid = args['--with-app-uuid'].to_s if args['--with-app-uuid']
        app_name = args['--with-app-name'].to_s if args['--with-app-name']
        gear_uuid = args['--with-container-uuid'].to_s if args['--with-container-uuid']
        gear_name = args['--with-container-name'].to_s if args['--with-container-name']
        namespace = args['--with-namespace'].to_s if args['--with-namespace']
        quota_blocks = args['--with-quota-blocks']
        quota_files  = args['--with-quota-files']
        uid          = args['--with-uid']

        quota_blocks = nil if quota_blocks && quota_blocks.to_s.empty?
        quota_files = nil if quota_files && quota_files.to_s.empty?
        uid = nil if uid && uid.to_s.empty?

        OpenShift::ApplicationContainer.new(app_uuid, gear_uuid, uid, app_name, gear_name,
                                            namespace, quota_blocks, quota_files, OpenShift::Utils::Hourglass.new(235))
      end

      def with_container_from_args(args)
        output = ''
        begin
          container = get_app_container_from_args(args)
          yield(container, output)
          return 0, output
        rescue OpenShift::Utils::ShellExecutionException => e
          return e.rc, "#{e.message}\n#{e.stdout}\n#{e.stderr}"
        rescue Exception => e
          Log.instance.error e.message
          Log.instance.error e.backtrace.join("\n")
          return -1, e.message
        end
      end

      def oo_app_create(args)
        output = ""
        begin
          container = get_app_container_from_args(args)
          container.create
        rescue OpenShift::UserCreationException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
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
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          output << out
          output << err
          return rc, output
        end
      end

      def oo_authorized_ssh_key_add(args)
        ssh_key  = args['--with-ssh-key']
        key_type = args['--with-ssh-key-type']
        comment  = args['--with-ssh-key-comment']

        with_container_from_args(args) do |container|
          container.user.add_ssh_key(ssh_key, key_type, comment)
        end
      end

      def oo_authorized_ssh_key_remove(args)
        ssh_key = args['--with-ssh-key']
        comment = args['--with-ssh-comment']

        with_container_from_args(args) do |container|
          container.user.remove_ssh_key(ssh_key, comment)
        end
      end

      def oo_authorized_ssh_keys_replace(args)
        ssh_keys  = args['--with-ssh-keys'] || []

        begin
          container = get_app_container_from_args(args)
          container.user.replace_ssh_keys(ssh_keys)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, ""
        end
      end

      def oo_broker_auth_key_add(args)
        iv    = args['--with-iv']
        token = args['--with-token']

        with_container_from_args(args) do |container|
          container.user.add_broker_auth(iv, token)
        end
      end

      def oo_broker_auth_key_remove(args)
        with_container_from_args(args) do |container|
          container.user.remove_broker_auth
        end
      end

      def oo_env_var_add(args)
        key   = args['--with-key']
        value = args['--with-value']

        with_container_from_args(args) do |container|
          container.user.add_env_var(key, value)
        end
      end

      def oo_env_var_remove(args)
        key = args['--with-key']

        with_container_from_args(args) do |container|
          container.user.remove_env_var(key)
        end
      end

      def oo_cartridge_list(args)
        list_descriptors = true if args['--with-descriptors']
        porcelain = true if args['--porcelain']

        output = ""
        begin
          output = OpenShift::Node.get_cartridge_list(list_descriptors, porcelain, false)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_app_state_show(args)
        container_uuid = args['--with-container-uuid'].to_s if args['--with-container-uuid']
        app_uuid = args['--with-app-uuid'].to_s if args['--with-app-uuid']

        with_container_from_args(args) do |container, output|
          output << container.state.value
        end
      end

      def oo_get_quota(args)
        uuid = args['--uuid'].to_s if args['--uuid']

        output = ""
        begin
          output = OpenShift::Node.get_quota(uuid)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
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
          output = OpenShift::Node.set_quota(uuid, blocks, inodes)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_force_stop(args)
        container_uuid = args['--with-container-uuid'].to_s if args['--with-container-uuid']
        app_uuid = args['--with-app-uuid'].to_s if args['--with-app-uuid']

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
        rescue OpenShift::FrontendHttpServerExecException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return e.rc, e.message + e.stdout + e.stderr
        rescue OpenShift::FrontendHttpServerException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def with_frontend_from_args(args)
        container_uuid = args['--with-container-uuid'].to_s if args['--with-container-uuid']
        container_name = args['--with-container-name'].to_s if args['--with-container-name']
        namespace = args['--with-namespace'].to_s if args['--with-namespace']

        with_frontend_rescue_pattern do |o|
          frontend = OpenShift::FrontendHttpServer.new(container_uuid, container_name, namespace)
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
        with_frontend_returns_data do |f, o|
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
          OpenShift::FrontendHttpServer.json_create({'data' => JSON.parse(backup)})
        end
      end

      def oo_tidy(args)
        with_container_from_args(args) do |container|
          container.tidy
        end
      end

      def oo_expose_port(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container|
          container.create_public_endpoints(cart_name)
        end
      end

      def oo_conceal_port(args)
        cart_name = args['--cart-name']

        with_container_from_args(args) do |container|
          container.delete_public_endpoints(cart_name)
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
        cart_name = args['--cart-name']
        template_git_url = args['--with-template-git-url']

        with_container_from_args(args) do |container, output|
          output << container.post_configure(cart_name, template_git_url)
        end
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

      def oo_system_messages(args)
        cart_name = args['--cart-name']

        output = ""
        begin
          output = OpenShift::Node.find_system_messages(cart_name)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
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

        with_container_from_args(args) do |container, output|
          output << container.restart(cart_name)
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
        rescue OpenShift::Utils::ShellExecutionException => e
          Log.instance.info "#{e.message}\n#{e.backtrace}\n#{e.stderr}"
          return e.rc, "CLIENT_ERROR: action 'threaddump' failed #{e.message} #{e.stderr}"
        rescue Exception => e
          Log.instance.info "#{e.message}\n#{e.backtrace}"
          return -1, e.message
        else
          return 0, output
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

        begin
          district_home = '/var/lib/openshift/.settings'
          FileUtils.mkdir_p(district_home)

          File.open(File.join(district_home, 'district.info'), 'w') { |f|
            f.write("#Do not modify manually!\nuuid='#{uuid}'\nactive='#{active}'\n")
          }

          Facter.add(:district_uuid) do
            setcode { uuid }
          end
          Facter.add(:district_active) do
            setcode { active }
          end

          reply[:output]   = "created/updated district #{uuid} with active = #{active}"
          reply[:exitcode] = 0
        rescue Exception => e
          reply[:output]   = e.message
          reply[:exitcode] = 255
          reply.fail! "set_district failed #{reply[:exitcode]}.  Output #{reply[:output]}"
        end

        Log.instance.info("set_district (#{reply[:exitcode]})\n------\n#{reply[:output]}\n------)")
      end

      #
      # Returns whether an app is on a server
      #
      def has_app_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :application, /^[a-zA-Z0-9]+$/
        uuid = request[:uuid].to_s if request[:uuid]
        app_name = request[:application]
        if File.exist?("/var/lib/openshift/#{uuid}/#{app_name}")
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end

      #
      # Returns whether an embedded app is on a server
      #
      def has_embedded_app_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :embedded_type, /^.+$/
        uuid = request[:uuid].to_s if request[:uuid]
        embedded_type = request[:embedded_type]
        if File.exist?("/var/lib/openshift/#{uuid}/#{embedded_type}")
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end

      #
      # Returns whether a uid or gid is already reserved on the system
      #
      def has_uid_or_gid_action
        validate :uid, /^[0-9]+$/
        uid  = request[:uid].to_i

        # FIXME: Etc.getpwuid() and Etc.getgrgid() would be much faster
        uids = IO.readlines("/etc/passwd").map { |line| line.split(":")[2].to_i }
        gids = IO.readlines("/etc/group").map { |line| line.split(":")[2].to_i }

        if uids.include?(uid) || gids.include?(uid)
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end

      #
      # Get all gears
      #
      def get_all_gears_action
        gear_map = {}

        uid_map          = {}
        uids             = IO.readlines("/etc/passwd").map { |line|
          uid               = line.split(":")[2]
          username          = line.split(":")[0]
          uid_map[username] = uid
        }
        dir              = "/var/lib/openshift/"
        filelist         = Dir.foreach(dir) { |file|
          if File.directory?(dir+file) and not File.symlink?(dir+file) and not file[0]=='.'
            if uid_map.has_key?(file)
              if request[:with_broker_key_auth]
                next unless File.exists?(File.join(dir, file, ".auth/token"))
              end

              gear_map[file] = uid_map[file]
            end
          end
        }
        reply[:output]   = gear_map
        reply[:exitcode] = 0
      end

      #
      # Get all sshkeys for all gears
      #
      def get_all_gears_sshkeys_action
        gear_map = {}

        dir              = "/var/lib/openshift/"
        filelist         = Dir.foreach(dir) do |gear_file|
          if File.directory?(dir + gear_file) and not File.symlink?(dir + gear_file) and not gear_file[0] == '.'
            gear_map[gear_file] = {}
            authorized_keys_file = File.join(dir, gear_file, ".ssh", "authorized_keys")
            if File.exists?(authorized_keys_file) and not File.directory?(authorized_keys_file)
              File.open(authorized_keys_file, File::RDONLY) do |key_file|
                key_file.each_line do |line|
                  begin
                    gear_map[gear_file][Digest::MD5.hexdigest(line.split[-2].chomp)] = line.split[-1].chomp
                  rescue
                  end
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
        active_gears     = {}
        dir              = "/var/lib/openshift/"
        filelist         = Dir.foreach(dir) { |file|
          if File.directory?(dir+file) and not File.symlink?(dir+file) and not file[0]=='.'
            state_file = File.join(dir, file, 'app-root', 'runtime', '.state')
            if File.exist?(state_file)
              state  = File.read(state_file).chomp
              active = !('idle' == state || 'stopped' == state)
              active_gears[file] = nil if active
            end
          end
        }
        reply[:output]   = active_gears
        reply[:exitcode] = 0
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
              ::OpenShift::CartridgeRepository.instance.install(path)
            when 'erase'
              ::OpenShift::CartridgeRepository.instance.erase(name, version, cartridge_version)
            when 'list'
              reply[:output] = ::OpenShift::CartridgeRepository.instance.to_s
            else
              reply.fail(
                  "#{action} is not implemented. openshift.ddl may be out of date.",
                  2)
              return
          end
        rescue Exception => e
          Log.instance.info("cartridge_repository_action(#{action}): failed #{e.message}\n#{e.backtrace}")
          reply.fail!("#{action} failed for #{path} #{e.message}", 4)
        end
      end
    end
  end
end
