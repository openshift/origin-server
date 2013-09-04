module OpenShift
  module Runtime
    module ApplicationContainerExt
      module CartridgeActions
        # Add cartridge to gear.  This method establishes the cartridge model
        # to use, but does not mark the application.  Marking the application
        # is the responsibility of the cart model.
        #
        # This method does not enforce constraints on whether the cartridge
        # being added is compatible with other installed cartridges.  That
        # is the responsibility of the broker.
        #
        # context: root -> gear user -> root
        # @param cart_name         cartridge name
        # @param template_git_url  URL for template application source/bare repository
        # @param manifest          Broker provided manifest
        def configure(cart_name, template_git_url=nil,  manifest=nil)
          deployment_datetime = latest_deployment_datetime
          # this is necessary so certain cartridge install scripts function properly
          update_dependencies_symlink(deployment_datetime)
          update_build_dependencies_symlink(deployment_datetime)

          @cartridge_model.configure(cart_name, template_git_url, manifest)
        end

        def post_configure(cart_name, template_git_url=nil)
          output         = ''
          cartridge      = @cartridge_model.get_cartridge(cart_name)
          cartridge_home = PathUtils.join(@container_dir, cartridge.directory)

          # Only perform an initial build if the manifest explicitly specifies a need,
          # or if a template Git URL is provided and the cart is capable of builds or deploys.
          if !OpenShift::Git.empty_clone_spec?(template_git_url) && (cartridge.install_build_required || template_git_url) && cartridge.buildable?
            build_log = '/tmp/initial-build.log'
            env       = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

            begin
              ::OpenShift::Runtime::Utils::Cgroups.new(@uuid).boost do
                logger.info "Executing initial gear prereceive for #{@uuid}"
                Utils.oo_spawn("gear prereceive >> #{build_log} 2>&1",
                               env:                 env,
                               chdir:               @container_dir,
                               uid:                 @uid,
                               timeout:             @hourglass.remaining,
                               expected_exitstatus: 0)

                logger.info "Executing initial gear postreceive for #{@uuid}"
                Utils.oo_spawn("gear postreceive >> #{build_log} 2>&1",
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
          else
            deployment_datetime = latest_deployment_datetime
            deployment_state = (read_deployment_metadata(deployment_datetime, 'state') || '').chomp

            # no need to do this for load balancer cartridges
            # no need to do this when cartridges are added (state is already DEPLOYED)
            unless deployment_state == 'DEPLOYED' or cartridge.web_proxy?
              prepare(deployment_datetime: deployment_datetime)

              update_repo_symlink(deployment_datetime)

              write_deployment_metadata(deployment_datetime, 'state', 'DEPLOYED')

              deployments_dir = PathUtils.join(@container_dir, 'app-deployments')
              set_rw_permission_R(deployments_dir)
              reset_permission_R(deployments_dir)
            end
          end

          output << @cartridge_model.post_configure(cart_name)

          pattern   = Utils::Sdk::CLIENT_OUTPUT_PREFIXES.join('|')
          out, _, _ = Utils.oo_spawn("grep -E '#{pattern}' #{build_log}",
                                     env:                 env,
                                     chdir:               @container_dir,
                                     uid:                 @uid,
                                     timeout:             @hourglass.remaining)
          output << out

          output
        end

        # Remove cartridge from gear
        #
        # context: root -> gear user -> root
        # @param cart_name   cartridge name
        def deconfigure(cart_name)
          @cartridge_model.deconfigure(cart_name)
        end

        # Unsubscribe from a cart
        #
        # @param cart_name   unsubscribing cartridge name
        # @param cart_name   publishing cartridge name
        def unsubscribe(cart_name, pub_cart_name)
          @cartridge_model.unsubscribe(cart_name, pub_cart_name)
        end

        # Creates public endpoints for the given cart. Public proxy mappings are created via
        # the FrontendProxyServer, and the resulting mapped ports are written to environment
        # variables with names based on the cart manifest endpoint entries.
        #
        # Returns nil on success, or raises an exception if any errors occur: all errors here
        # are considered fatal.
        def create_public_endpoints(cart_name)
          cart = @cartridge_model.get_cartridge(cart_name)

          output = ''

          # TODO this is a quick fix because the PUBLIC_IP from the node config
          # isn't the one we want - the port proxy binds to the 10.x IPs, not
          # to the public EC2 IP addresses
          ip_address = `facter ipaddress`.chomp

          env  = ::OpenShift::Runtime::Utils::Environ::for_gear(@container_dir)
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

            # Write the load balancer env var if primary option is set
            if endpoint.options and endpoint.options["primary"]
              logger.info("primary option set for the endpoint")
              add_env_var('LOAD_BALANCER_PORT', public_port, true)
            end

            config = ::OpenShift::Config.new
            endpoint_create_hash = { "external_address" => config.get('PUBLIC_IP'),
                                     "external_port" => public_port,
                                     "internal_address" => private_ip,
                                     "internal_port" => endpoint.private_port,
                                     "protocols" => endpoint.protocols,
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
            output << "NOTIFY_ENDPOINT_CREATE: #{endpoint_create_hash.to_json}\n"

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
                      out:                options[:out],
                      err:                options[:err])
          end
        end

        def child_gear_ssh_urls
          if @cartridge_model.web_proxy
            ::OpenShift::Runtime::GearRegistry.new(self).ssh_urls.reject { |g| g.split('@')[0] == @uuid }
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
        #   :hot_deploy : a boolean to toggle hot deploy for the operation (default: false)
        #   :branch     : the git branch to use
        #   :force_clean_build    : if true, don't copy the previous deployment's dependencies to the new one (default: false)
        #
        def post_receive(options={})
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
            if options[:hot_deploy]
              options[:deployment_datetime] = current_deployment_datetime
            else
              options[:deployment_datetime] = create_deployment_dir
            end

            repo_dir = PathUtils.join(@container_dir, 'app-deployments', options[:deployment_datetime], 'repo')
            ApplicationRepository.new(self).archive(repo_dir, options[:branch] || 'master')

            build(options)

            prepare(options)

            # activate the local gear
            activate(options)

            # if we have children, activate them
            if @cartridge_model.web_proxy
              distribute(options)

              activate_many(options)
            end
          end

          report_build_analytics
        end

        #
        # A deploy variant intended for use by builder cartridges. This method is useful when
        # the build has already occurred elsewhere, and the gear now needs a local deployment.
        #
        #   1. Runs the primary cartridge +update-configuration+ control action
        #   2. Executes +deploy+
        #   3. (optional) Executes the primary cartridge post-install steps
        #
        # options: hash
        #   :out  : an IO to which any stdout should be written (default: nil)
        #   :err  : an IO to which any stderr should be written (default: nil)
        #   :init : boolean; if true, post-install steps will be executed (default: false)
        #   :deployment_datetime : string; the deployment datetime to deploy
        #
        def remote_deploy(options={})
          @cartridge_model.do_control('update-configuration',
                                      @cartridge_model.primary_cartridge,
                                      pre_action_hooks_enabled:  false,
                                      post_action_hooks_enabled: false,
                                      out:                       options[:out],
                                      err:                       options[:err])

          repo_dir = PathUtils.join(@container_dir, 'app-deployments', options[:deployment_datetime], 'repo')

          prepare(options)

          # activate the local gear
          activate(options)

          # if we have children, activate them
          if @cartridge_model.web_proxy
            distribute(options)

            activate_many(options)
          end
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

          overrides = {}
          if options[:deployment_datetime]
            overrides['OPENSHIFT_REPO_DIR'] = PathUtils.join(@container_dir, 'app-deployments', options[:deployment_datetime], 'repo') + "/"
            update_dependencies_symlink(options[:deployment_datetime])
            update_build_dependencies_symlink(options[:deployment_datetime])
          end


          buffer = ''

          buffer << @cartridge_model.do_control('update-configuration',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled:  false,
              post_action_hooks_enabled: false,
              env_overrides:             overrides,
              out:                       options[:out],
              err:                       options[:err])

          buffer << @cartridge_model.do_control('pre-build',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              env_overrides:            overrides,
              out:                      options[:out],
              err:                      options[:err])

          buffer << @cartridge_model.do_control('build',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              env_overrides:            overrides,
              out:                      options[:out],
              err:                      options[:err])

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
          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          # override deployment dir env var for hook use
          deployment_datetime = options[:deployment_datetime]
          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          env['OPENSHIFT_REPO_DIR'] = "#{deployment_dir}/repo"

          if options[:file]
            file = PathUtils.join(@container_dir, 'app-archives', options[:file])
            if !File.exist?(file)
              raise "Specified file '#{file}' does not exist."
            end

            # explode file
            # TODO support things other than tar.gz
            out, err, rc = run_in_container_context("tar xf #{file}",
                                                    env: env,
                                                    chdir: deployment_dir,
                                                    expected_exitstatus: 0)
          end

          buffer = ''

          # call prepare hook
          out = @cartridge_model.do_action_hook('prepare', env, options)
          unless out.nil? or out.empty?
            buffer << out
            options[:out].puts(out) if options[:out]
          end

          deployment_id = calculate_deployment_id(deployment_datetime)

          # this is needed so the distribute and activate steps down the line can work
          options[:deployment_id] = deployment_id

          # create symlink so it's easier to find later by id
          FileUtils.cd(PathUtils.join(@container_dir, 'app-deployments', 'by-id')) do
            FileUtils.ln_s(PathUtils.join('..', deployment_datetime), deployment_id)
          end

          write_deployment_metadata(deployment_datetime, 'id', deployment_id)

          out = "Prepared deployment artifacts in #{deployment_dir}\n"
          buffer << out
          options[:out].puts(out) if options[:out]

          out = "Deployment id is #{deployment_id}"
          buffer << out
          options[:out].puts(out) if options[:out]

          buffer
        end

        # options: hash
        #   :out             : an IO to which any stdout should be written (default: nil)
        #   :err             : an IO to which any stderr should be written (default: nil)
        #   :deployment_id   : previously built/prepared deployment
        #
        # Returns the combined output of all actions as a +String+.
        #
        def distribute(options={})
          gears = options[:gears] || child_gear_ssh_urls
          return if gears.empty?

          # TODO error if deployment doesn't exist

          deployment_id = options[:deployment_id]
          deployment_datetime = get_deployment_datetime_for_deployment_id(deployment_id)

          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)

          buffer = ''

          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          #TODO this really should be parallelized
          gears.each do |gear|
            # since the gear will look like 51e96b5e4f43c070fc000001@s1-agoldste.dev.rhcloud.com
            # splitting by @ and taking the first element gets the gear's uuid
            # no need to distribute to self
            gear_uuid = gear.split('@')[0]

            out, err, rc = run_in_container_context("rsync -axvz --rsh=/usr/bin/oo-ssh ./ #{gear}:app-deployments/#{deployment_datetime}/",
                                                    env: gear_env,
                                                    chdir: deployment_dir,
                                                    expected_exitstatus: 0)

            buffer << out

            # create by-id symlink
            out, err, rc = run_in_container_context("rsync -axvz --rsh=/usr/bin/oo-ssh #{deployment_id} #{gear}:app-deployments/by-id/#{deployment_id}",
                                                    env: gear_env,
                                                    chdir: PathUtils.join(@container_dir, 'app-deployments', 'by-id'),
                                                    expected_exitstatus: 0)

            buffer << out
          end

          buffer
        end

        #
        # Activates a specific deployment id for the specified gears
        #
        # options: hash
        #   :deployment_id : the id of the deployment to activate (required)
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #   :gears         : an Array of FQDNs to activate (required)
        #
        def activate_many(options={})
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          # only activate if we're the currently elected proxy
          # TODO the way we determine this needs to change so gears other than
          # the initial proxy gear can be elected
          return if gear_env['OPENSHIFT_APP_DNS'] != gear_env['OPENSHIFT_GEAR_DNS']

          gears = options[:gears] || child_gear_ssh_urls
          return if gears.empty?

          buffer = ''

          web_proxy_cart = @cartridge_model.web_proxy

          #TODO this really should be parallelized
          gears.each do |gear|
            # since the gear will look like 51e96b5e4f43c070fc000001@s1-agoldste.dev.rhcloud.com
            # splitting by @ and taking the first element gets the gear's uuid
            gear_uuid = gear.split('@')[0]

            hot_deploy_option = (options[:hot_deploy] == true) ? '--hot-deploy' : '--no-hot-deploy'
            init_option = (options[:init] == true) ? ' --init' : ''

            @cartridge_model.do_control('disable-server',
                                        web_proxy_cart,
                                        args: gear_uuid,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])

            out = "Activating gear #{gear_uuid}, deployment id: #{options[:deployment_id]}, #{hot_deploy_option},#{init_option}\n"
            buffer << out
            options[:out].puts(out) if options[:out]

            out, err, rc = run_in_container_context("/usr/bin/oo-ssh #{gear} gear activate #{options[:deployment_id]} #{hot_deploy_option}#{init_option}",
                                                    env: gear_env,
                                                    expected_exitstatus: 0)
            buffer << out
            options[:out].puts(out) if options[:out]

            @cartridge_model.do_control('enable-server',
                                        web_proxy_cart,
                                        args: gear_uuid,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])
          end

          buffer
        end

        #
        # Activates a specific deployment id
        #
        # options: hash
        #   :deployment_id : the id of the deployment to activate (required)
        #   :init          : if true, run post_install after post-deploy (i.e. for a new gear on scale up)
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #
        def activate(options={})
          deployment_id = options[:deployment_id]
          deployment_datetime = get_deployment_datetime_for_deployment_id(deployment_id)

          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)

          buffer = ''

          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          if @state.value == State::STARTED
            output = stop_gear(options.merge(exclude_web_proxy: true))
            buffer << output
            options[:out].puts(output) if options[:out]
          end

          update_repo_symlink(deployment_datetime)
          update_dependencies_symlink(deployment_datetime)

          # TODO only do for children?
          @cartridge_model.do_control('update-configuration',
                                      @cartridge_model.primary_cartridge,
                                      pre_action_hooks_enabled:  false,
                                      post_action_hooks_enabled: false,
                                      out:                       options[:out],
                                      err:                       options[:err])

          msg = "Starting application #{application_name}\n"
          buffer << msg
          options[:out].puts(msg) if options[:out]

          output = start_gear(secondary_only: true,
                              user_initiated: true,
                              exclude_web_proxy: true,
                              hot_deploy:     options[:hot_deploy],
                              out:            options[:out],
                              err:            options[:err])

          buffer << output

          @state.value = ::OpenShift::Runtime::State::DEPLOYING

          output = @cartridge_model.do_control('deploy',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
                                                prefix_action_hooks:      false,
                                                out:                      options[:out],
                                                err:                      options[:err])

          buffer << output

          output = start_gear(primary_only:   true,
                              user_initiated: true,
                              exclude_web_proxy: true,
                              hot_deploy:     options[:hot_deploy],
                              out:            options[:out],
                              err:            options[:err])

          buffer << output

          output = @cartridge_model.do_control('post-deploy',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
                                                prefix_action_hooks:      false,
                                                out:                      options[:out],
                                                err:                      options[:err])

          buffer << output

          if options[:init]
            primary_cart_env_dir = PathUtils.join(@container_dir, @cartridge_model.primary_cartridge.directory, 'env')
            primary_cart_env     = ::OpenShift::Runtime::Utils::Environ.load(primary_cart_env_dir)
            ident                = primary_cart_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
            _, _, version, _     = Runtime::Manifest.parse_ident(primary_cart_env[ident.first])

            @cartridge_model.post_install(@cartridge_model.primary_cartridge,
                                          version,
                                          out: options[:out],
                                          err: options[:err])

          end

          write_deployment_metadata(deployment_datetime, 'state', 'DEPLOYED')
          clean_up_deployments_before(deployment_datetime)

          if web_proxy_cart = @cartridge_model.web_proxy
            @cartridge_model.do_control('enable-server',
                                        web_proxy_cart,
                                        args: self.uuid,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])
          end

          buffer
        end

        #
        # Rolls back to the previous deployment for the specified gears
        #
        # options: hash
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #   :gears         : an Array of FQDNs to activate (required)
        #
        def rollback_many(options={})
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          # only rollback if we're the currently elected proxy
          # TODO the way we determine this needs to change so gears other than
          # the initial proxy gear can be elected
          return if gear_env['OPENSHIFT_APP_DNS'] != gear_env['OPENSHIFT_GEAR_DNS']

          gears = options[:gears] || child_gear_ssh_urls
          return if gears.empty?

          buffer = ''

          web_proxy_cart = @cartridge_model.web_proxy

          #TODO this really should be parallelized
          gears.each do |gear|
            # since the gear will look like 51e96b5e4f43c070fc000001@s1-agoldste.dev.rhcloud.com
            # splitting by @ and taking the first element gets the gear's uuid
            gear_uuid = gear.split('@')[0]

            @cartridge_model.do_control('disable-server',
                                        web_proxy_cart,
                                        args: gear_uuid,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])

            out = "Rolling back gear #{gear_uuid}\n"
            buffer << out
            options[:out].puts(out) if options[:out]

            out, err, rc = run_in_container_context("/usr/bin/oo-ssh #{gear} gear rollback",
                                                    env: gear_env,
                                                    expected_exitstatus: 0)
            buffer << out
            options[:out].puts(out) if options[:out]

            @cartridge_model.do_control('enable-server',
                                        web_proxy_cart,
                                        args: gear_uuid,
                                        pre_action_hooks_enabled:  false,
                                        post_action_hooks_enabled: false,
                                        out:                       options[:out],
                                        err:                       options[:err])
          end

          buffer
        end

        #
        # Rolls back to the previous deployment
        #
        # options: hash
        #   :out           : an IO to which any stdout should be written (default: nil)
        #   :err           : an IO to which any stderr should be written (default: nil)
        #
        def rollback(options={})
          buffer = ''
          rollback_to = nil

          if options[:deployment_id]
            deployment_datetime = get_deployment_datetime_for_deployment_id(options[:deployment_id])
            unless deployment_datetime.nil?
              deployment_state = read_deployment_metadata(deployment_datetime, 'state') || ''
              rollback_to = options[:deployment_id] if deployment_state.chomp == 'DEPLOYED'
            end
          else
            deployments_dir = PathUtils.join(@container_dir, 'app-deployments')

            current_deployment = current_deployment_datetime

            # get a list of all entries in app-deployments excluding 'by-id'
            deployments = Dir["#{deployments_dir}/*"].entries.reject {|e| File.basename(e) == 'by-id'}.sort.reverse

            out = "Looking up previous deployment\n"
            buffer << out
            options[:out].puts(out) if options[:out]

            # make sure we get the latest 'deployed' dir prior to the current one
            rollback_to = nil
            found_current = false
            deployments.each do |d|
              candidate = File.basename(d)
              unless found_current
                found_current = true if candidate == current_deployment
              else
                deployment_state = read_deployment_metadata(candidate, 'state') || ''
                if deployment_state.chomp == 'DEPLOYED'
                  rollback_to = read_deployment_metadata(candidate, 'id').chomp
                  break
                end
              end
            end
          end

          if rollback_to
            # activate
            out = "Rolling back to deployment ID #{rollback_to}\n"
            buffer << out
            options[:out].puts(out) if options[:out]

            buffer << activate(options.merge(deployment_id: rollback_to))
          else
            if options[:deployment_id]
              if deployment_exists?(options[:deployment_id])
                raise "Deployment ID '#{options[:deployment_id]}' was never deployed - unable to roll back"
              else
                raise "Deployment ID '#{options[:deployment_id]}' does not exist"
              end
            else
              raise 'No prior deployments exist - unable to roll back'
            end
          end

          buffer
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

        # restart gear as supported by cartridges
        def restart(cart_name, options={})
          @cartridge_model.start_cartridge('restart', cart_name,
                                           user_initiated: true,
              out:            options[:out],
              err:            options[:err])
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
            return "CLIENT_ERROR: Application is #{state.value}, must be #{::OpenShift::Runtime::State::STARTED} to allow a thread dump"
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
          buffer << @cartridge_model.do_control("status", cart_name)
          buffer
        end

        def update_cluster(cluster)
          # currently there's no easy way to only target web proxy gears from the broker
          # via mcollective, so this is a temporary workaround
          return unless @cartridge_model.web_proxy

          gear_env = ::OpenShift::Runtime::Utils::Environ::for_gear(container_dir)
          gear_registry = ::OpenShift::Runtime::GearRegistry.new(self)

          registry_updates = {}

          cloud_domain = @config.get("CLOUD_DOMAIN")
          set_proxy_input = []
          cluster.split(' ').each do |line|
            gear_uuid, gear_name, namespace, private_ip, proxy_port = line.split(',')
            gear_dns = "#{gear_name}-#{namespace}.#{cloud_domain}"
            set_proxy_input << "#{gear_dns}|#{private_ip}:#{proxy_port}"

            # add the entry to the temp hash of registry updates
            registry_updates[gear_uuid] = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuid,
                                                                                   namespace: namespace,
                                                                                   dns: gear_dns,
                                                                                   private_ip: private_ip,
                                                                                   proxy_port: proxy_port)
          end

          # registry_updates now contains what should be the full gear registry and it should
          # replace the existing file on disk

          # update the gear registry
          # returns a list of new gears added with this update
          new_gears = gear_registry.update(registry_updates)

          # only rsync and activate if we're the currently elected proxy
          # TODO the way we determine this needs to change so gears other than
          # the initial proxy gear can be elected
          if gear_env['OPENSHIFT_APP_DNS'] == gear_env['OPENSHIFT_GEAR_DNS']
            # exclude the current gear - no need to do any work on it
            new_gears.delete_if { |k,v| k.uuid == self.uuid }

            unless new_gears.empty?
              # convert the new gears to the format uuid@ip
              new_gears.map! { |e| "#{e.uuid}@#{e.private_ip}" }

              # sync from this gear (load balancer) to all new gears
              # copy app-deployments and make all the new gears look just like it (i.e., use --delete)
              new_gears.each do |gear|
                out, err, rc = run_in_container_context("rsync -axvz --delete --rsh=/usr/bin/oo-ssh app-deployments/ #{gear}:app-deployments/",
                                                        env: gear_env,
                                                        chdir: container_dir,
                                                        expected_exitstatus: 0)
              end

              # activate the current deployment on all the new gears
              deployment_id = read_deployment_metadata(current_deployment_datetime, 'id').chomp
              # since the gears are new, set init to true and hot_deploy to false
              activate_many(gears: new_gears, deployment_id: deployment_id, init: true, hot_deploy: false)
            end
          end

          args = set_proxy_input.join(' ')
          @cartridge_model.do_control('update-cluster', @cartridge_model.web_proxy, args: args)
        end
      end
    end
  end
end
