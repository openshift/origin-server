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
          @cartridge_model.configure(cart_name, template_git_url, manifest)
        end

        def post_configure(cart_name, template_git_url=nil)
          output = ''
          cartridge = @cartridge_model.get_cartridge(cart_name)
          cartridge_home = PathUtils.join(@container_dir, cartridge.directory)

          # Only perform an initial build if the manifest explicitly specifies a need,
          # or if a template Git URL is provided and the cart is capable of builds or deploys.
          if !OpenShift::Git.empty_clone_spec?(template_git_url) && (cartridge.install_build_required || template_git_url) && cartridge.buildable?
            build_log = '/tmp/initial-build.log'
            env       = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

            begin
              ::OpenShift::Runtime::Utils::Cgroups::with_no_cpu_limits(@uuid) do
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
                             env:                 env,
                             chdir:               @container_dir,
                             uid:                 @uid,
                             timeout:             @hourglass.remaining)

              message = "The initial build for the application failed: #{e.message}\n\n.Last #{max_bytes/1024} kB of build output:\n#{out}"

              raise ::OpenShift::Runtime::Utils::Sdk.translate_out_for_client(message, :error)
            end
          end

          output = @cartridge_model.post_configure(cart_name)
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

            config = ::OpenShift::Config.new
            output << "NOTIFY_ENDPOINT_CREATE: #{endpoint.public_port_name} #{config.get('PUBLIC_IP')} #{public_port}\n" 

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
              output << "NOTIFY_ENDPOINT_DELETE: #{p[:public_port_name]} #{config.get('PUBLIC_IP')} #{p[:proxy_port]}\n" if p[:proxy_port]
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
            stop_gear(user_initiated: true,
                hot_deploy:     options[:hot_deploy],
                out:            options[:out],
                err:            options[:err])
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

            ApplicationRepository.new(self).archive

            build(options)

            deploy(options)
          end

          report_build_analytics
        end

        #
        # A deploy variant intended for use by builder cartridges. This method is useful when
        # the build has already occured elsewhere, and the gear now needs a local deployment.
        #
        #   1. Runs the primary cartridge +update-configuration+ control action
        #   2. Executes +deploy+
        #   3. (optional) Executes the primary cartridge post-install steps
        #
        # options: hash
        #   :out  : an IO to which any stdout should be written (default: nil)
        #   :err  : an IO to which any stderr should be written (default: nil)
        #   :init : boolean; if true, post-install steps will be executed (default: false)
        #
        def remote_deploy(options={})
          @cartridge_model.do_control('update-configuration',
                                      @cartridge_model.primary_cartridge,
                                      pre_action_hooks_enabled:  false,
              post_action_hooks_enabled: false,
              out:                       options[:out],
              err:                       options[:err])

          deploy(options)

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
        # Returns the combined output of all actions as a +String+.
        #
        def build(options={})
          @state.value = ::OpenShift::Runtime::State::BUILDING

          buffer = ''

          buffer << @cartridge_model.do_control('update-configuration',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled:  false,
              post_action_hooks_enabled: false,
              out:                       options[:out],
              err:                       options[:err])

          buffer << @cartridge_model.do_control('pre-build',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              out:                      options[:out],
              err:                      options[:err])

          buffer << @cartridge_model.do_control('build',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              out:                      options[:out],
              err:                      options[:err])

          buffer
        end

        #
        # Implements the following deploy process:
        #
        #   1. Start secondary cartridges on the gear
        #   2. Set the application state to +DEPLOYING+
        #   3. Run the web proxy cartridge +deploy+ control action (if such a cartridge is present)
        #   4. Run the primary cartridge +deploy+ control action
        #   5. Run the +deploy+ user action hook
        #   6. Start the primary cartridge on the gear
        #   7. Run the primary cartridge +post-deploy+ control action
        #
        # options: hash
        #   :out        : an IO to which any stdout should be written (default: nil)
        #   :err        : an IO to which any stderr should be written (default: nil)
        #   :hot_deploy : a boolean to toggle hot deploy for the operation (default: false)
        #
        # Returns the combined output of all actions as a +String+.
        #
        def deploy(options={})
          buffer = ''

          buffer << start_gear(secondary_only: true,
              user_initiated: true,
              hot_deploy:     options[:hot_deploy],
              out:            options[:out],
              err:            options[:err])

          @state.value = ::OpenShift::Runtime::State::DEPLOYING

          web_proxy_cart = @cartridge_model.web_proxy
          if web_proxy_cart
            buffer << @cartridge_model.do_control('deploy',
                                                  web_proxy_cart,
                                                  pre_action_hooks_enabled: false,
                prefix_action_hooks:      false,
                out:                      options[:out],
                err:                      options[:err])
          end

          buffer << @cartridge_model.do_control('deploy',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              out:                      options[:out],
              err:                      options[:err])

          buffer << start_gear(primary_only:   true,
              user_initiated: true,
              hot_deploy:     options[:hot_deploy],
              out:            options[:out],
              err:            options[:err])

          buffer << @cartridge_model.do_control('post-deploy',
                                                @cartridge_model.primary_cartridge,
                                                pre_action_hooks_enabled: false,
              prefix_action_hooks:      false,
              out:                      options[:out],
              err:                      options[:err])

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
      end
    end
  end
end
