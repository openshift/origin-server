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
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/v1_cart_model'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/cartridge'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-common'
require 'logger'
require 'yaml'
require 'active_model'

module OpenShift
  # == Application Container
  class ApplicationContainer
    include OpenShift::Utils::ShellExec
    include ActiveModel::Observing

    attr_reader :uuid, :application_uuid, :user, :state, :container_name


    def initialize(application_uuid, container_uuid, user_uid = nil,
        app_name = nil, container_name = nil, namespace = nil, quota_blocks = nil, quota_files = nil, logger = nil)
      @logger = logger ||= Logger.new(STDOUT)

      @config = OpenShift::Config.new

      @uuid = container_uuid
      @application_uuid = application_uuid
      @container_name = container_name
      @user = UnixUser.new(application_uuid, container_uuid, user_uid,
        app_name, container_name, namespace, quota_blocks, quota_files)
      @state = OpenShift::Utils::ApplicationState.new(container_uuid)

      # smells
      @cart_model = nil
    end

    def name
      @uuid
    end

    #-----------------------------------
    # Cart Model:
    # 
    # There are two use cases for determining the cartridge
    # model to use:
    # 
    # 1. ApplicationContainer is created for a new application which
    #    contains no cartridges and the model must be inferred from the name
    #    of the cartridge being added
    def establish_cart_model(cart)
      unless @cart_model
        @cart_model = (OpenShift::Utils::Sdk.v1_cartridges.include?(cart)) ? 
          V1CartridgeModel.new(@config, @user, self, @logger) : V2CartridgeModel.new(@config, @user, self, @logger)
      end
    end

    # 2. ApplicationContainer is created for an existing app which
    #    already has a cartridge and thus an appropriate cart model
    #    to use.
    def cart_model
      unless @cart_model
        @cart_model = (OpenShift::Utils::Sdk.is_new_sdk_app(@user.homedir)) ? 
          V2CartridgeModel.new(@config, @user, self, @logger) : V1CartridgeModel.new(@config, @user, self, @logger)
      end

      @cart_model
    end

    # Loads a cartridge from manifest for the given name.
    #
    # TODO: Caching?
    def get_cartridge(cart_name)
      begin
        manifest_path = cart_model.get_cart_manifest_path(cart_name)
        manifest = YAML.load_file(manifest_path)
        return OpenShift::Runtime::Cartridge.new(manifest)
      rescue => e
        @logger.error(e.backtrace)
        raise "Failed to load cart manifest from #{manifest_path} for cart #{cart_name} in gear #{@uuid}: #{e.message}"
      end
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
    # @param cart_name   cartridge name
    def configure(cart_name, template_git_url=nil)
      establish_cart_model(cart_name)
      cart_model.configure(cart_name, template_git_url)
    end

    # Remove cartridge from gear
    #
    # context: root -> gear user -> root
    # @param cart_name   cartridge name
    def deconfigure(cart_name)
      cart_model.deconfigure(cart_name)
    end

    # create gear
    #
    # - model/unix_user.rb
    # context: root
    def create
      notify_observers(:before_container_create)
      @user.create
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
      output, errout, retcode = cart_model.destroy(skip_hooks)

      notify_observers(:after_container_destroy)

      return output, errout, retcode
    end

    # Public: Sets the app state to "stopped" and causes an immediate forced
    # termination of all gear processes.
    #
    # TODO: exception handling
    def force_stop
      @state.value = ApplicationState::State::STOPPED
      UnixUser.kill_procs(@user.uid)
    end

    # Creates public endpoints for the given cart. Public proxy mappings are created via
    # the FrontendProxyServer, and the resulting mapped ports are written to environment
    # variables with names based on the cart manifest endpoint entries.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors here
    # are considered fatal.
    def create_public_endpoints(cart_name)
      env = Utils::Environ::for_gear(@user.homedir)
      cart = get_cartridge(cart_name)

      proxy = OpenShift::FrontendProxyServer.new(@logger)

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

        @logger.info("Created public endpoint for cart #{cart.name} in gear #{@uuid}: "\
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
      env = Utils::Environ::for_gear(@user.homedir)
      cart = get_cartridge(cart_name)

      proxy = OpenShift::FrontendProxyServer.new(@logger)

      public_ports = []
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
        @logger.info("Deleted all public endpoints for cart #{cart.name} in gear #{@uuid}\n"\
          "Endpoints: #{public_port_vars}\n"\
          "Public ports: #{public_ports}")
      rescue => e
        @logger.warn(%Q{Couldn't delete all public endpoints for cart #{cart.name} in gear #{@uuid}: #{e.message}
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
    # * Git cleanup
    # * Gear temp dir cleanup
    # * Cartridge tidy hook executions
    # * Start the gear
    #
    # Raises an Exception if an internal error occurs, and ignores
    # failed cartridge tidy hook executions.
    def tidy
      @logger.debug("Starting tidy on gear #{@uuid}")

      env = Utils::Environ::for_gear(@user.homedir)
      gear_dir = env['OPENSHIFT_HOMEDIR']
      app_name = env['OPENSHIFT_APP_NAME']

      gear_repo_dir = File.join(gear_dir, 'git', "#{app_name}.git")
      gear_tmp_dir = File.join(gear_dir, '.tmp')

      stop_gear(gear_dir)

      # Perform the gear- and cart- level tidy actions.  At this point, the gear has
      # been stopped; we'll attempt to start the gear no matter what tidy operations fail.
      begin
        gear_level_tidy(gear_repo_dir, gear_tmp_dir)

        # Delegate to cartridge model to perform cart-level tidy operations for all installed carts.
        cart_model.tidy
      rescue Exception => e
        @logger.warn("An unknown exception occured during tidy for gear #{@uuid}: #{e.message}\n#{e.backtrace}")
      ensure
        start_gear(gear_dir)
      end

      @logger.debug("Completed tidy for gear #{@uuid}")
    end

    def stop_gear(gear_dir)
      # TODO: remove shell command
      begin
        # Stop the gear. If this fails, consider the tidy a failure.
        out, err, rc = OpenShift::Utils::ShellExec.shellCmd("/usr/sbin/oo-admin-ctl-gears stopgear #{@user.uuid}", gear_dir, false, 0)
        @logger.debug("Stopped gear #{@uuid}. Output:\n#{out}")
      rescue OpenShift::Utils::ShellExecutionException => e
        @logger.error(%Q{
          Couldn't stop gear #{@uuid} for tidy: #{e.message}
          --- stdout ---\n#{e.stdout}
          --- stderr ---\n#{e.stderr}
          })
        raise "Tidy failed on gear #{@uuid}; the gear couldn't be stopped successfully"
      end
    end

    def start_gear(gear_dir)
      # TODO: remove shell command
      begin
        # Start the gear, and if that fails raise an exception, as the app is now
        # in a bad state.
        out, err, rc = OpenShift::Utils::ShellExec.shellCmd("/usr/sbin/oo-admin-ctl-gears startgear #{@user.uuid}", gear_dir)
        @logger.debug("Started gear #{@uuid}. Output:\n#{out}")
      rescue OpenShift::Utils::ShellExecutionException => e
        @logger.error(%Q{
          Failed to restart gear #{@uuid} following tidy: #{e.message}
          --- stdout ---\n#{e.stdout}
          --- stderr ---\n#{e.stderr}
          })
        raise "Tidy of gear #{@uuid} failed, and the gear was not successfuly restarted"
      end
    end

    def gear_level_tidy(gear_repo_dir, gear_tmp_dir)
      # Git pruning
      tidy_action do
        OpenShift::Utils::ShellExec.run_as(@user.uid, @user.gid, "git prune", gear_repo_dir, false, 0)
        @logger.debug("Pruned git directory at #{gear_repo_dir}")
      end

      # Git GC
      tidy_action do
        OpenShift::Utils::ShellExec.run_as(@user.uid, @user.gid, "git gc --aggressive", gear_repo_dir, false, 0)
        @logger.debug("Executed git gc for repo #{gear_repo_dir}")
      end

      # Temp dir cleanup
      tidy_action do
        FileUtils.rm_rf(Dir.glob(File.join(gear_tmp_dir, "*")))
        @logger.debug("Cleaned gear temp dir at #{gear_tmp_dir}")
      end
    end

    # Executes a block, trapping ShellExecutionExceptions and treating them
    # as warnings. Any other exceptions are unexpected and will bubble out.
    def tidy_action
      begin
        yield
      rescue OpenShift::Utils::ShellExecutionException => e
        @logger.warn(%Q{
          Tidy operation failed on gear #{@uuid}: #{e.message}
          --- stdout ---\n#{e.stdout}
          --- stderr ---\n#{e.stderr}
          })
      end
    end

    def update_namespace(cart_name, old_namespace, new_namespace)
      cart_model.update_namespace(cart_name, old_namespace, new_namespace)
    end

    def connector_execute(cart_name, connector, args)
      cart_model.connector_execute(cart_name, connector, args)
    end

    def deploy_httpd_proxy(cart_name)
      cart_model.deploy_httpd_proxy(cart_name)
    end

    def remove_httpd_proxy(cart_name)
      cart_model.remove_httpd_proxy(cart_name)
    end

    def restart_httpd_proxy(cart_name)
      cart_model.restart_httpd_proxy(cart_name)
    end

    def move(cart_name, idle)
      cart_model.move(cart_name, idle)
    end

    def pre_move(cart_name)
      cart_model.pre_move(cart_name)
    end

    def post_move(cart_name)
      cart_model.post_move(cart_name)
    end

    # === Cartridge control methods

    # start gear
    # Throws ShellExecutionException on failure
    def start(cart_name)
      @state.value = OpenShift::State::STARTED
      cart_model.do_control("start", cart_name)
    end

    # stop gear
    def stop(cart_name)
      @state.value = OpenShift::State::STOPPED
      cart_model.do_control("stop", cart_name)
    end

    # build application
    def build(cart_name)
      @state.value = OpenShift::State::BUILDING
      cart_model.do_control("build", cart_name)
    end

    # deploy application
    def deploy(cart_name)
      @state.value = OpenShift::State::DEPLOYING
      cart_model.do_control("deploy", cart_name)
    end

    # restart gear as supported by cartridges
    def restart(cart_name)
      cart_model.do_control("restart", cart_name)
    end

    # reload gear as supported by cartridges
    def reload(cart_name)
      cart_model.do_control("reload", cart_name)
    end

    # restore gear from tar ball
    def restore(cart_name)
      raise NotImplementedError("restore")
    end

    # write gear to tar ball
    def snapshot(cart_name)
      raise NotImplementedError("snapshot")
    end

    def status(cart_name)
      cart_model.do_control("status", cart_name)
    end

    def thread_dump(cart_name)
      cart_model.do_control("threaddump", cart_name)
    end
  end
end
