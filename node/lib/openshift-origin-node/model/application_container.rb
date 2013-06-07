#--
# Copyright 2010 Red Hat, Inc.
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
require 'openshift-origin-node/model/frontend_proxy'
require 'openshift-origin-node/model/frontend_httpd'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/v1_cart_model'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/hourglass'
require 'openshift-origin-common'
require 'yaml'
require 'active_model'
require 'json'
require 'rest-client'
require 'openshift-origin-node/utils/managed_files'
require 'timeout'

module OpenShift
  # == Application Container
  class ApplicationContainer
    include OpenShift::Utils::ShellExec
    include ActiveModel::Observing
    include NodeLogger
    include ManagedFiles

    GEAR_TO_GEAR_SSH = "/usr/bin/ssh -q -o 'BatchMode=yes' -o 'StrictHostKeyChecking=no' -i $OPENSHIFT_APP_SSH_KEY "

    attr_reader :uuid, :application_uuid, :user, :state, :container_name, :cartridge_model

    def initialize(application_uuid, container_uuid, user_uid = nil,
        app_name = nil, container_name = nil, namespace = nil, quota_blocks = nil, quota_files = nil, hourglass = nil)

      @config           = OpenShift::Config.new
      @uuid             = container_uuid
      @application_uuid = application_uuid
      @container_name   = container_name
      @user             = UnixUser.new(application_uuid, container_uuid, user_uid,
                                       app_name, container_name, namespace, quota_blocks, quota_files)
      @state            = OpenShift::Utils::ApplicationState.new(container_uuid)
      @build_model      = self.class.get_build_model(@user, @config)
      @hourglass        = hourglass || Utils::Hourglass.new(3600)

      if @build_model == :v1
        @cartridge_model = V1CartridgeModel.new(@config, @user)
      else
        @cartridge_model = V2CartridgeModel.new(@config, @user, @state, @hourglass)
      end
    end

    def self.get_build_model(user, config)
      build_model = :v1

      if user.homedir && File.exist?(user.homedir)
        build_model = :v2 if OpenShift::Utils::Sdk.new_sdk_app?(user.homedir)
      else
        build_model = OpenShift::Utils::Sdk.node_default_model(config)
      end

      build_model
    end

    def name
      @uuid
    end

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
      if @build_model == :v1
        if template_git_url
          cartridge = @cartridge_model.get_cartridge(cart_name)
          output = @cartridge_model.resolve_application_dependencies(cart_name) if cartridge.buildable?        
        end
      else
        cartridge = @cartridge_model.get_cartridge(cart_name)
        cartridge_home = PathUtils.join(@user.homedir, cartridge.directory)

        # Only perform an initial build if the manifest explicitly specifies a need,
        # or if a template Git URL is provided and the cart is capable of builds or deploys.
        if (cartridge.install_build_required || template_git_url) && cartridge.buildable?
          build_log = '/tmp/initial-build.log'
          env       = Utils::Environ.for_gear(@user.homedir)
  
          begin
            logger.info "Executing initial gear prereceive for #{@uuid}"
            Utils.oo_spawn("gear prereceive >> #{build_log} 2>&1",
                           env:                 env,
                           chdir:               @user.homedir,
                           uid:                 @user.uid,
                           timeout:             @hourglass.remaining,
                           expected_exitstatus: 0)

            logger.info "Executing initial gear postreceive for #{@uuid}"
            Utils.oo_spawn("gear postreceive >> #{build_log} 2>&1",
                           env:                 env,
                           chdir:               @user.homedir,
                           uid:                 @user.uid,
                           timeout:             @hourglass.remaining,
                           expected_exitstatus: 0)
          rescue Utils::ShellExecutionException => e
            max_bytes = 10 * 1024
            out, _, _ = Utils.oo_spawn("tail -c #{max_bytes} #{build_log} 2>&1",
                           env:                 env,
                           chdir:               @user.homedir,
                           uid:                 @user.uid,
                           timeout:             @hourglass.remaining)

            message = "The initial build for the application failed: #{e.message}\n\n.Last #{max_bytes/1024} kB of build output:\n#{out}"

            raise Utils::Sdk.translate_out_for_client(message, :error)
          end
        end

        output = @cartridge_model.post_configure(cart_name)
      end
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

    # create gear
    #
    # - model/unix_user.rb
    # context: root
    def create
      notify_observers(:before_container_create)

      @user.create
      if :v2 == OpenShift::Utils::Sdk.node_default_model(@config)
        Utils::Sdk.mark_new_sdk_app(@user.homedir)
      end

      notify_observers(:after_container_create)
    end

    # Destroy gear
    #
    # - model/unix_user.rb
    # context: root
    # @param skip_hooks should destroy call the gear's hooks before destroying the gear
    def destroy(skip_hooks=false)
      notify_observers(:before_container_destroy)

      # possible mismatch across cart model versions
      output, errout, retcode = @cartridge_model.destroy(skip_hooks)

      notify_observers(:after_container_destroy)

      return output, errout, retcode
    end

    # Public: Sets the app state to "stopped" and causes an immediate forced
    # termination of all gear processes.
    #
    # TODO: exception handling
    def force_stop
      @state.value = OpenShift::State::STOPPED
      @cartridge_model.create_stop_lock
      UnixUser.kill_procs(@user.uid)
    end

    # Creates public endpoints for the given cart. Public proxy mappings are created via
    # the FrontendProxyServer, and the resulting mapped ports are written to environment
    # variables with names based on the cart manifest endpoint entries.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors here
    # are considered fatal.
    def create_public_endpoints(cart_name)
      env  = Utils::Environ::for_gear(@user.homedir)
      cart = @cartridge_model.get_cartridge(cart_name)

      proxy = OpenShift::FrontendProxyServer.new

      # TODO: better error handling
      cart.public_endpoints.each do |endpoint|
        # Load the private IP from the gear
        private_ip = env[endpoint.private_ip_name]

        if private_ip == nil
          raise "Missing private IP #{endpoint.private_ip_name} for cart #{cart.name} in gear #{@uuid}, "\
            "required to create public endpoint #{endpoint.public_port_name}"
        end

        # Attempt the actual proxy mapping assignment
        public_port = proxy.add(@user.uid, private_ip, endpoint.private_port)

        @user.add_env_var(endpoint.public_port_name, public_port)

        logger.info("Created public endpoint for cart #{cart.name} in gear #{@uuid}: "\
          "[#{endpoint.public_port_name}=#{public_port}]")
      end
    end

    # Deletes all public endpoints for the given cart. Public port mappings are
    # looked up and deleted using the FrontendProxyServer, and all corresponding
    # environment variables are deleted from the gear.
    #
    # Returns nil on success. Failed public port delete operations are logged
    # and skipped.
    def delete_public_endpoints(cart_name)
      env  = Utils::Environ::for_gear(@user.homedir)
      cart = @cartridge_model.get_cartridge(cart_name)

      proxy = OpenShift::FrontendProxyServer.new

      public_ports     = []
      public_port_vars = []

      cart.public_endpoints.each do |endpoint|
        # Load the private IP from the gear
        private_ip = env[endpoint.private_ip_name]

        public_port_vars << endpoint.public_port_name

        public_port = proxy.find_mapped_proxy_port(@user.uid, private_ip, endpoint.private_port)

        public_ports << public_port unless public_port == nil
      end

      begin
        # Remove the proxy entries
        rc = proxy.delete_all(public_ports, true)
        logger.info("Deleted all public endpoints for cart #{cart.name} in gear #{@uuid}\n"\
          "Endpoints: #{public_port_vars}\n"\
          "Public ports: #{public_ports}")
      rescue => e
        logger.warn(%Q{Couldn't delete all public endpoints for cart #{cart.name} in gear #{@uuid}: #{e.message}
          Endpoints: #{public_port_vars}
          Public ports: #{public_ports}
                    #{e.backtrace}
                    })
      end

      # Clean up the environment variables
      public_port_vars.each { |var| @user.remove_env_var(var) }
    end

    # Public: Cleans up the gear, providing any installed
    # cartridges with the opportunity to perform their own
    # cleanup operations via the tidy hook.
    #
    # The generic gear-level cleanup flow is:
    # * Stop the gear
    # * Gear temp dir cleanup
    # * Cartridge tidy hook executions
    # * Git cleanup
    # * Start the gear
    #
    # Raises an Exception if an internal error occurs, and ignores
    # failed cartridge tidy hook executions.
    def tidy
      logger.debug("Starting tidy on gear #{@uuid}")

      env      = Utils::Environ::for_gear(@user.homedir)
      gear_dir = env['OPENSHIFT_HOMEDIR']
      app_name = env['OPENSHIFT_APP_NAME']

      raise 'Missing required env var OPENSHIFT_HOMEDIR' unless gear_dir
      raise 'Missing required env var OPENSHIFT_APP_NAME' unless app_name

      gear_repo_dir = File.join(gear_dir, 'git', "#{app_name}.git")
      gear_tmp_dir  = File.join(gear_dir, '.tmp')

      stop_gear(user_initiated: false)

      # Perform the gear- and cart- level tidy actions.  At this point, the gear has
      # been stopped; we'll attempt to start the gear no matter what tidy operations fail.
      begin
        # clear out the tmp dir
        gear_level_tidy_tmp(gear_tmp_dir)

        # Delegate to cartridge model to perform cart-level tidy operations for all installed carts.
        @cartridge_model.tidy

        # git gc - do this last to maximize room  for git to write changes
        gear_level_tidy_git(gear_repo_dir)
      rescue Exception => e
        logger.warn("An unknown exception occured during tidy for gear #{@uuid}: #{e.message}\n#{e.backtrace}")
      ensure
        start_gear(user_initiated: false)
      end

      logger.debug("Completed tidy for gear #{@uuid}")
    end

    ##
    # Sets the application state to +STOPPED+ and stops the gear. Gear stop implementation
    # is model specific, but +options+ is provided to the implementation.
    def stop_gear(options={})
      buffer = @cartridge_model.stop_gear(options)
      unless buffer.empty?
        buffer.chomp!
        buffer << "\n"
      end
      buffer << stopped_status_attr
      buffer
    end

    ##
    # Idles the gear if there is no stop lock and state is not already +STOPPED+.
    #
    def idle_gear(options={})
      if not stop_lock? and (state.value != State::STOPPED)
        frontend = FrontendHttpServer.new(@uuid)
        frontend.idle
        begin
          output = stop_gear
        ensure
          state.value = State::IDLE
        end
        output
      end
    end

    ##
    # Unidles the gear.
    #
    def unidle_gear(options={})
      output = ""
      if stop_lock? and (state.value == State::IDLE)
        state.value = State::STARTED
        output = start_gear
      end
      frontend = FrontendHttpServer.new(@uuid)
      if frontend.idle?
        frontend.unidle
      end
      output
    end

    ##
    # Sets the application state to +STARTED+ and starts the gear. Gear state implementation
    # is model specific, but +options+ is provided to the implementation.
    def start_gear(options={})
      @cartridge_model.start_gear(options)
    end

    def gear_level_tidy_tmp(gear_tmp_dir)
      # Temp dir cleanup
      tidy_action do
        FileUtils.rm_rf(Dir.glob(File.join(gear_tmp_dir, "*")))
        logger.debug("Cleaned gear temp dir at #{gear_tmp_dir}")
      end
    end

    def gear_level_tidy_git(gear_repo_dir)
      # Git pruning
      tidy_action do
        Utils.oo_spawn('git prune', uid: @user.uid, chdir: gear_repo_dir, expected_exitstatus: 0, timeout: @hourglass.remaining)
        logger.debug("Pruned git directory at #{gear_repo_dir}")
      end

      # Git GC
      tidy_action do
        Utils.oo_spawn('git gc --aggressive', uid: @user.uid, chdir: gear_repo_dir, expected_exitstatus: 0, timeout: @hourglass.remaining)
        logger.debug("Executed git gc for repo #{gear_repo_dir}")
      end
    end

    # Executes a block, trapping ShellExecutionExceptions and treating them
    # as warnings. Any other exceptions are unexpected and will bubble out.
    def tidy_action
      begin
        yield
      rescue OpenShift::Utils::ShellExecutionException => e
        logger.warn(%Q{
          Tidy operation failed on gear #{@uuid}: #{e.message}
          --- stdout ---\n#{e.stdout}
          --- stderr ---\n#{e.stderr}
                    })
      end
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

        ApplicationRepository.new(@user).archive

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
        primary_cart_env_dir = File.join(@user.homedir, @cartridge_model.primary_cartridge.directory, 'env')
        primary_cart_env     = Utils::Environ.load(primary_cart_env_dir)
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
      @state.value = OpenShift::State::BUILDING

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

      @state.value = OpenShift::State::DEPLOYING

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
      if State::STARTED == state.value
        return @cartridge_model.do_control('reload', cart_name)
      else
        return @cartridge_model.do_control('force-reload', cart_name)
      end
    end

    ##
    # Creates a snapshot of a gear.
    #
    # Writes an archive (in tar.gz format) to the calling process' STDOUT.
    # The operations invoked by this method write user-facing output to the
    # client on STDERR.
    def snapshot
      stop_gear

      scalable_snapshot = !!@cartridge_model.web_proxy 

      if scalable_snapshot
        begin
          handle_scalable_snapshot
        rescue => e
          $stderr.puts "We were unable to snapshot this application due to communication issues with the OpenShift broker.  Please try again later."
          $stderr.puts "#{e.message}"
          $stderr.puts "#{e.backtrace}"
          return false
        end
      end

      @cartridge_model.each_cartridge do |cartridge|
        @cartridge_model.do_control('pre-snapshot', 
                                    cartridge,
                                    err: $stderr,
                                    pre_action_hooks_enabled: false,
                                    post_action_hooks_enabled: false,
                                    prefix_action_hooks:      false,)
      end

      exclusions = []

      @cartridge_model.each_cartridge do |cartridge|
        exclusions |= snapshot_exclusions(cartridge)
      end

      write_snapshot_archive(exclusions)

      @cartridge_model.each_cartridge do |cartridge|
        @cartridge_model.do_control('post-snapshot', 
                                    cartridge, 
                                    err: $stderr,
                                    pre_action_hooks_enabled: false,
                                    post_action_hooks_enabled: false)
      end      

      start_gear
    end

    def handle_scalable_snapshot
      gear_env = Utils::Environ.for_gear(@user.homedir)

      gear_groups = get_gear_groups(gear_env)

      get_secondary_gear_groups(gear_groups).each do |type, group|
        $stderr.puts "Saving snapshot for secondary #{type} gear"

        ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
        Utils::oo_spawn("#{GEAR_TO_GEAR_SSH} #{ssh_coords} 'snapshot' > #{type}.tar.gz",
                        env: gear_env,
                        chdir: gear_env['OPENSHIFT_DATA_DIR'],
                        uid: @user.uid,
                        gid: @user.gid,
                        err: $stderr,
                        timeout: @hourglass.remaining,
                        expected_exitstatus: 0)
      end
    end

    ##
    # Get the gear groups for the application this gear is part of.
    # 
    # Returns the parsed JSON for the response.
    def get_gear_groups(gear_env)
      broker_addr = @config.get('BROKER_HOST')
      domain = gear_env['OPENSHIFT_NAMESPACE']
      app_name = gear_env['OPENSHIFT_APP_NAME']
      url = "https://#{broker_addr}/broker/rest/domains/#{domain}/applications/#{app_name}/gear_groups.json"

      params = {
        'broker_auth_key' => File.read(File.join(@config.get('GEAR_BASE_DIR'), name, '.auth', 'token')).chomp,
        'broker_auth_iv' => File.read(File.join(@config.get('GEAR_BASE_DIR'), name, '.auth', 'iv')).chomp
      }
      
      request = RestClient::Request.new(:method => :get, 
                                        :url => url, 
                                        :timeout => 120,
                                        :headers => { :accept => 'application/json;version=1.0', :user_agent => 'OpenShift' },
                                        :payload => params)
      
      begin
        response = request.execute()

        if 300 <= response.code 
          raise response
        end
      rescue 
        raise
      end

      begin
        gear_groups = JSON.parse(response)
      rescue
        raise
      end

      gear_groups
    end

    ##
    # Given a list of gear groups, return the secondary gear groups
    def get_secondary_gear_groups(groups)
      secondary_groups = {}

      groups['data'].each do |group|
        group['cartridges'].each do |cartridge|
          cartridge['tags'].each do |tag|
            if tag == 'database'
              secondary_groups[cartridge['name']] = group
            end
          end
        end
      end

      secondary_groups
    end

    def write_snapshot_archive(exclusions)
      gear_env = Utils::Environ.for_gear(@user.homedir)

      exclusions = exclusions.map { |x| "--exclude=./$OPENSHIFT_GEAR_UUID/#{x}" }.join(' ')

      tar_cmd = %Q{
/bin/tar --ignore-failed-read -czf - \
--exclude=./$OPENSHIFT_GEAR_UUID/.tmp \
--exclude=./$OPENSHIFT_GEAR_UUID/.ssh \
--exclude=./$OPENSHIFT_GEAR_UUID/.sandbox \
--exclude=./$OPENSHIFT_GEAR_UUID/*/conf.d/openshift.conf \
--exclude=./$OPENSHIFT_GEAR_UUID/*/run/httpd.pid \
--exclude=./$OPENSHIFT_GEAR_UUID/haproxy-\*/run/stats \
--exclude=./$OPENSHIFT_GEAR_UUID/app-root/runtime/.state \
--exclude=./$OPENSHIFT_DATA_DIR/.bash_history \
#{exclusions} ./$OPENSHIFT_GEAR_UUID
}

      $stderr.puts 'Creating and sending tar.gz'

      Utils.oo_spawn(tar_cmd,
                     env: gear_env,
                     unsetenv_others: true,
                     out: $stdout,
                     chdir: @config.get('GEAR_BASE_DIR'),
                     uid: @user.uid,
                     timeout: @hourglass.remaining,
                     expected_exitstatus: 0)
    end

    ##
    # Restores a gear from an archive read from STDIN.
    #
    # The operation invoked by this method write output to the client on STDERR.
    def restore(restore_git_repo)
      gear_env = Utils::Environ.for_gear(@user.homedir)

      scalable_restore = !!@cartridge_model.web_proxy 
      gear_groups = nil

      if scalable_restore
        gear_groups = get_gear_groups(gear_env)
      end
      
      if restore_git_repo
        pre_receive(err: $stderr, out: $stdout)
      else
        stop_gear
      end

      @cartridge_model.each_cartridge do |cartridge|
        @cartridge_model.do_control('pre-restore', 
                                    cartridge,
                                    pre_action_hooks_enabled: false,
                                    post_action_hooks_enabled: false,
                                    err: $stderr)
      end

      prepare_for_restore(restore_git_repo, gear_env)

      transforms = []
      @cartridge_model.each_cartridge do |cartridge|
        transforms |= restore_transforms(cartridge)
      end

      extract_restore_archive(transforms, restore_git_repo, gear_env)

      if scalable_restore
        handle_scalable_restore(gear_groups, gear_env)
      end

      @cartridge_model.each_cartridge do |cartridge|
        @cartridge_model.do_control('post-restore',
                                     cartridge,
                                     pre_action_hooks_enabled: false,
                                     post_action_hooks_enabled: false,
                                     err: $stderr)
      end

      if restore_git_repo
        post_receive(err: $stderr, out: $stdout)
      else
        start_gear
      end
    end

    def prepare_for_restore(restore_git_repo, gear_env)
      if restore_git_repo
        app_name = gear_env['OPENSHIFT_APP_NAME']
        $stderr.puts "Removing old git repo: ~/git/#{app_name}.git/"
        FileUtils.rm_rf(Dir.glob(File.join(@user.homedir, 'git', "#{app_name}.git", '[^h]*', '*')))
      end

      $stderr.puts "Removing old data dir: ~/app-root/data/*"
      FileUtils.rm_rf(Dir.glob(File.join(@user.homedir, 'app-root', 'data', '*')))
      FileUtils.rm_rf(Dir.glob(File.join(@user.homedir, 'app-root', 'data', '.[^.]*')))
      FileUtils.safe_unlink(File.join(@user.homedir, 'app-root', 'runtime', 'data'))
    end

    def extract_restore_archive(transforms, restore_git_repo, gear_env)
      includes = %w(./*/app-root/data)
      excludes = %w(./*/app-root/runtime/data)
      transforms << 's|${OPENSHIFT_GEAR_NAME}/data|app-root/data|'
      transforms << 's|git/.*\.git|git/${OPENSHIFT_GEAR_NAME}.git|'

      # TODO: use all installed cartridges, not just ones in current instance directory
      @cartridge_model.each_cartridge do |cartridge|
        excludes << "./*/#{cartridge.directory}/data"
      end

      if restore_git_repo
        excludes << './*/git/*.git/hooks'
        includes << './*/git'
        $stderr.puts "Restoring ~/git/#{name}.git and ~/app-root/data"
      else
        $stderr.puts "Restoring ~/app-root/data"
      end

      includes = includes.join(' ')
      excludes = excludes.map { |x| "--exclude=\"#{x}\"" }.join(' ')
      transforms = transforms.map { |x| "--transform=\"#{x}\"" }.join(' ')

      tar_cmd = %Q{/bin/tar --strip=2 --overwrite -xmz #{includes} #{transforms} #{excludes} 1>&2}

      Utils.oo_spawn(tar_cmd,
                     env: gear_env,
                     unsetenv_others: true,
                     out: $stdout,
                     err: $stderr,
                     in: $stdin,
                     chdir: @user.homedir,
                     uid: @user.uid,
                     timeout: @hourglass.remaining,
                     expected_exitstatus: 0)

      FileUtils.cd File.join(@user.homedir, 'app-root', 'runtime') do
        FileUtils.ln_s('../data', 'data')
      end
    end

    def handle_scalable_restore(gear_groups, gear_env)
      secondary_groups = get_secondary_gear_groups(gear_groups)

      secondary_groups.each do |type, group|
        $stderr.puts "Restoring snapshot for #{type} gear"

        ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
        Utils::oo_spawn("cat #{type}.tar.gz | #{GEAR_TO_GEAR_SSH} #{ssh_coords} 'restore'",
                        env: gear_env,
                        chdir: gear_env['OPENSHIFT_DATA_DIR'],
                        uid: @user.uid,
                        gid: @user.gid,
                        err: $stderr,
                        timeout: @hourglass.remaining,
                        expected_exitstatus: 0)
      end
    end

    def status(cart_name)
      buffer = ''
      buffer << stopped_status_attr
      quota_cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "quota_attrs.sh")} #{user.name}"
      out,err,rc = shellCmd(quota_cmd)
      raise "ERROR: Error fetching quota (#{rc}): #{quota_cmd.squeeze(" ")} stdout: #{out} stderr: #{err}" unless rc == 0
      buffer << out
      buffer << @cartridge_model.do_control("status", cart_name)
      buffer
    end

    def stopped_status_attr
      if state.value == State::STOPPED || stop_lock?
        "ATTR: status=ALREADY_STOPPED\n"
      elsif state.value == State::IDLE
        "ATTR: status=ALREADY_IDLED\n"
      else
        ''
      end
    end

    def threaddump(cart_name)
      unless State::STARTED == state.value
        return "CLIENT_ERROR: Application is #{state.value}, must be #{State::STARTED} to allow a thread dump"
      end

      @cartridge_model.do_control('threaddump', cart_name)
    end

    def stop_lock?
      @cartridge_model.stop_lock?
    end

    #
    # Send a fire-and-forget request to the broker to report build analytics.
    #
    def report_build_analytics
      broker_addr = @config.get('BROKER_HOST')
      url         = "https://#{broker_addr}/broker/nurture"

      payload = {
        "json_data" => {
          "app_uuid" => @application_uuid,
          "action"   => "push"
        }.to_json
      }
      
      request = RestClient::Request.new(:method => :post, 
                                        :url => url, 
                                        :timeout => 30,
                                        :open_timeout => 30,
                                        :headers => { :user_agent => 'OpenShift' },
                                        :payload => payload)

      pid = fork do
        Process.daemon
        begin
          Timeout::timeout(60) do
            response = request.execute()
          end
        rescue
          # ignore it
        end

        exit!
      end

      Process.detach(pid)
    end

    #
    # Public: Return an ApplicationContainer object loaded from the container_uuid on the system
    #
    # Caveat: the quota information will not be populated.
    #
    def self.from_uuid(container_uuid, logger=nil)
      u = UnixUser.from_uuid(container_uuid)
      ApplicationContainer.new(u.application_uuid, u.container_uuid, u.uid,
                               u.app_name, u.container_name, u.namespace,
                               nil, nil, logger)
    end

    #
    # Public: Return an enumerator which provides an ApplicationContainer object
    # for every OpenShift gear in the system.
    #
    # Caveat: the quota information will not be populated.
    #
    def self.all(hourglass=nil)
      Enumerator.new do |yielder|
        UnixUser.all.each do |u|
          a=nil
          begin
            a=ApplicationContainer.new(u.application_uuid, u.container_uuid, u.uid,
                                       u.app_name, u.container_name, u.namespace,
                                       nil, nil, hourglass)
          rescue => e
            if logger
              logger.error("Failed to instantiate ApplicationContainer for #{u.application_uuid}: #{e}")
              logger.error("Backtrace: #{e.backtrace}")
            else
              NodeLogger.logger.error("Failed to instantiate ApplicationContainer for #{u.application_uuid}: #{e}")
              NodeLogger.logger.error("Backtrace: #{e.backtrace}")
            end
          else
            yielder.yield(a)
          end
        end
      end
    end

  end
end
