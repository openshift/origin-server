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

    attr_reader :uuid, :application_uuid, :user

    def initialize(application_uuid, container_uuid, user_uid = nil,
        app_name = nil, container_name = nil, namespace = nil, quota_blocks = nil, quota_files = nil, logger = nil)
      @logger = logger ||= Logger.new(STDOUT)

      @config = OpenShift::Config.new

      @uuid = container_uuid
      @application_uuid = application_uuid
      @user = UnixUser.new(application_uuid, container_uuid, user_uid,
        app_name, container_name, namespace, quota_blocks, quota_files)
      @state = OpenShift::Utils::ApplicationState.new(container_uuid)

      # smells
      @cart_model = nil
    end

    def name
      @uuid
    end

    def cart_model
      unless @cart_model
        @cart_model = (OpenShift::Utils::Sdk.is_new_sdk_app(@user.homedir)) ? V2CartridgeModel.new(@config, @user) : V1CartridgeModel.new(@config, @user)
      end

      @cart_model
    end

    def add_cart(cart)
      # TODO: figure out when to mark app as v2 sdk
      OpenShift::Utils::Sdk.mark_new_sdk_app(@user.homedir)

      cart_model.add_cart(cart)
    end

    def remove_cart(cart)
      cart_model.remove_cart(cart)
    end

    # Create gear - model/unix_user.rb
    def create
      notify_observers(:before_container_create)
      @user.create
      notify_observers(:after_container_create)
    end

    # Destroy gear - model/unix_user.rb
    def destroy(skip_hooks=false)
      notify_observers(:before_container_destroy)

      # possible mismatch across cart model versions
      output, errout, retcode = cart_model.destroy

      notify_observers(:after_container_destroy)

      return output, errout, retcode
    end

    # Public: Fetch application state from gear.
    # Returns app state as string on Success and 'unknown' on Failure
    def get_app_state
      @state.get
    end

    # Public: Sets the application state.
    #
    # new_state - The new state to assign. Must be an ApplicationContainer::State.
    def set_app_state(new_state)
      @start.set new_state
    end

    # Public: Sets the app state to "stopped" and causes an immediate forced 
    # termination of all gear processes.
    #
    # TODO: exception handling
    def force_stop
      @state.set(ApplicationState::State::STOPPED)
      UnixUser.kill_procs(@user.uid)
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

      env = load_env
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
      begin
        # Stop the gear. If this fails, consider the tidy a failure.
        out, err, rc = shellCmd("/usr/sbin/oo-admin-ctl-gears stopgear #{@user.uuid}", gear_dir, false, 0)
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
      begin
        # Start the gear, and if that fails raise an exception, as the app is now
        # in a bad state.
        out, err, rc = shellCmd("/usr/sbin/oo-admin-ctl-gears startgear #{@user.uuid}", gear_dir)
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
        run_as(@user.uid, @user.gid, "git prune", gear_repo_dir, false, 0)
        @logger.debug("Pruned git directory at #{gear_repo_dir}. Output:\n#{out}")
      end

      # Git GC
      tidy_action do
        OpenShift::Utils::ShellExec.run_as(@user.uid, @user.gid, "git gc --aggressive", gear_repo_dir, false, 0)
        @logger.debug("Executed git gc for repo #{gear_repo_dir}. Output:\n#{out}")
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

    # Creates an endpoint for the given cart within a gear. The flow is:
    #
    # 1. Extract the Endpoint metadata from the cart manifest.
    # 2. For each endpoint:
    #   a. Compute the internal name for the endpoint (OPENSHIFT_{CART_NS}_{ENDPOINT_NAME}).
    #   b. Attempt to create a proxy mapping for the endpoint via FrontendProxyServer.
    #   c. Create an environment variable for the endpoint name with a value of
    #      the mapped proxy port assigned from (b).
    #
    # Returns nil on success, and raises an exception if the manifest can't be parsed
    # or if any individual endpoint creation fails for any reason.
    def create_endpoints(cart)
      env = load_env

      # Load the manifest for the cartridge
      begin
        manifest = get_cart_manifest(cart)
      rescue => e
        @logger.error(%Q{Failed to parse manifest for cart #{cart} in gear #{@uuid}: #{e.message}
          #{e.backtrace}
          })
        raise "Couldn't create endpoints for cart #{cart} in gear #{@uuid}"
      end

      endpoints = manifest["Endpoints"]

      # Nothing to do if no endpoints are defined in the manifest
      if endpoints == nil
        @logger.info("No Endpoints present in manifest for cart #{cart} in gear #{@uuid}; endpoint creation skipped")
        return
      end
     
      proxy = OpenShift::FrontendProxyServer.new(@logger)
      cart_ip = get_cart_ip(env, cart)
      
      endpoints.each do |endpoint|
        begin
          # Yank the specific info from the endpoint Hash
          name = endpoint.flatten[0]
          port = endpoint.flatten[1]

          # Compute the endpoint name
          cart_ns = self.class.cart_name_to_namespace(cart)
          endpoint_name = "OPENSHIFT_#{cart_ns}_#{name}"

          # Attempt the actual proxy mapping assignment
          proxy_port = proxy.add(@user.uid, cart_ip, port)

          # Create an env var for the endpoint
          @user.add_env_var(endpoint_name, proxy_port)

          @logger.info("Created endpoint #{endpoint_name}=#{cart_ip}:#{proxy_port} for cart #{cart} on gear #{@uuid}")
        rescue => e
          @logger.error(%Q{Failed to create endpoint #{endpoint} for cart #{cart} in gear #{@uuid}: #{e.message}
            #{e.backtrace}
            })
          raise "Couldn't create endpoint #{endpoint} for cart #{cart} in gear #{@uuid}"
        end
      end
    end

    # Deletes all endpoints for the given cart based on the cartridge manifest
    # Endpoint entries and cleans up the related environment variables from
    # the gear.
    #
    # Returns nil on success, and raises an exception if the manifest can't be parsed.
    # Any failed deletes will be logged and skipped.
    def delete_endpoints(cart)
      env = load_env

      # Load the manifest for the cartridge
      begin
        manifest = get_cart_manifest(cart)
      rescue => e
        @logger.error(%Q{Failed to parse manifest for cart #{cart} in gear #{@uuid}: #{e.message}
          #{e.backtrace}
          })
        raise "Couldn't delete endpoints for cart #{cart} in gear #{@uuid}"
      end

      endpoints = manifest["Endpoints"]

      # Nothing to do if no endpoints are defined in the manifest
      if endpoints == nil
        @logger.info("No Endpoints present in manifest for cart #{cart} in gear #{@uuid}; endpoint deletion skipped")
        return
      end

      proxy = OpenShift::FrontendProxyServer.new(@logger)
      cart_ip = get_cart_ip(env, cart)

      proxy_ports = []
      endpoint_vars = []

      # Gather endpoint metadata
      endpoints.each do |endpoint|
        name = endpoint.flatten[0]
        port = endpoint.flatten[1]

        # Compute the endpoint name
        cart_ns = self.class.cart_name_to_namespace(cart)
        endpoint_name = "OPENSHIFT_#{cart_ns}_#{name}"

        endpoint_vars << endpoint_name

        proxy_port = proxy.find_mapped_proxy_port(@user.uid, cart_ip, port)

        if proxy_port != nil
          proxy_ports << proxy_port
        end
      end

      begin
        # Remove the proxy entries
        rc = proxy.delete_all(proxy_ports, true)
        @logger.info(%Q{Deleted #{endpoints.length} endpoints for cart #{cart} in gear #{@uuid}
          Endpoints: #{endpoints}
          Proxy ports: #{proxy_ports}
          })
      rescue => e
        @logger.warn(%Q{Couldn't delete all endpoints for cart #{cart} in gear #{@uuid}: #{e.message}
          Endpoints: #{endpoints}
          Proxy ports: #{proxy_ports}
          #{e.backtrace}
          })
      end

      # Clean up the environment variables
      endpoint_vars.each { |var| @user.remove_env_var(var) }
    end

    # Resolves, loads, and returns the given cartridge manifest as a YAML object.
    #
    # Raises an exception on error.
    def get_cart_manifest(cart)
      cart_model.get_manifest(cart)
      # replaces:
      # manifest_path = File.join(@config.get("CARTRIDGE_BASE_PATH"), cart, "info", "manifest.yml")
      # return YAML.load_file(manifest_path)
    end

    # Compatibility function to resolve a cartridge's IP taking into account the
    # fact that there are two different naming conventions in use from when there
    # was a hard distinction between database and non-database cartridges.
    #
    # The cart IP will be resolved by using a lookup order against the provided
    # environment hash. The order of precedence from most to least preferred is:
    #
    #   1. OPENSHIFT_{CART_NS}_IP
    #   2. OPENSHIFT_{CART_NS}_DB_HOST
    #
    # Returns the IP for the given cart/environment and raises an exception if
    # no preferred key is present in the hash.
    def get_cart_ip(env, cart_name)
      cart_ns = self.class.cart_name_to_namespace(cart_name)

      lookup_order = ["OPENSHIFT_#{cart_ns}_IP", "OPENSHIFT_#{cart_ns}_DB_HOST"]

      lookup_order.each do |lookup|
        return env[lookup] if env.has_key?(lookup)
      end
      
      raise %Q{Couldn't determine IP for cartridge #{cart_name}
        Cart namespace: #{cart_ns}
        Lookup order: #{lookup_order}
        Env: #{env}
      }
    end

    # Public: Load a gears environment variables into the environment
    #
    # Examples
    #
    #   load_env
    #   # => {"OPENSHIFT_APP_NAME"=>"myapp"}
    #
    # Returns env Array
    def load_env
      Utils::Environ::for_gear(user.homedir)
    end

    # Converts a cartridge name to a cartridge namespace.
    #
    # Examples:
    #
    #     cart_name_to_namespace('jbossas-7')
    #     => "JBOSSAS"
    #     cart_name_to_namespace('jenkins-client-1.4')
    #     => "JENKINSCLIENT"
    #
    # Returns the cartridge namespace as a String.
    def self.cart_name_to_namespace(cart)
      return `echo #{cart} | sed 's/-//g' | sed 's/[^a-zA-Z_]*$//g' | tr '[a-z]' '[A-Z]'`.chomp
    end

    # ---------------------------------------------------------------------
    # This code can only be reached by v2 model cartridges

    # start gear
    def start
      do_control("start")
    end

    # stop gear
    def stop
      do_control("stop")
    end

    # restart gear as supported by cartridges
    def restart
      do_control("restart")
    end

    # reload gear as supported by cartridges
    def reload
      do_control("reload")
    end

    # restore gear from tar ball
    def restore
      raise NotImplementedError("restore")
    end

    # write gear to tar ball
    def snapshot
      raise NotImplementedError("snapshot")
    end

    # PRIVATE: execute action using each cartridge's control script in gear
    # FIXME: need to source hooks in command
    def do_control(action)
      gear_env = Utils::Environ.load(File.join(user.home_dir, ".env"))

      @cart_model.process_cartridges { |path|
        cartridge_env = Utils::Environ.load(File.join(path, "env")).merge(gear_env)

        control       = Files.join(path, "bin", "control")
        unless File.executable?(control)
          raise "Corrupt cartridge: #{control} must exists and be executable"
        end

        command = control + " " + action
        Utils::spawn(cartridge_env, command, user.home_dir)
      }
    end
    # ---------------------------------------------------------------------
  end
end
