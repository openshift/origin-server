require 'openshift-origin-node/utils/threads'
require 'json'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'

module OpenShift
  module Runtime
    module ApplicationContainerExt
      module CartridgeActions
        PARALLEL_CONCURRENCY_RATIO = 0.2
        MAX_THREADS = 8
        RESULT_SUCCESS = 'success'
        RESULT_FAILURE = 'failure'

        # Add cartridge to gear.  This method establishes the cartridge model
        # to use, but does not mark the application.  Marking the application
        # is the responsibility of the cart model.
        #
        # This method does not enforce constraints on whether the cartridge
        # being added is compatible with other installed cartridges.  That
        # is the responsibility of the broker.
        #
        # context: root -> gear user -> root
        # @param [OpenShift::Runtime::Ident] ident cartridge identifier
        # @param template_git_url  URL for template application source/bare repository
        # @param manifest          Broker provided manifest
        # @param do_expose_ports   Flag to suggest whether cartridge's public endpoints should be exposed out or not
        def configure(ident, template_git_url=nil,  manifest=nil, do_expose_ports=false)
          o = (@cartridge_model.configure(ident, template_git_url, manifest) || '')
          if do_expose_ports
            o += (create_public_endpoints(ident.to_name) || "")
          end
          o
        end

        def post_configure(cart_name, template_git_url=nil)
          output         = ''
          cartridge      = @cartridge_model.get_cartridge(cart_name)

          # Only perform an initial build if the manifest explicitly specifies a need,
          # or if a template Git URL is provided and the cart is capable of builds or deploys.
          perform_initial_build = !OpenShift::Git.empty_clone_spec?(template_git_url) && (cartridge.install_build_required || template_git_url) && cartridge.buildable?
          if perform_initial_build
            build_log = '/tmp/initial-build.log'
            env       = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

            begin
              ::OpenShift::Runtime::Utils::Cgroups.new(@uuid).boost do
                logger.info "Executing initial gear prereceive for #{@uuid}"
                Utils.oo_spawn("gear prereceive --init >> #{build_log} 2>&1",
                               env:                 env,
                               chdir:               @container_dir,
                               uid:                 @uid,
                               timeout:             @hourglass.remaining,
                               expected_exitstatus: 0)

                logger.info "Executing initial gear postreceive for #{@uuid}"
                Utils.oo_spawn("gear postreceive --init >> #{build_log} 2>&1",
                               env:                 env,
                               chdir:               @container_dir,
                               uid:                 @uid,
                               timeout:             @hourglass.remaining,
                               expected_exitstatus: 0)

              end
            rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
              max_bytes = 10 * 1024
              out, _, _ = Utils.oo_spawn("tail -c #{max_bytes} #{build_log} 2>&1",
                                         env:     env,
                                         chdir:   @container_dir,
                                         uid:     @uid,
                                         timeout: @hourglass.remaining)

              message = "The initial build for the application failed: #{e.message}\n\n.Last #{max_bytes/1024} kB of build output:\n#{out}"

              raise ::OpenShift::Runtime::Utils::Sdk.translate_out_for_client(message, :error)
            end
          elsif cartridge.deployable?
            setup_deployment(latest_deployment_datetime)
          end

          output << @cartridge_model.post_configure(cart_name)

          if perform_initial_build
            pattern   = Utils::Sdk::CLIENT_OUTPUT_PREFIXES.join('|')
            out, _, _ = Utils.oo_spawn("grep -E '#{pattern}' #{build_log} | head -c 10K",
                                      env:                 env,
                                      chdir:               @container_dir,
                                      uid:                 @uid,
                                      timeout:             @hourglass.remaining)
            output << out
          end

          output
        end

        def setup_deployment(deployment_datetime)
          deployment_metadata = deployment_metadata_for(deployment_datetime)
          # only do this if we've never activated
          if deployment_metadata.activations.empty?
            prepare(deployment_datetime: deployment_datetime)

            # prepare modifies the deployment metadata - need to reload
            deployment_metadata.load

            application_repository = ApplicationRepository.new(self)
            git_ref = 'master'
            git_sha1 = application_repository.get_sha1(git_ref)
            deployment_metadata.git_sha1 = git_sha1
            deployment_metadata.git_ref = git_ref

            deployments_dir = PathUtils.join(@container_dir, 'app-deployments')
            set_rw_permission_R(deployments_dir)
            reset_permission_R(deployments_dir)

            deployment_metadata.record_activation
            deployment_metadata.save

            update_current_deployment_datetime_symlink(deployment_datetime)
          end
        end

        # Remove cartridge from gear
        #
        # context: root -> gear user -> root
        # @param [OpenShift::Runtime::Ident] ident   cartridge identifier
        def deconfigure(ident)
          @cartridge_model.deconfigure(ident)
        end

        # Unsubscribe from a cart
        #
        # @param cart_name   unsubscribing cartridge name
        # @param cart_name   publishing cartridge name
        def unsubscribe(cart_name, pub_cart_name)
          @cartridge_model.unsubscribe(cart_name, pub_cart_name)
        end

        def generate_endpoint_creation_notification_msg(cart, endpoint, private_ip_value, public_port_value)
          config = ::OpenShift::Config.new
          endpoint_create_hash = { "cartridge_name" => "#{cart.name}-#{cart.version}",
                                   "external_address" => config.get('PUBLIC_IP'),
                                   "external_port" => public_port_value,
                                   "internal_address" => private_ip_value,
                                   "internal_port" => endpoint.private_port,
                                   "protocols" => endpoint.protocols,
                                   "description" => endpoint.description,
                                   "type" => []
          }

          if cart.web_proxy?
            endpoint_create_hash['protocols'] = @cartridge_model.primary_cartridge.public_endpoints.first.protocols
            endpoint_create_hash['type'] = ["load_balancer"]
          elsif cart.web_framework?
            endpoint_create_hash['type'] = ["web_framework"]
          elsif cart.categories.include? "database"
            endpoint_create_hash['type'] = ["database"]
          elsif cart.categories.include? "plugin"
            endpoint_create_hash['type'] = ["plugin"]
          else
            endpoint_create_hash['type'] = ["other"]
          end
          endpoint_create_hash['mappings'] = endpoint.mappings.map { |m| { "frontend" => m.frontend, "backend" => m.backend } } if endpoint.mappings
          "NOTIFY_ENDPOINT_CREATE: #{endpoint_create_hash.to_json}\n"
        end

        # Creates public endpoints for the given cart. Public proxy mappings are created via
        # the FrontendProxyServer, and the resulting mapped ports are written to environment
        # variables with names based on the cart manifest endpoint entries.
        #
        # Returns nil on success, or raises an exception if any errors occur: all errors here
        # are considered fatal.
        def create_public_endpoints(cart_name)
          output = ''
          cart   = @cartridge_model.get_cartridge(cart_name)

          env = ::OpenShift::Runtime::Utils::Environ::for_gear(@container_dir)
          # TODO: better error handling
          cart.public_endpoints.each do |endpoint|
            # Load the private IP from the gear
            private_ip = env[endpoint.private_ip_name]

            if private_ip == nil
              raise "Missing private IP #{endpoint.private_ip_name} for cart #{cart.name} in gear #{@uuid}, "\
            "required to create public endpoint #{endpoint.public_port_name}"
            end

            public_port = create_public_endpoint(private_ip, endpoint.private_port)
            add_env_var(endpoint.public_port_name, public_port)

            output << generate_endpoint_creation_notification_msg(cart, endpoint, private_ip, public_port)

            logger.info("Created public endpoint for cart #{cart.name} in gear #{@uuid}: "\
          "[#{endpoint.public_port_name}=#{public_port}]")
          end

          output
        end

        def create_public_endpoint(private_ip, private_port)
          @container_plugin.create_public_endpoint(private_ip, private_port)
        end

        # Deletes all public endpoints for the given cart. Public port mappings are
        # looked up and deleted using the FrontendProxyServer, and all corresponding
        # environment variables are deleted from the gear.
        #
        # Returns nil on success. Failed public port delete operations are logged
        # and skipped.
        def delete_public_endpoints(cart_name)
          cart = @cartridge_model.get_cartridge(cart_name)
          proxy_mappings = @cartridge_model.list_proxy_mappings

          output = ''

          begin
            # Remove the proxy entries
            @container_plugin.delete_public_endpoints(proxy_mappings)

            config = ::OpenShift::Config.new
            proxy_mappings.each { |p|
              output << "NOTIFY_ENDPOINT_DELETE: #{config.get('PUBLIC_IP')} #{p[:proxy_port]}\n" if p[:proxy_port]
            }

            logger.info("Deleted all public endpoints for cart #{cart.name} in gear #{@uuid}\n"\
              "Endpoints: #{proxy_mappings.map{|p| p[:public_port_name]}}\n"\
              "Public ports: #{proxy_mappings.map{|p| p[:proxy_port]}}")
          rescue => e
            logger.warn(%Q{Couldn't delete all public endpoints for cart #{cart.name} in gear #{@uuid}: #{e.message}
              "Endpoints: #{proxy_mappings.map{|p| p[:public_port_name]}}\n"\
              "Public ports: #{proxy_mappings.map{|p| p[:proxy_port]}}\n"\
              #{e.backtrace}
            })
          end

          # Clean up the environment variables
          proxy_mappings.map{|p| remove_env_var(p[:public_port_name])}

          output
        end

        # Delete a particular public endpoint
        def delete_public_endpoint(public_port_name, public_port_value)
          @container_plugin.delete_public_endpoint(public_port_value)
          remove_env_var(public_port_name)
        end

        def connector_execute(cart_name, pub_cart_name, connector_type, connector, args)
          @cartridge_model.connector_execute(cart_name, pub_cart_name, connector_type, connector, args)
        end

        def deploy_httpd_proxy(cart_name)
          @cartridge_model.deploy_httpd_proxy(cart_name)
        end

        def remove_httpd_proxy(cart_name)
          @cartridge_model.remove_httpd_proxy(cart_name)
        end

        def restart_httpd_proxy(cart_name)
          @cartridge_model.restart_httpd_proxy(cart_name)
        end

        #
        # Deploys a binary artifact
        #
        # options: hash
        #   :hot_deploy    : indicates whether to hot deploy
        #   :artifact_url  : the artifact to download and deploy
        #   :stdin         : deploy content streamed to STDIN
        #   :file          : deploy the specified file
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #   :all           : indicates whether to deploy to all gears or just the local one
        #
        def deploy_binary_artifact(options)
          result = { status: RESULT_FAILURE }

          message = "Starting deploy for binary artifact"
          options[:out].puts message if options[:out]

          message = "Stopping gear"
          options[:out].puts message if options[:out]

          stop_gear(user_initiated: true,
                    hot_deploy: options[:hot_deploy],
                    exclude_web_proxy: true,
                    out: options[:out],
                    err: options[:in])

          message ="Creating new deployment directory"
          options[:out].puts message if options[:out]

          deployment_datetime = create_deployment_dir
          options[:deployment_datetime] = deployment_datetime

          configure_deployment_metadata(deployment_datetime,options)

          message = "Preparing deployment"
          options[:out].puts message if options[:out]

          prepare(options)

          message = "Distributing deployment"
          options[:out].puts message if options[:out]

          distribute_result = distribute(options)
          result[:distribute_result] = distribute_result
          distribute_status = distribute_result[:status]

          message = "Distribution status: #{distribute_status}"
          options[:out].puts message if options[:out]

          if distribute_status != RESULT_SUCCESS
            message = "Distribution failed for the following gears:"
            options[:out].puts message if options[:out]

            failures = result[:gear_results].values.select { |r| r[:status] != RESULT_SUCCESS }
            message = failures.map { |f| "#{f[:gear_uuid]} (#{f[:errors][0]})" }.join("\n")
            options[:out].puts message if options[:out]
          end

          options[:all]                = true
          options[:report_deployments] = true

          activate_result = activate(options)
          result[:activate_result] = activate_result
          activate_status = activate_result[:status]

          message = "Activation status: #{activate_status}"
          options[:out].puts message if options[:out]

          if activate_status != RESULT_SUCCESS
            message = "Activation failed for the following gears:"
            options[:out].puts message if options[:out]

            failures = result[:gear_results].values.select { |r| r[:status] != RESULT_SUCCESS }

            message = failures.map { |f| "#{f[:gear_uuid]} (#{f[:errors][0]})" }.join("\n")
            options[:out].puts message if options[:out]
          end

          result[:status] = RESULT_SUCCESS if distribute_status == RESULT_SUCCESS and activate_status == RESULT_SUCCESS

          message = "Deployment status: #{result[:status]}"
          options[:out].puts message if options[:out]

          result
        end


        # Handles the pre-receive portion of the Git push lifecycle.
        #
        # If a builder cartridge is present, the +pre-receive+ control action is invoked on
        # the builder cartridge. If no builder is present, a user-initiated gear stop is
        # invoked.
        #
        # options: hash
        #   :out        : an IO to which any stdout should be written (default: nil)
        #   :err        : an IO to which any stderr should be written (default: nil)
        #   :hot_deploy : a boolean to toggle hot deploy for the operation (default: false)
        #
        def pre_receive(options={})
          builder_cartridge = @cartridge_model.builder_cartridge

          if builder_cartridge
            @cartridge_model.do_control('pre-receive',
                                        builder_cartridge,
                                        out: options[:out],
                err: options[:err])
          else
            stop_gear(user_initiated:     true,
                      hot_deploy:         options[:hot_deploy],
                      exclude_web_proxy:  true,
                      init:               options[:init],
                      out:                options[:out],
                      err:                options[:err])

            check_deployments_integrity(options)
            deployment_datetime = create_deployment_dir

            configure_deployment_metadata(deployment_datetime,options)
          end
        end

        def child_gear_ssh_urls(type = :web)
          if @cartridge_model.web_proxy
            entries = gear_registry.entries[type]
            entries_excluding_self = entries.select { |gear_uuid, entry| gear_uuid != @uuid }
            entries_excluding_self.map { |gear_uuid, entry| "#{gear_uuid}@#{entry.proxy_hostname}" }
          else
            []
          end
        end

        #
        # Handles the post-receive portion of the Git push lifecycle.
        #
        # If a builder cartridge is present, the +post-receive+ control action is invoked on
        # the builder cartridge. If no builder is present, the following sequence occurs:
        #
        #   1. Executes the primary cartridge +pre-repo-archive+ control action
        #   2. Archives the application Git repository, redeploying the code
        #   3. Executes +build+
        #   4. Executes +deploy+
        #
        # options: hash
        #   :out        : an IO to which any stdout should be written (default: nil)
        #   :err        : an IO to which any stderr should be written (default: nil)
        #   :report_deployments : a boolean to toggle hot deploy for the operation (default: false)
        #
        def post_receive(options={})
          result = {
            status: RESULT_FAILURE
          }

          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          # if init is set, we're being called prior to update-cluster, so we don't
          # have a gear registry. git repo will be synced during update-cluster in this case
          unless options[:init]
            if proxy_cart = options[:proxy_cart] = @cartridge_model.web_proxy
              options[:out].puts "Syncing git content to other proxy gears" if options[:out]
              sync_git_repo(child_gear_ssh_urls(:proxy), gear_env)
            end
          end

          builder_cartridge = @cartridge_model.builder_cartridge

          if builder_cartridge
            @cartridge_model.do_control('post-receive',
                                        builder_cartridge,
                                        out: options[:out],
                                        err: options[:err])
          else
            @cartridge_model.do_control('pre-repo-archive',
                                        @cartridge_model.primary_cartridge,
                                        out:                       options[:out],
                                        err:                       options[:err],
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false)

            # need to add the entry to the options hash, as it's used in build, prepare, distribute, and activate below
            options[:deployment_datetime] = latest_deployment_datetime

            repo_dir = PathUtils.join(@container_dir, 'app-root', 'runtime', 'repo')
            application_repository = ApplicationRepository.new(self)

            deployment_metadata = deployment_metadata_for(options[:deployment_datetime])

            git_ref = deployment_metadata.git_ref
            git_sha1 = application_repository.get_sha1(git_ref)
            deployment_metadata.git_sha1 = git_sha1
            deployment_metadata.save

            application_repository.archive(repo_dir, git_ref)

            build(options)

            prepare(options)

            distribute_result = result[:distribute_result] = distribute(options)
            return result unless distribute_result[:status] == RESULT_SUCCESS

            activate_result = result[:activate_result] = activate(options)
            return result unless activate_result[:status] == RESULT_SUCCESS
          end

          report_build_analytics

          # report approaching quota overage.
          watermark = @config.get('QUOTA_WARNING_PERCENT', '90.0').to_f
          ::OpenShift::Runtime::Node.check_quotas(@uuid, watermark).each do |line|
            options[:err] << "#{line}\n" if options.key?(:err)
          end

          result[:status] = RESULT_SUCCESS
          result
        end

        #
        # A deploy variant intended for use by builder cartridges. This method is useful when
        # the build has already occurred elsewhere, and the gear now needs a local deployment.
        #
        #   1. Executes +prepare+
        #   2. Executes +distribute+ if the gear has a proxy cartridge
        #   3. Executes +activate+
        #   4. (optional) Executes the primary cartridge post-install steps
        #
        # options: hash
        #   :out  : an IO to which any stdout should be written (default: nil)
        #   :err  : an IO to which any stderr should be written (default: nil)
        #   :deployment_datetime : string; the deployment datetime to deploy
        #
        def remote_deploy(options={})
          result = {
            status: RESULT_FAILURE
          }

          prepare(options)

          distribute_result = result[:distribute_result] = distribute(options)
          return result unless distribute_result[:status] == RESULT_SUCCESS

          activate_result = result[:activate_result] = activate(options)
          return result unless activate_result[:status] == RESULT_SUCCESS

          result[:status] = RESULT_SUCCESS
          result
        end

        #
        # Implements the following build process:
        #
        #   1. Set the application state to +BUILDING+
        #   2. Run the cartridge +update-configuration+ control action
        #   3. Run the cartridge +pre-build+ control action
        #   4. Run the +pre_build+ user action hook
        #   5. Run the cartridge +build+ control action
        #   6. Run the +build+ user action hook
        #
        # options: hash
        #   :deployment_datetime  : name of the current deployment (just the date + time)
        #
        # Returns the combined output of all actions as a +String+.
        #
        def build(options={})
          @state.value = ::OpenShift::Runtime::State::BUILDING

          deployment_datetime = options[:deployment_datetime] || latest_deployment_datetime
          deployment_metadata = deployment_metadata_for(deployment_datetime)

          unless options.has_key?(:deployment_datetime)
            # this will execute if coming from a CI builder, since it doesn't
            # specify :deployment_datetime in the options hash
            application_repository = options[:git_repo]

            git_ref = options[:ref]
            git_sha1 = application_repository.get_sha1(git_ref)
            deployment_metadata.git_sha1 = git_sha1
            deployment_metadata.git_ref = git_ref
            deployment_metadata.hot_deploy = options[:hot_deploy]
            deployment_metadata.force_clean_build = options[:force_clean_build]
            deployment_metadata.save
          end

          buffer = ''

          if deployment_metadata.force_clean_build
            message = "Force clean build enabled - cleaning dependencies"
            options[:out].puts message if options[:out]
            buffer << message

            clean_runtime_dirs(dependencies: true, build_dependencies: true)

            # create the dependency directories for each cartridge
            @cartridge_model.each_cartridge do |cartridge|
              @cartridge_model.create_dependency_directories(cartridge)
            end
          end

          message = "Building git ref '#{deployment_metadata.git_ref}', commit #{deployment_metadata.git_sha1}"
          options[:out].puts message if options[:out]
          buffer << message

          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
          deployments_to_keep = deployments_to_keep(env)

          begin
            primary_cartridge = @cartridge_model.primary_cartridge

            buffer << @cartridge_model.do_control('update-configuration',
                                                  primary_cartridge,
                                                  pre_action_hooks_enabled:  false,
                                                  post_action_hooks_enabled: false,
                                                  out:                       options[:out],
                                                  err:                       options[:err])

            buffer << @cartridge_model.do_control('pre-build',
                                                  primary_cartridge,
                                                  pre_action_hooks_enabled: false,
                                                  prefix_action_hooks:      false,
                                                  out:                      options[:out],
                                                  err:                      options[:err])

            buffer << @cartridge_model.do_control('build',
                                                  primary_cartridge,
                                                  pre_action_hooks_enabled: false,
                                                  prefix_action_hooks:      false,
                                                  out:                      options[:out],
                                                  err:                      options[:err])
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
            buffer << "Encountered a failure during build: #{e.message}"
            buffer << "Backtrace: #{e.backtrace.join("\n")}"

            if deployments_to_keep > 1
              buffer << "Restarting application"
              buffer << start_gear(user_initiated:     true,
                                   hot_deploy:         deployment_metadata.hot_deploy,
                                   out:                options[:out],
                                   err:                options[:err])
            end

            # need to reraise so the build is seen as a failure
            raise
          end

          buffer
        end

        # Prepares a deployment for distribution and activation
        #
        # If a file is specified, its contents will be extracted to the deployment directory.
        # The contents of the file must be the following:
        #   repo                  : the application's deployable files (essentially an archive of the git repo)
        #   dependencies          : all dependencies needed to run the application (e.g. virtenv for Python)
        #
        # If present, .openshift/action_hooks/prepare will be invoked prior to calculating the deployment id
        #
        # The deployment id is calculated based on the contents of the deployment directory
        #
        # options: hash
        #   :out                  : an IO to which any stdout should be written (default: nil)
        #   :err                  : an IO to which any stderr should be written (default: nil)
        #   :deployment_datetime  : date + time of the current deployment directory
        #   :file                 : name of the binary deployment archive in app-root/archives to prepare
        #
        # Returns the combined output of all actions as a +String+.
        #
        def prepare(options={})
          options[:out].puts "Preparing build for deployment" if options[:out]

          deployment_datetime = options[:deployment_datetime]

          raise ArgumentError.new('deployment_datetime is required') unless deployment_datetime

          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          logger.info "stdin(#{options[:stdin]}) file(#{options[:file]}) URL(#{options[:artifact_url]})"
          if options[:stdin] || options[:file] || options[:artifact_url]
            options[:destination] = PathUtils.join(@container_dir, 'app-root', 'runtime')

            clean_runtime_dirs(dependencies: true, build_dependencies: true, repo: true)

            logger.info "Starting Extraction"
            extract_deployment_archive(env, options)
            logger.info "Extraction completed artifact should be stored in(#{options[:destination]})"
          end

          buffer = ''

          # call prepare hook
          out = @cartridge_model.do_action_hook('prepare', env, options)
          unless out.nil? or out.empty?
            buffer << out
            options[:out].puts(out) if options[:out]
          end

          deployment_id = calculate_deployment_id(deployment_datetime)
          link_deployment_id(deployment_datetime, deployment_id)

          begin
            sync_runtime_repo_dir_to_deployment(deployment_datetime)
            sync_runtime_dependencies_dir_to_deployment(deployment_datetime)
            sync_runtime_build_dependencies_dir_to_deployment(deployment_datetime)

            deployment_metadata = deployment_metadata_for(deployment_datetime)
            deployment_metadata.id = deployment_id
            deployment_metadata.checksum = calculate_deployment_checksum(deployment_id)
            deployment_metadata.save

            # this is needed so the activate step down the line can work
            options[:deployment_id] = deployment_id

            out = "Deployment id is #{deployment_id}"
            buffer << out
            options[:out].puts(out) if options[:out]
          rescue IOError => e
            out = "Error preparing deployment #{deployment_id}; "
            buffer << out
            options[:out].puts(out) if options[:out]
            unlink_deployment_id(deployment_id)
          end

          buffer
        end

        # options: hash
        #   :out             : an IO to which any stdout should be written (default: nil)
        #   :err             : an IO to which any stderr should be written (default: nil)
        #
        def distribute(options={})
          result = { status: RESULT_SUCCESS, gear_results: {}, messages: [], errors: []}

          # initial build - don't do anything because we don't have a gear registry yet
          # and distribution + activation will happen when update-cluster is called
          return result if options[:init]

          gears = options[:gears] || child_gear_ssh_urls

          return result if gears.empty?

          options[:out].puts "Distributing deployment to child gears" if options[:out]

          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          gear_results = OpenShift::Runtime::Threads::Parallel.map(gears, :in_threads => MAX_THREADS) do |gear|
            gear_result = distribute_to_gear(gear, gear_env)
          end

          gear_results.each do |gear_result|
            result[:gear_results][gear_result[:gear_uuid]] = gear_result
            result[:status] = RESULT_FAILURE unless gear_result[:status] == RESULT_SUCCESS
            result[:messages].push(*gear_result[:messages])
            result[:errors].push(*gear_result[:errors])
          end

          result
        end

        def distribute_to_gear(gear, gear_env)
          result = {
            gear_uuid: gear.split('@')[0],
            status: RESULT_FAILURE,
            messages: [],
            errors: []
          }

          3.times do
            begin
              result = attempt_distribute_to_gear(gear, gear_env)
            rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
              next
            end

            break
          end

          result
        end

        def attempt_distribute_to_gear(gear, gear_env)
          result = {
            gear_uuid: gear.split('@')[0],
            status: RESULT_FAILURE,
            messages: [],
            errors: []
          }

          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')

          rsync_options = remote_rsync_options(result[:gear_uuid])

          command = "rsync #{rsync_options} --rsh=/usr/bin/oo-ssh --delete-before --exclude=current ./ #{gear}:app-deployments/"
          out, err, rc = run_in_container_context(command, env: gear_env, chdir: deployments_dir)

          if out && !out.empty?
            result[:messages] << command
            result[:messages] += out.split("\n")
          end

          if err && !err.empty?
            result[:errors] << command
            result[:errors] += err.split("\n")
          end

          return result unless rc == 0

          result[:status] = RESULT_SUCCESS if rc == 0

          result
        end

        # For a given ratio and number of items, calculate the appropriate batch
        # size such that the value is an integer for ratio * count, or 1 if
        # the product is < 1
        def calculate_batch_size(count, ratio)
          # if ratio is 0.2, then 1/ratio is 5
          #
          # we can't get an integer from e.g. 1 * 0.2, so we want to take a percentage
          # based on the max of 1/ratio and count
          #
          # to finish the example, if count is 1, 2, 3, or 4, then the max will be 5
          # if count is >= 5, then just use count's value when multiplying by the ratio
          (([1/ratio, count].max) * ratio).to_i
        end

        #
        # Activates a specific deployment id for the specified gears
        #
        # options: hash
        #   :deployment_id : the id of the deployment to activate (required)
        #   :gears         : an Array of FQDNs to activate (required)
        #
        def activate(options={})
          deployment_id = options[:deployment_id]
          raise ArgumentError.new("deployment_id must be supplied") unless deployment_id

          options[:out].puts "Activating deployment" if options[:out]

          deployment_datetime = get_deployment_datetime_for_deployment_id(deployment_id)
          deployment_metadata = deployment_metadata_for(deployment_datetime)
          options[:hot_deploy] = deployment_metadata.hot_deploy

          # if it's a new gear via scale-up, force hot_deploy to false
          options[:hot_deploy] = false if options[:post_install] || options[:restore]

          parallel_results = with_gear_rotation(options) do |target_gear, local_gear_env, options|
            target_gear_uuid = target_gear.is_a?(String) ? target_gear : target_gear.uuid
            if target_gear_uuid == self.uuid
              activate_local_gear(options)
            else
              activate_remote_gear(target_gear, local_gear_env, options)
            end
          end

          # if we have a standalone proxy, the call to 'with_gear_rotation' ignores a gear without a web cart
          parallel_results << activate_local_gear(options) if @cartridge_model.standalone_web_proxy?

          activated_gear_uuids = []

          if options[:all] || options[:gears]
            result = { status: RESULT_SUCCESS, gear_results: {}}

            parallel_results.each do |gear_result|
              gear_uuid = gear_result[:gear_uuid]
              activated_gear_uuids << gear_uuid
              result[:gear_results][gear_uuid] = gear_result
              result[:status] = RESULT_FAILURE unless gear_result[:status] == RESULT_SUCCESS
            end
          else
            activated_gear_uuids = [self.uuid]

            # neither options[:all] or options[:gears] was set, so just return the first (and what should be the only) result
            result = parallel_results[0]
          end

          logger.info "Activation result for gears #{activated_gear_uuids.join(", ")}: #{result}"

          result
        end

        # Activates a remote gear
        #
        # options: hash
        #   :deployment_id : the id of the deployment to activate (required)
        #   :post_install  : if true, run post_install after post-deploy (i.e. for a new gear on scale up)
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #
        # @param [OpenShift::Runtime::GearRegistry::Entry] gear the remote gear to activate
        # @param [Hash] gear_env the environment for the local gear
        # @param [Hash] options activation options
        # @option options [String] :deployment_id the deployment ID to activate
        # @option options [Boolean] :post_install if true, run the post-install hook during activation
        def activate_remote_gear(gear, gear_env, options={})
          gear_uuid = gear.uuid

          result = {
            status: RESULT_FAILURE,
            gear_uuid: gear_uuid,
            deployment_id: options[:deployment_id],
            messages: [],
            errors: [],
          }

          post_install_option = (options[:post_install] == true) ? ' --post-install' : ''

          # call activate_gear on the remote gear
          result[:messages] << "Activating gear #{gear_uuid}, deployment id: #{options[:deployment_id]},#{post_install_option}\n"

          begin
            out, err, rc = run_in_container_context("/usr/bin/oo-ssh #{gear.to_ssh_url} gear activate #{options[:deployment_id]} --as-json#{post_install_option} --no-rotation",
                                                    env: gear_env,
                                                    expected_exitstatus: 0)

            raise "No result JSON was received from the remote activate call" if out.nil? || out.empty?

            # JSON.load is not used to prevent class injection. BZ#1086427
            activate_result = HashWithIndifferentAccess.new(JSON.parse(out))

            raise "Invalid result JSON received from remote activate call: #{activate_result.inspect}" unless activate_result.has_key?(:status)

            result[:messages] += activate_result[:messages]
            result[:errors] += activate_result[:errors]
            result[:status] = activate_result[:status]
          rescue Exception => e
            result[:errors] << "Gear activation failed: #{e.message}"
            result[:errors] += e.backtrace
          end

          result
        end

        #
        # Activates a specific deployment id
        #
        # options: hash
        #   :deployment_id : the id of the deployment to activate (required)
        #   :post_install  : if true, run post_install after post-deploy (i.e. for a new gear on scale up)
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #
        def activate_local_gear(options={})
          deployment_id = options[:deployment_id]

          result = {
            status: RESULT_FAILURE,
            gear_uuid: self.uuid,
            deployment_id: deployment_id,
            messages: [],
            errors: []
          }

          if !deployment_exists?(deployment_id)
            result[:errors] << "No deployment with id #{deployment_id} found on gear"
            return result
          end

          begin
            deployment_datetime = get_deployment_datetime_for_deployment_id(deployment_id)

            deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)

            gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

            if @state.value == State::STARTED
              output = stop_gear(options.merge(exclude_web_proxy: true))
              result[:messages] << output unless output.empty?
            end

            sync_deployment_repo_dir_to_runtime(deployment_datetime)
            sync_deployment_dependencies_dir_to_runtime(deployment_datetime)
            sync_deployment_build_dependencies_dir_to_runtime(deployment_datetime)

            update_current_deployment_datetime_symlink(deployment_datetime)

            # look this up once instead of multiple times
            primary_cartridge = @cartridge_model.primary_cartridge

            @cartridge_model.do_control('update-configuration',
                                        primary_cartridge,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])

            msg = "Starting application #{application_name}"
            result[:messages] << msg

            output = start_gear(secondary_only:    true,
                                user_initiated:    true,
                                hot_deploy:        options[:hot_deploy],
                                out:               options[:out],
                                err:               options[:err])

            result[:messages] << output unless output.empty?

            @state.value = ::OpenShift::Runtime::State::DEPLOYING

            output = @cartridge_model.do_control('deploy',
                                                  primary_cartridge,
                                                  pre_action_hooks_enabled: false,
                                                  prefix_action_hooks:      false,
                                                  out:                      options[:out],
                                                  err:                      options[:err])

            result[:messages] << output unless output.empty?

            output = start_gear(primary_only:      true,
                                user_initiated:    true,
                                hot_deploy:        options[:hot_deploy],
                                out:               options[:out],
                                err:               options[:err])

            result[:messages] << output unless output.empty?

            output = @cartridge_model.do_control('post-deploy',
                                                  primary_cartridge,
                                                  pre_action_hooks_enabled: false,
                                                  prefix_action_hooks:      false,
                                                  out:                      options[:out],
                                                  err:                      options[:err])

            result[:messages] << output unless output.empty?

            if options[:post_install]
              primary_cart_env_dir = PathUtils.join(@container_dir, primary_cartridge.directory, 'env')
              primary_cart_env     = ::OpenShift::Runtime::Utils::Environ.load(primary_cart_env_dir)
              ident                = primary_cart_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
              _, _, version, _     = Runtime::Manifest.parse_ident(primary_cart_env[ident.first])

              @cartridge_model.post_install(primary_cartridge, version)

            end

            # append this activation time to the metadata
            deployment_metadata = deployment_metadata_for(deployment_datetime)
            deployment_metadata.record_activation
            deployment_metadata.save

            if options[:report_deployments] && gear_env['OPENSHIFT_APP_DNS'] == gear_env['OPENSHIFT_GEAR_DNS']
              report_deployments(gear_env, out: options[:out])
            end

            result[:status] = RESULT_SUCCESS
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
            result[:status] = RESULT_FAILURE
            result[:errors] << "Error activating gear: #{e.message}\n#{e.stdout}\n#{e.stderr}\n"
          rescue Exception => e
            result[:status] = RESULT_FAILURE
            result[:errors] << "Error activating gear: #{e.message}"
            result[:errors] += e.backtrace
          end

          result
        end

        #
        # Deploys the app
        #
        # options: hash
        #   :hot_deploy    : indicates whether to hot deploy
        #   :force_clean_build : indicates whether to force clean build
        #   :ref           : the ref to deploy
        #   :artifact_url  : the artifact to download and deploy
        #   :report_deployments  : report the deployments back to the broker
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #   :all           : indicates whether to deploy to all gears or just the local one
        #
        def deploy(options={})
          if options[:artifact_url] == nil
            pre_receive(options)
            post_receive(options)
          else
            deploy_binary_artifact(options)
          end
        end

        # === Cartridge control methods

        def start(cart_name, options={})
          @cartridge_model.start_cartridge('start', cart_name,
                                           user_initiated: true,
              out:            options[:out],
              err:            options[:err])
        end

        def stop(cart_name, options={})
          @cartridge_model.stop_cartridge(cart_name,
                                          user_initiated: true,
              out:            options[:out],
              err:            options[:err])
        end

        # Perform a rolling gear rotation, yielding to the block in between
        # the calls to rotate-out and rotate-in.
        #
        # If this is invoked in a gear that does not have a proxy cartridge,
        # no rotation will happen and only the local gear will have the
        # code in the block executed on it.
        #
        # If this is invoked in a gear that does have a web proxy cartridge,
        # and options[:all] is set, the yielded action will be invoked for
        # all web gears.
        #
        # @param [Hash] options
        # @option options [Boolean] all invoke yielded action for all web gears
        def with_gear_rotation(options={}, &block)
          local_gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
          proxy_cart = options[:proxy_cart] = @cartridge_model.web_proxy

          gears = []
          if not options[:init] and proxy_cart
            if options[:all]
              gears = gear_registry.entries[:web].values
            elsif options[:gears]
              gears = gear_registry.entries[:web].values.select { |e| options[:gears].include?(e.uuid) }
            else
              # it's possible the gear registry hasn't been populated yet (scale-up that adds a new proxy cart)
              # so if gear_registry.entries[:web] is nil, just use [uuid] instead
              gears = [gear_registry.entries[:web][uuid]] rescue [uuid]
            end
          else
            gears = [uuid]
          end

          parallel_concurrency_ratio = options[:parallel_concurrency_ratio] || PARALLEL_CONCURRENCY_RATIO

          batch_size = calculate_batch_size(gears.size, parallel_concurrency_ratio)
          threads = [batch_size, MAX_THREADS].min

          parallel_output = OpenShift::Runtime::Threads::Parallel.map(gears, :in_threads => threads) do |target_gear|
            rotate_and_yield(target_gear, local_gear_env, options, &block)
          end
        end

        # If options[:proxy_cart] exists:
        #
        #   1. rotates-out the target gear
        #   2. yields the target gear, local gear environment, and options hash
        #   3. rotates-in the target gear
        #
        # Otherwise, just yields
        #
        def rotate_and_yield(target_gear, local_gear_env, options, &block)
          result = HashWithIndifferentAccess.new({
            status: RESULT_FAILURE,
            messages: [],
            errors: []
          })

          proxy_cart = options[:proxy_cart]

          target_gear_uuid = target_gear.is_a?(String) ? target_gear : target_gear.uuid

          if not options[:init] and options[:rotate] != false and proxy_cart and options[:hot_deploy] != true
            result[:messages] << "Rotating out gear in proxies"
            rotate_out_results = update_proxy_status(action: :disable,
                                                     gear_uuid: target_gear_uuid,
                                                     cartridge: proxy_cart)

            result[:rotate_out_results] = rotate_out_results
            if rotate_out_results[:status] != RESULT_SUCCESS
              result[:errors] << "Rotating out gear in proxies failed"
              return result
            end
          end

          yield_result = yield(target_gear, local_gear_env, options)

          # pull off the status, append messages and errors
          yield_status = yield_result.delete(:status)
          yield_messages = yield_result.delete(:messages) || []
          yield_errors = yield_result.delete(:errors) || []
          result[:messages] += yield_messages
          result[:errors] += yield_errors

          # merge the remaining contents of the yielded result
          result.merge!(yield_result)

          # short circuit if the yielded action failed
          return result if yield_status != RESULT_SUCCESS

          if not options[:init] and options[:rotate] != false and proxy_cart and options[:hot_deploy] != true
            result[:messages] << "Rotating in gear in proxies"
            rotate_in_results = update_proxy_status(action: :enable,
                                                    gear_uuid: target_gear_uuid,
                                                    cartridge: proxy_cart)

            result[:rotate_in_results] = rotate_in_results
            if rotate_in_results[:status] != RESULT_SUCCESS
              result[:errors] << "Rotating in gear in proxies failed"
              return result
            end
          end

          result[:status] = RESULT_SUCCESS
          result
        end

        # Restarts the specified cartridge.
        #
        # If options[:all] is specified and the local gear has a web proxy cartridge,
        # rotates out, restarts, and rotates in each gear.
        #
        # Returns a result hash in the form:
        #
        #  {
        #    status: RESULT_SUCCESS, # or RESULT_FAILURE
        #    gear_results: {
        #      #{target_gear_uuid}: {
        #        target_gear_uuid: #{target_gear_uuid},
        #        status: RESULT_SUCCESS, # or RESULT_FAILURE,
        #        messages: [], # strings
        #        errors: [] # strings
        #      }, ...
        #    }
        #  }
        #
        def restart(cart_name, options={})
          parallel_results = with_gear_rotation(options) do |target_gear, local_gear_env, options|
            target_result = restart_gear(target_gear, local_gear_env, cart_name, options)
          end

          if !!options[:all]
            result = {
              status: RESULT_SUCCESS,
              gear_results: {}
            }

            parallel_results.each do |parallel_result|
              target_gear_uuid = parallel_result[:target_gear_uuid]
              result[:gear_results][target_gear_uuid] = parallel_result

              result[:status] = RESULT_FAILURE unless parallel_result[:status] == RESULT_SUCCESS
            end

            return result
          else
            # options[:all] was false, so just return the first (and what should be the only) result
            return parallel_results[0]
          end
        end

        # Restarts a single cartridge in a single gear. If the gear is local, perform the restart
        # locally. Otherwise, SSH to the remote gear and invoke 'gear restart' to perform the
        # restart.
        #
        # @param [String, OpenShift::Runtime::GearRegistry::Entry] target_gear the target gear to restart,
        #   either a String (the uuid) or a GearRegistry Entry
        def restart_gear(target_gear, local_gear_env, cart_name, options)
          target_gear_uuid = target_gear.is_a?(String) ? target_gear : target_gear.uuid

          result = {
            status: RESULT_SUCCESS,
            target_gear_uuid: target_gear_uuid,
            messages: [],
            errors: []
          }

          begin
            # stay local (don't ssh) if the target gear is the local gear
            if target_gear_uuid == uuid
              if cart_name
                result[:messages] << @cartridge_model.start_cartridge('restart',
                                                                     cart_name,
                                                                     user_initiated: true,
                                                                     out: options[:out],
                                                                     err: options[:err])
              else
                result[:messages] << @cartridge_model.restart_gear(user_initiated: true,
                                                                  out: options[:out],
                                                                  err: options[:err])
              end
            else
              if cart_name
                out, err, rc = run_in_container_context("/usr/bin/oo-ssh #{target_gear.to_ssh_url} gear restart --cart #{cart_name} --as-json",
                                                        env: local_gear_env,
                                                        expected_exitstatus: 0)
              else
                out, err, rc = run_in_container_context("/usr/bin/oo-ssh #{target_gear.to_ssh_url} gear restart --all-cartridges --as-json",
                                                      env: local_gear_env,
                                                      expected_exitstatus: 0)
              end
              raise "No result JSON was received from the remote gear restart call" if out.nil? || out.empty?

              # JSON.load is not used to prevent class injection. BZ#1086427
              result = HashWithIndifferentAccess.new(JSON.parse(out))

              raise "Invalid result JSON received from remote gear restart call: #{result.inspect}" unless result.has_key?(:status)
            end
          rescue => e
            result[:status] = RESULT_FAILURE
            result[:errors] ||= []
            result[:errors] << "An exception occurred restarting the gear: #{e.message}"
            result[:errors] += e.backtrace
          end

          result
        end

        # reload gear as supported by cartridges
        def reload(cart_name)
          if ::OpenShift::Runtime::State::STARTED == state.value
            return @cartridge_model.do_control('reload', cart_name)
          else
            return @cartridge_model.do_control('force-reload', cart_name)
          end
        end

        def threaddump(cart_name)
          unless ::OpenShift::Runtime::State::STARTED == state.value
            raise "CLIENT_ERROR: Application is #{state.value}, must be #{::OpenShift::Runtime::State::STARTED} to allow a thread dump"
          end

          @cartridge_model.do_control('threaddump', cart_name)
        end

        def status(cart_name)
          buffer = ''
          buffer << stopped_status_attr
          quota_cmd = "/bin/sh #{PathUtils.join('/usr/libexec/openshift/lib', "quota_attrs.sh")} #{@uuid}"
          out,err,rc = run_in_container_context(quota_cmd)
          raise "ERROR: Error fetching quota (#{rc}): #{quota_cmd.squeeze(" ")} stdout: #{out} stderr: #{err}" unless rc == 0
          buffer << out
          begin
            buffer << @cartridge_model.do_control("status", cart_name)
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => shell_ex
            # catch the exception. Nonzero exit code may also be a valid status message.
            buffer << "ERROR: Non-zero exitcode returned while executing 'status' command on cartridge. Error code : #{shell_ex.rc}. Stdout : #{shell_ex.stdout}. Stderr : #{shell_ex.stderr}"
          end
          buffer
        end

        def generate_update_cluster_control_args(entries)
          entries ||= gear_registry.entries
          args    = []
          if entries.has_key?(:web)
            entries[:web].each_value do |entry|
              args << "#{entry.dns}|#{entry.proxy_hostname}:#{entry.proxy_port}"
            end
          end
          args.join(' ')
        end

        # Performs the following actions in response to scale up/down:
        #
        # - updates the gear registry
        # - if the current "master" gear, copies all app-deployments to all new gears (if any)
        # - if the current "master" gear, activates the current deployment on all new gears (if any)
        # - calls the web proxy cartridge's 'update-cluster' control method
        def update_cluster(proxies, cluster, rollback, sync_new_gears)
          # currently there's no easy way to only target web proxy gears from the broker
          # via mcollective, so this is a temporary workaround
          return unless proxy_cart = @cartridge_model.web_proxy

          gear_env = ::OpenShift::Runtime::Utils::Environ::for_gear(container_dir)
          updated_entries = nil

          if rollback
            logger.info "Restoring #{uuid} gear registry from backup"
            gear_registry.restore_from_backup
          else
            logger.info "Backing up #{uuid }gear registry"
            gear_registry.backup

            # get a copy of the gear registry as it was before update_cluster was called
            logger.info "Retrieving #{uuid} gear registry entries prior to this update"
            old_registry = gear_registry.entries

            # clear out the gear registry, as we're going to replace it completely with
            # the data provided to us here
            logger.info "Clearing #{uuid} gear registry"
            gear_registry.clear

            cloud_domain = @config.get("CLOUD_DOMAIN")

            cluster.split(' ').each do |line|
              gear_uuid, gear_name, namespace, proxy_hostname, proxy_port, platform = line.split(',')
              gear_dns = "#{gear_name}-#{namespace}.#{cloud_domain}"

              # add the entry to the gear registry
              new_entry = {
                type: :web,
                uuid: gear_uuid,
                namespace: namespace,
                dns: gear_dns,
                proxy_hostname: proxy_hostname,
                proxy_port: proxy_port,
                platform: platform
              }
              logger.info "Adding gear registry #{uuid} new web entry: #{new_entry}"
              gear_registry.add(new_entry)
            end

            proxies.split(' ').each do |line|
              gear_uuid, gear_name, namespace, proxy_hostname, platform = line.split(',')
              gear_dns = "#{gear_name}-#{namespace}.#{cloud_domain}"
              new_entry = {
                type: :proxy,
                uuid: gear_uuid,
                namespace: namespace,
                dns: gear_dns,
                proxy_hostname: proxy_hostname,
                proxy_port: 0,
                platform: platform
              }
              logger.info "Adding gear registry #{uuid} new proxy entry: #{new_entry}"
              gear_registry.add(new_entry)
            end

            # registry_updates now contains what should be the full gear registry and it should
            # replace the existing file on disk
            logger.info "Saving gear registry #{uuid}"
            gear_registry.save

            logger.info "Retrieving updated gear registry #{uuid} entries"
            updated_entries = gear_registry.entries

            # we initialize the standalone web proxy git template after we're aware of web gears
            if @cartridge_model.standalone_web_proxy?
              repo = ApplicationRepository.new(self)

              unless repo.exist?
                @cartridge_model.populate_gear_repo(@cartridge_model.web_proxy.name, nil)
              end

              setup_deployment(latest_deployment_datetime)
            end

            # the broker will inform us if we are supposed to sync and activate new gears
            if sync_new_gears == true
              old_web_gears = old_registry[:web]
              if old_web_gears.nil?
                # If the previous version of the registry had no web gears, it means that
                # an application was created where the cartridge's manifest specified a
                # minimum gear count >= 2. In this case, all gears are new and need syncing
                # and activation (except for self).
                new_web_gears = updated_entries[:web].values.reject { |entry| entry.uuid == self.uuid }
              else
                # The previous version of the registry had some web gears in it, so
                # determine which ones are new.
                new_web_gears = updated_entries[:web].values.select do |entry|
                  entry.uuid != self.uuid and not old_web_gears.keys.include?(entry.uuid)
                end
              end

              unless new_web_gears.empty?
                # sync from this gear (load balancer) to all new gears
                # copy app-deployments and make all the new gears look just like it (i.e., use --delete)
                new_web_gears.each do |web_gear|
                  # convert the new gear to the format uuid@ip
                  gear = "#{web_gear.uuid}@#{web_gear.proxy_hostname}"

                  rsync_options = remote_rsync_options(web_gear)

                  out, err, rc = run_in_container_context("rsync #{rsync_options} --delete --rsh=/usr/bin/oo-ssh app-deployments/ #{gear}:app-deployments/",
                                                          env: gear_env,
                                                          chdir: container_dir,
                                                          expected_exitstatus: 0)
                end

                # activate the current deployment on all the new gears
                deployment_id = deployment_metadata_for(current_deployment_datetime).id

                # TODO this will activate in batches, based on the ratio defined in activate_many
                # may want to consider activating all (limited concurrently to :in_threads) instead
                # of in batches

                # since the gears are new, set post_install to true
                # also set rotate to false because there's no need to rotate out/in these new gears
                # (nor will it work if the new gear is also a proxy gear)
                activate_result = activate(gears: new_web_gears.map(&:uuid), deployment_id: deployment_id, post_install: true, rotate: false)
                if activate_result[:status] != RESULT_SUCCESS
                  errors = []
                  activate_result[:gear_results].each do |uuid, gear_result|
                    errors << "#{uuid}: #{gear_result[:errors][0]}" if gear_result[:status] != RESULT_SUCCESS
                  end
                  raise "Activation of new gears failed: #{errors.join("\n")}" unless activate_result[:status] == RESULT_SUCCESS
                end
              end

              old_proxy_gears = old_registry[:proxy]
              new_proxy_gears = updated_entries[:proxy].values.select do |entry|
                # old_proxy_gears may be nil if this is a brand new HA app
                entry.uuid != self.uuid and old_proxy_gears and not old_proxy_gears.keys.include?(entry.uuid)
              end

              unless new_proxy_gears.empty?
                # convert the new gears to the format uuid@ip
                ssh_urls = new_proxy_gears.map { |e| "#{e.uuid}@#{e.proxy_hostname}" }

                # sync from this gear (load balancer) to all new proxy gears
                # copy the git repo
                sync_git_repo(ssh_urls, gear_env)

                # also sync the private key so that new proxy gears can also deploy to other gears when elected
                sync_private_key(ssh_urls, gear_env)
              end
            end
          end

          args = generate_update_cluster_control_args(updated_entries)
          @cartridge_model.do_control('update-cluster', proxy_cart, args: args)
        end

        def sync_git_repo(ssh_urls, gear_env)
          OpenShift::Runtime::Threads::Parallel.map(ssh_urls, :in_threads => MAX_THREADS) do |gear|
            gear_uuid = gear.split('@')[0]

            rsync_options = remote_rsync_options(gear_uuid)

            out, err, rc = run_in_container_context("rsync #{rsync_options} --delete --exclude hooks --rsh=/usr/bin/oo-ssh git/#{application_name}.git/ #{gear}:git/#{application_name}.git/",
                                                    env: gear_env,
                                                    chdir: container_dir,
                                                    expected_exitstatus: 0)
          end
        end

        def sync_private_key(ssh_urls, gear_env)
          ssh_dir        = PathUtils.join(container_dir, '.openshift_ssh')
          ssh_key        = PathUtils.join(ssh_dir, 'id_rsa')
          OpenShift::Runtime::Threads::Parallel.map(ssh_urls, :in_threads => MAX_THREADS) do |gear|
            out, err, rc = run_in_container_context("rsync -aAXS --rsh=/usr/bin/oo-ssh #{ssh_key}{,.pub} #{gear}:.openshift_ssh/",
                                                    env: gear_env,
                                                    chdir: container_dir,
                                                    expected_exitstatus: 0)
            if rc==0
              # rsync drops the system_u context on the files, reset it
              command = "/usr/bin/oo-ssh #{gear} chcon -u system_u .openshift_ssh/*"
              out, err, rc = run_in_container_context(command, env: gear_env, expected_exitstatus: 0)
            end
          end
        end

        # Enables/disables the specified gear in the current gear's web proxy
        #
        # @param action a Symbol indicating the desired new status (:enable or :disable)
        # @param gear_uuid the web gear to enable/disable
        # @param persist a boolean indicating if the change should be persisted to the configuration file on disk
        #
        # Returns the output of updating the web proxy
        def update_proxy_status_for_gear(options)
          action = options[:action]
          raise ArgumentError.new("action must either be :enable or :disable") unless [:enable, :disable].include?(action)

          gear_uuid = options[:gear_uuid]
          raise ArgumentError.new("gear_uuid is required") if gear_uuid.nil?

          cartridge = options[:cartridge] || @cartridge_model.web_proxy
          raise ArgumentError.new("Unable to update proxy status - no proxy cartridge found") if cartridge.nil?

          persist = options[:persist]
          control = "#{action.to_s}-server"

          args = []
          args << 'persist' if persist
          args << gear_uuid

          @cartridge_model.do_control(control,
                                      cartridge,
                                      args: args.join(' '),
                                      pre_action_hooks_enabled:  false,
                                      post_action_hooks_enabled: false)
        end

        def update_remote_proxy_status(args)
          current_gear = args[:current_gear]
          proxy_gear = args[:proxy_gear]
          target_gear = args[:target_gear]
          cartridge = args[:cartridge]
          action = args[:action]
          persist = args[:persist]
          gear_env = args[:gear_env]

          if current_gear == proxy_gear.uuid
            # self, no need to ssh
            return update_local_proxy_status(cartridge: cartridge, action: action, target_gear: target_gear, persist: persist)
          end

          direction = if :enable == action
            'in'
          else
            'out'
          end

          persist_option = if persist
            '--persist'
          else
            ''
          end

          url = "#{proxy_gear.uuid}@#{proxy_gear.proxy_hostname}"

          command = "/usr/bin/oo-ssh #{url} gear rotate-#{direction} --gear #{target_gear} #{persist_option} --cart #{cartridge.name}-#{cartridge.version} --as-json"

          begin
            out, err, rc = run_in_container_context(command,
                                                    env: gear_env,
                                                    expected_exitstatus: 0)

            raise "No result JSON was received from the remote proxy update call" if out.nil? || out.empty?

            # JSON.load is not used to prevent class injection. BZ#1086427
            result = HashWithIndifferentAccess.new(JSON.parse(out))

            raise "Invalid result JSON received from remote proxy update call: #{result.inspect}" unless result.has_key?(:status)
          rescue => e
            result = {
              status: RESULT_FAILURE,
              proxy_gear_uuid: proxy_gear.uuid,
              messages: [],
              errors: ["An exception occurred updating the proxy status: #{e.message}\n#{e.backtrace.join("\n")}"]
            }
          end

          result
        end

        def update_local_proxy_status(args)
          cartridge = args[:cartridge]
          action = args[:action]
          target_gear = args[:target_gear]
          persist = args[:persist]

          begin
            output = update_proxy_status_for_gear(cartridge: cartridge, action: action, gear_uuid: target_gear, persist: persist)
            result = {
              status: RESULT_SUCCESS,
              proxy_gear_uuid: self.uuid,
              target_gear_uuid: target_gear,
              messages: [],
              errors: []
            }
          rescue => e
            result = {
              status: RESULT_FAILURE,
              proxy_gear_uuid: self.uuid,
              target_gear_uuid: target_gear,
              messages: [],
              errors: ["An exception occurred updating the proxy status: #{e.message}\n#{e.backtrace.join("\n")}"]
            }
          end

          result
        end

        # Enables/disables the selected gear in the current gear's web proxy.
        #
        # If the current gear is the 'master' gear, also updates all other web proxies.
        #
        # @param action a Symbol indicating the desired new status (:enable or :disable)
        # @param gear_uuid the web gear to enable/disable
        # @param persist a boolean indicating if the change should be persisted to the configuration file on disk
        #
        # Returns a result hash in the form:
        #
        #  {
        #    status: RESULT_SUCCESS, # or RESULT_FAILURE
        #    target_gear_uuid: #{gear_uuid}
        #    proxy_results: {
        #      #{proxy_gear_uuid}: {
        #        proxy_gear_uuid: #{proxy_gear_uuid},
        #        status: RESULT_SUCCESS, # or RESULT_FAILURE,
        #        messages: [], # strings
        #        errors: [] # strings
        #      }, ...
        #    }
        #  }
        #
        def update_proxy_status(options)
          action = options[:action]
          raise ArgumentError.new("action must either be :enable or :disable") unless [:enable, :disable].include?(action)

          gear_uuid = options[:gear_uuid]
          raise ArgumentError.new("gear_uuid is required") if gear_uuid.nil?

          cartridge = options[:cartridge] || @cartridge_model.web_proxy
          raise ArgumentError.new("Unable to update proxy status - no proxy cartridge found") if cartridge.nil?

          persist = options[:persist]

          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          result = {
            status: RESULT_SUCCESS, # or RESULT_FAILURE
            target_gear_uuid: gear_uuid,
            proxy_results: {},
          }

          if gear_env['OPENSHIFT_APP_DNS'] != gear_env['OPENSHIFT_GEAR_DNS']
            gear_result = update_local_proxy_status(cartridge: cartridge, action: action, proxy_gear: self.uuid, target_gear: gear_uuid, persist: persist)
            result[:proxy_results][self.uuid] = gear_result
          else
            # only update the other proxies if we're the currently elected proxy
            # TODO the way we determine this needs to change so gears other than
            # the initial proxy gear can be elected
            proxy_entries = gear_registry.entries[:proxy].values

            parallel_results = OpenShift::Runtime::Threads::Parallel.map(proxy_entries, :in_threads => MAX_THREADS) do |entry|
              update_remote_proxy_status(current_gear: self.uuid,
                                         proxy_gear: entry,
                                         target_gear: gear_uuid,
                                         cartridge: cartridge,
                                         action: action,
                                         persist: persist,
                                         gear_env: gear_env)
            end

            parallel_results.each do |parallel_result|
              if parallel_result.has_key?(:proxy_results)
                parallel_result[:proxy_results].each do |proxy_uuid, proxy_result|
                  result[:proxy_results][proxy_uuid] = proxy_result
                end
              else
                result[:proxy_results][parallel_result[:proxy_gear_uuid]] = parallel_result
              end
            end
          end

          # if any results failed, consider the overall operation a failure
          result[:proxy_results].each_value do |proxy_result|
            result[:status] = RESULT_FAILURE unless proxy_result[:status] == RESULT_SUCCESS
          end

          result
        end

        private
          def configure_deployment_metadata(deployment_datetime,options={})
            gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
            git_ref = determine_deployment_ref(gear_env, options[:ref])
            deployment_metadata = deployment_metadata_for(deployment_datetime)
            deployment_metadata.git_ref = git_ref
            deployment_metadata.hot_deploy = options[:hot_deploy]
            deployment_metadata.force_clean_build = options[:force_clean_build]
            deployment_metadata.save
          end

        def remote_rsync_options(gear)
          if gear.is_a? String
            gear = gear_registry.entries[:web][gear]
          end

          case gear.platform
            when 'windows'
              '-rltgoDOv'
            else
              '-avzS'
          end
        end
      end
    end
  end
end
