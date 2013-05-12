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
require 'openshift-origin-node/model/v1_cart_model'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/model/default_builder'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-common'
require 'yaml'
require 'active_model'
require 'json'
require 'rest-client'
require 'openshift-origin-node/utils/managed_files'

module OpenShift
  class UserCreationException < Exception
  end
  
  class UserDeletionException < Exception
  end
  
  ##
  # @api model
  # Class to represent a Gear on the OpenShift node.
  # @!attribute [r] uuid
  #   @return [String] The UUID of this gear
  # @!attribute [r] application_uuid
  #   @return [String] The UUID of the application that runs on this gear
  # @!attribute [r] state
  #   @return [OpenShift::Utils::ApplicationState] Active state of this gear
  # @!attribute [r] container_name
  #   @return [String] The name of of the application that runs on this gear
  # @!attribute [r] cartridge_model
  #   @return [CartridgeModel] Cartridge API compatibility layer
  class ApplicationContainer
    include OpenShift::Utils::ShellExec
    include ActiveModel::Observing
    include NodeLogger
    include ManagedFiles
    
    @container_provider = nil
    def self.provider=(provider_class)
      @container_provider = provider_class
    end
    
    def self.provider
      @container_provider
    end

    GEAR_TO_GEAR_SSH = "/usr/bin/ssh -q -o 'BatchMode=yes' -o 'StrictHostKeyChecking=no' -i $OPENSHIFT_APP_SSH_KEY "
    attr_reader :uuid, :container_name, :application_uuid, :application_name, :namespace, :state, :container_dir,
        :quota_blocks, :quota_files, :cartridge_model, :container_uid, :container_gid, :base_dir, :gecos
    
    ##
    # Constructor
    #
    # @param application_uuid [String] UUID of the application that runs on this gear
    # @param uuid [String] UUID of this gear
    # @param user_uid [Integer] UID of the user for this gear
    # @param app_name [String] The name of this application
    # @param namespace [String] The domain namespace of the application
    # @param container_name [String] The name of this gear
    # @param quota_blocks [Integer]
    # @param quota_files [Integer]
    # @param logger [Object]
    def initialize(application_uuid, uuid, user_uid = nil,
        app_name = nil, container_name = nil, namespace = nil, quota_blocks = nil, quota_files = nil, logger = nil, user_gid = nil )
      throw "No container model selected" if ApplicationContainer.provider.nil?
      extend ApplicationContainer.provider
      
      @config           = OpenShift::Config.new
      @uuid             = uuid
      @container_name   = container_name
      @basedir          = @config.get("GEAR_BASE_DIR")
      @gear_shell       = @config.get("GEAR_SHELL")
      
      begin
        user_info = Etc.getpwnam(@uuid)
        @container_uid = user_info.uid
        @container_gid = user_info.gid
        @gecos = user_info.gecos
        @container_dir = "#{user_info.dir}/"
      rescue ArgumentError => e
        @container_uid = user_uid
        @container_gid = user_gid || user_uid
        @gecos = nil
        @container_dir = File.join(@basedir,@uuid)
      end
      
      
      @application_uuid = application_uuid
      @application_name = app_name
      @namespace        = namespace
      
      @quota_blocks     = quota_blocks
      @quota_files      = quota_files
      @state            = OpenShift::Utils::ApplicationState.new(uuid, self)
      @build_model      = get_build_model

      # When v2 is the default cartridge format flip the test...
      if @build_model == :v1
        @cartridge_model = V1CartridgeModel.new(@config, self)
      else
        @cartridge_model = V2CartridgeModel.new(@config, @state, self)
      end
      container_init
      NodeLogger.logger.debug("Creating #{@build_model} model for #{uuid}: #{__callee__}")
    end
    
    def name
      @uuid
    end
    
    # create gear
    #
    # - model/unix_user.rb
    # context: root
    def create
      notify_observers(:before_container_create)

      # lock to prevent race condition between create and delete of gear
      uuid_lock_file = "/var/lock/oo-create.#{@uuid}"
      File.open(uuid_lock_file, File::RDWR|File::CREAT, 0o0600) do | uuid_lock |
        uuid_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
        uuid_lock.flock(File::LOCK_EX)

        # Lock to prevent race condition on obtaining a UNIX user uid.
        # When running without districts, there is a simple search on the
        #   passwd file for the next available uid.
        File.open("/var/lock/oo-create", File::RDWR|File::CREAT, 0o0600) do | uid_lock |
          uid_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          uid_lock.flock(File::LOCK_EX)

          container_create
        end
        
        initialize_container_dir
        proxy_server = FrontendProxyServer.new
        proxy_server.delete_all_for_uid(@container_uid, true)

        uuid_lock.flock(File::LOCK_UN)
        File.unlink(uuid_lock_file)
      end
      
      if :v2 == OpenShift::Utils::Sdk.node_default_model(@config)
        Utils::Sdk.mark_new_sdk_app(self)
      end

      notify_observers(:after_container_create)
    end
    
    # Public: Append an SSH key to a users authorized_keys file
    #
    # key - The String value of the ssh key.
    # key_type - The String value of the key type ssh-(rsa|dss)).
    # comment - The String value of the comment to append to the key.
    #
    # Examples
    #
    #   add_ssh_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
    #               'ssh-rsa',
    #               'example@example.com')
    #   # => nil
    #
    # Returns nil on Success or raises on Failure
    def add_ssh_key(key, key_type=nil, comment=nil)
      comment = "" unless comment
      self.class.notify_observers(:before_add_ssh_key, self, key)

      ssh_comment, cmd_entry = get_ssh_key_cmd_entry(key, key_type, comment)

      modify_ssh_keys do |keys|
        keys[ssh_comment] = cmd_entry
      end
      NodeLogger.logger.debug("Created #{@build_model} model for #{@container_uuid}")

      ssh_dir = File.join(@container_dir, ".ssh")
      set_ro_permission_R(ssh_dir)

      self.class.notify_observers(:after_add_ssh_key, self, key)
    end
    
    # Public: Remove all existing SSH keys and add the new ones to a users authorized_keys file.
    #
    # ssh_keys - The Array of ssh keys.
    #
    # Examples
    #
    #   replace_ssh_keys([{'key' => AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...', 'type' => 'ssh-rsa', 'name' => 'key1'}])
    #   # => nil
    #
    # Returns nil on Success or raises on Failure
    def replace_ssh_keys(ssh_keys)
      raise Exception.new('The provided ssh keys do not have the required attributes') unless validate_ssh_keys(ssh_keys)
      
      self.class.notify_observers(:before_replace_ssh_keys, self)
    
      modify_ssh_keys do |keys|
        keys.delete_if{ |k, v| true }
        
        ssh_keys.each do |key|
          ssh_comment, cmd_entry = get_ssh_key_cmd_entry(key['key'], key['type'], key['comment'])
          keys[ssh_comment] = cmd_entry
        end
      end
    
      self.class.notify_observers(:after_replace_ssh_keys, self)
    end

    # Generate the command entry for the ssh key to be written into the authorized keys file
    def get_ssh_key_cmd_entry(key, key_type, comment)
      key_type    = "ssh-rsa" if key_type.to_s.strip.length == 0
      cloud_name  = "OPENSHIFT"
      ssh_comment = "#{cloud_name}-#{@uuid}-#{comment}"
      shell       = @gear_shell || "/bin/bash"
      cmd_entry   = "command=\"#{shell}\",no-X11-forwarding #{key_type} #{key} #{ssh_comment}"
      
      [ssh_comment, cmd_entry]
    end
    
    # validate the ssh keys to check for the required attributes
    def validate_ssh_keys(ssh_keys)
      ssh_keys.each do |key|
        begin
          if key['key'].nil? or key['type'].nil? and key['comment'].nil?
            return false
          end
        rescue Exception => ex
          return false
        end
      end
      return true
    end

    # Public: Remove an SSH key from a users authorized_keys file.
    #
    # key - The String value of the ssh key.
    # comment - The String value of the comment associated with the key.
    #
    # Examples
    #
    #   remove_ssh_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
    #               'example@example.com')
    #   # => nil
    #
    # Returns nil on Success or raises on Failure
    def remove_ssh_key(key, comment=nil)
      self.class.notify_observers(:before_remove_ssh_key, self, key)

      modify_ssh_keys do |keys|
        keys.delete_if{ |k, v| v.include?(key)}
      end

      self.class.notify_observers(:after_remove_ssh_key, self, key)
    end

    # Public: Add an environment variable to a given gear.
    #
    # key - The String value of target environment variable.
    # value - The String value to place inside the environment variable.
    # prefix_cloud_name - The String value to append in front of key.
    #
    # Examples
    #
    #  add_env_var('mysql-5.3')
    #  # => 36
    #
    # Returns the Integer value for how many bytes got written or raises on
    # failure.
    def add_env_var(key, value, prefix_cloud_name = false, &blk)
      env_dir = File.join(@container_dir, '.env/')
      key = "OPENSHIFT_#{key}" if prefix_cloud_name

      filename = File.join(env_dir, key)
      File.open(filename, File::WRONLY|File::TRUNC|File::CREAT) do |file|
        if :v1 == @cartridge_format
          file.write "export #{key}='#{value}'"
        else
          file.write value.to_s
        end
      end
      
      set_ro_permission(filename)

      if block_given?
        blk.call(value)
      end
    end

    # Public: list directories (cartridges) in home directory
    # @param  [String] home directory
    # @return [String] comma separated list of directories
    def list_home_dir(home_dir)
      results = []
      if File.exists?(home_dir)
        Dir.foreach(home_dir) do |entry|
          #next if entry =~ /^\.{1,2}/   # Ignore ".", "..", or hidden files
          results << entry
        end
      end
      results.join(', ')
    end

    # Public: Remove an environment variable from a given gear.
    #
    # key - String name of the environment variable to remove.
    # prefix_cloud_name - String prefix to append to key.
    #
    # Examples
    #
    #   remove_env_var('OPENSHIFT_MONGODB_DB_URL')
    #   # => nil
    #
    # Returns an nil on success and false on failure.
    def remove_env_var(key, prefix_cloud_name=false)
      status = false
      [".env", ".env/.uservars"].each do |path|
        env_dir = File.join(@container_dir,path)
        if prefix_cloud_name
          key = "OPENSHIFT_#{key}"
        end
        env_file_path = File.join(env_dir, key)
        FileUtils.rm_f env_file_path
        status = status ? true : (File.exists?(env_file_path) ? false : true)
      end
      status
    end

    # Public: Add broker authorization keys so gear can communicate with
    #         broker.
    #
    # iv - A String value for the IV file.
    # token - A String value for the token file.
    #
    # Examples
    #   add_broker_auth('ivvalue', 'tokenvalue')
    #   # => ["/var/lib/openshift/UUID/.auth/iv",
    #         "/var/lib/openshift/UUID/.auth/token"]
    #
    # Returns An Array of Strings for the newly created auth files
    def add_broker_auth(iv,token)
      broker_auth_dir=File.join(@container_dir,'.auth')
      FileUtils.mkdir_p broker_auth_dir
      File.open(File.join(broker_auth_dir, 'iv'),
            File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write iv
      end
      File.open(File.join(broker_auth_dir, 'token'),
            File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write token
      end

      FileUtils.chmod(0o0750, broker_auth_dir)
      FileUtils.chmod(0o0640, Dir.glob("#{broker_auth_dir}/*"))
      set_ro_permission_R(broker_auth_dir)
    end

    # Public: Remove broker authentication keys from gear.
    #
    # Examples
    #   remove_broker_auth
    #   # => nil
    #
    # Returns nil on Success and false on Failure
    def remove_broker_auth
      broker_auth_dir=File.join(@container_dir, '.auth')
      FileUtils.rm_rf broker_auth_dir
      File.exists?(broker_auth_dir) ? false : true
    end

    ##
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

        # Only perform an initial build if the manifest explicitly specifies a need,
        # or if a template Git URL is provided and the cart is capable of builds or deploys.
        if cartridge.install_build_required || (template_git_url && cartridge.buildable?)
          gear_script_log = '/tmp/initial-build.log'
          env             = Utils::Environ.for_gear(@container_dir)
  
          logger.info "Executing initial gear prereceive for #{@uuid}"
          run_in_container_context("gear prereceive >>#{gear_script_log} 2>&1",
                         env:                 env,
                         chdir:               @container_dir,
                         expected_exitstatus: 0)

          logger.info "Executing initial gear postreceive for #{@uuid}"
          run_in_container_context("gear postreceive >>#{gear_script_log} 2>&1",
                         env:                 env,
                         chdir:               @container_dir,
                         expected_exitstatus: 0)
        end

        output = @cartridge_model.post_configure(cart_name)
      end
      output
    end

    ##
    # Remove cartridge from gear
    #
    # context: root -> gear user -> root
    # @param cart_name [String] cartridge name
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

    # Destroy gear
    #
    # - model/unix_user.rb
    # context: root
    # @param skip_hooks should destroy call the gear's hooks before destroying the gear
    def destroy(skip_hooks=false)
      notify_observers(:before_container_destroy)

      # possible mismatch across cart model versions
      output, errout, retcode = @cartridge_model.destroy(skip_hooks)
      
      if @container_uid.nil? or (@container_dir.nil? or !File.directory?(@container_dir.to_s))
        # gear seems to have been destroyed already... suppress any error
        # TODO : remove remaining stuff if it exists, e.g. .httpd/#{uuid}* etc
        return nil
      end
      raise UserDeletionException.new(
            "ERROR: unable to destroy user account #{@uuid}"
            ) if @uuid.nil?
      
      Dir.chdir(@basedir) do
        uuid_lock_file = "/var/lock/oo-create.#{@uuid}"
        File.open(uuid_lock_file, File::RDWR|File::CREAT, 0o0600) do | lock |
          lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          lock.flock(File::LOCK_EX)
          
          container_destroy
          
          lock.flock(File::LOCK_UN)
          File.unlink(uuid_lock_file)
        end
      end

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
      container_force_stop
    end

    # Creates public endpoints for the given cart. Public proxy mappings are created via
    # the FrontendProxyServer, and the resulting mapped ports are written to environment
    # variables with names based on the cart manifest endpoint entries.
    #
    # Returns nil on success, or raises an exception if any errors occur: all errors here
    # are considered fatal.
    def create_public_endpoints(cart_name)
      env  = Utils::Environ::for_gear(@container_dir)
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
        public_port = proxy.add(@container_uid, private_ip, endpoint.private_port)

        add_env_var(endpoint.public_port_name, public_port)

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
      env  = Utils::Environ::for_gear(@container_dir)
      cart = @cartridge_model.get_cartridge(cart_name)

      proxy = OpenShift::FrontendProxyServer.new

      public_ports     = []
      public_port_vars = []

      cart.public_endpoints.each do |endpoint|
        # Load the private IP from the gear
        private_ip = env[endpoint.private_ip_name]

        public_port_vars << endpoint.public_port_name

        public_port = proxy.find_mapped_proxy_port(@container_uid, private_ip, endpoint.private_port)

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
      public_port_vars.each { |var| remove_env_var(var) }
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

      env      = Utils::Environ::for_gear(@container_dir)
      gear_dir = env['OPENSHIFT_@container_dir']
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
      @cartridge_model.stop_gear(options)
    end
    
    def idle(options={})
      container_stop(options)
    end

    ##
    # Sets the application state to +STARTED+ and starts the gear. Gear state implementation
    # is model specific, but +options+ is provided to the implementation.
    def start_gear(options={})
      @cartridge_model.start_gear(options)
    end
    
    def unidle(options={})
      container_stop(options)
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
        run_in_container_context("git prune", chdir: gear_repo_dir, expected_exitstatus: 0)
        logger.debug("Pruned git directory at #{gear_repo_dir}")
      end

      # Git GC
      tidy_action do
        run_in_container_context("git gc --aggressive", chdir: gear_repo_dir, expected_exitstatus: 0)
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

    def update_namespace(cart_name, old_namespace, new_namespace)
      @cartridge_model.update_namespace(cart_name, old_namespace, new_namespace)
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

    def pre_receive(options={})
      builder_cartridge = @cartridge_model.builder_cartridge

      if builder_cartridge
        @cartridge_model.do_control('pre-receive',
                                    builder_cartridge,
                                    out: options[:out],
                                    err: options[:err])
      else
        DefaultBuilder.new(self).pre_receive(out:        options[:out],
                                             err:        options[:err],
                                             hot_deploy: options[:hot_deploy])

        @cartridge_model.do_control('pre-receive',
                                    @cartridge_model.primary_cartridge,
                                    out:                       options[:out],
                                    err:                       options[:err],
                                    pre_action_hooks_enabled:  false,
                                    post_action_hooks_enabled: false)
      end
    end

    def post_receive(options={})
      builder_cartridge = @cartridge_model.builder_cartridge

      if builder_cartridge
        @cartridge_model.do_control('post-receive',
                                    builder_cartridge,
                                    out: options[:out],
                                    err: options[:err])
      else
        DefaultBuilder.new(self).post_receive(out:        options[:out],
                                              err:        options[:err],
                                              hot_deploy: options[:hot_deploy])
      end
    end

    def remote_deploy(options={})
      @cartridge_model.do_control('process-version',
                                  @cartridge_model.primary_cartridge,
                                  pre_action_hooks_enabled:  false,
                                  post_action_hooks_enabled: false,
                                  out:                       options[:out],
                                  err:                       options[:err])

      start_gear(secondary_only: true,
                 user_initiated: true,
                 hot_deploy:     options[:hot_deploy],
                 out:            options[:out],
                 err:            options[:err])

      deploy(out: options[:out],
             err: options[:err])

      start_gear(primary_only:   true,
                 user_initiated: true,
                 hot_deploy:     options[:hot_deploy],
                 out:            options[:out],
                 err:            options[:err])

      post_deploy(out: options[:out],
                  err: options[:err])

      if options[:init]
        primary_cart_env_dir = File.join(@container_dir, @cartridge_model.primary_cartridge.directory, 'env')
        primary_cart_env     = Utils::Environ.load(primary_cart_env_dir)
        ident                = primary_cart_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
        _, _, version, _     = Runtime::Manifest.parse_ident(primary_cart_env[ident.first])

        @cartridge_model.post_setup(@cartridge_model.primary_cartridge,
                                    version,
                                    out: options[:out],
                                    err: options[:err])

        @cartridge_model.post_install(@cartridge_model.primary_cartridge,
                                      version,
                                      out: options[:out],
                                      err: options[:err])

      end
    end

    ##
    # Implements the following build process:
    #
    #   1. Set the application state to +BUILDING+
    #   2. Run the cartridge +process-version+ control action
    #   3. Run the cartridge +pre-build+ control action
    #   4. Run the +pre-build+ user action hook
    #   5. Run the cartridge +build+ control action
    #   6. Run the +build+ user action hook
    #
    # Returns the combined output of all actions as a +String+.
    def build(options={})
      @state.value = OpenShift::State::BUILDING

      buffer = ''

      buffer << @cartridge_model.do_control('process-version',
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

    ##
    # Implements the following deploy process:
    #
    #   1. Set the application state to +DEPLOYING+
    #   2. Run the web proxy cartridge +deploy+ control action
    #   3. Run the primary cartridge +deploy+ control action
    #   4. Run the +deploy+ user action hook
    #
    # Returns the combined output of all actions as a +String+.
    def deploy(options={})
      @state.value = OpenShift::State::DEPLOYING

      web_proxy_cart = @cartridge_model.web_proxy
      if web_proxy_cart
        @cartridge_model.do_control('deploy',
                                    web_proxy_cart,
                                    pre_action_hooks_enabled: false,
                                    prefix_action_hooks:      false,
                                    out:                      options[:out],
                                    err:                      options[:err])
      end

      @cartridge_model.do_control('deploy',
                                  @cartridge_model.primary_cartridge,
                                  pre_action_hooks_enabled: false,
                                  prefix_action_hooks:      false,
                                  out:                      options[:out],
                                  err:                      options[:err])

    end

    ##
    # Implements the following post-deploy process:
    #
    #   1. Run the cartridge +post-deploy+ action
    #   2. Run the +post-deploy+ user action hook
    def post_deploy(options={})
      @cartridge_model.do_control('post-deploy',
                                  @cartridge_model.primary_cartridge,
                                  pre_action_hooks_enabled: false,
                                  prefix_action_hooks:      false,
                                  out:                      options[:out],
                                  err:                      options[:err])
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
        return "Application or component not running. Cannot reload."
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
        exclusions |= snapshot_exclusions(self,cartridge)
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
      gear_env = Utils::Environ.for_gear(@container_dir)

      gear_groups = get_gear_groups(gear_env)

      get_secondary_gear_groups(gear_groups).each do |type, group|
        $stderr.puts "Saving snapshot for secondary #{type} gear"

        ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
        run_in_container_context("#{GEAR_TO_GEAR_SSH} #{ssh_coords} 'snapshot' > #{type}.tar.gz",
                        env: gear_env,
                        chdir: gear_env['OPENSHIFT_DATA_DIR'],
                        err: $stderr,
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
      gear_env = Utils::Environ.for_gear(@container_dir)

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
                     out: $stdout,
                     chdir: @config.get('GEAR_BASE_DIR'),
                     expected_exitstatus: 0)
    end

    ##
    # Restores a gear from an archive read from STDIN.
    #
    # The operation invoked by this method write output to the client on STDERR.
    def restore(restore_git_repo)
      gear_env = Utils::Environ.for_gear(@container_dir)

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
        transforms |= restore_transforms(self,cartridge)
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
        FileUtils.rm_rf(Dir.glob(File.join(@container_dir, 'git', "#{app_name}.git", '[^h]*', '*')))
      end

      $stderr.puts "Removing old data dir: ~/app-root/data/*"
      FileUtils.rm_rf(Dir.glob(File.join(@container_dir, 'app-root', 'data', '*')))
      FileUtils.rm_rf(Dir.glob(File.join(@container_dir, 'app-root', 'data', '.[^.]*')))
      FileUtils.safe_unlink(File.join(@container_dir, 'app-root', 'runtime', 'data'))
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

      run_in_container_context(tar_cmd, 
                     env: gear_env,
                     out: $stdout,
                     err: $stderr,
                     in: $stdin,
                     chdir: @container_dir,
                     expected_exitstatus: 0)

      FileUtils.cd File.join(@container_dir, 'app-root', 'runtime') do
        FileUtils.ln_s('../data', 'data')
      end
    end

    def handle_scalable_restore(gear_groups, gear_env)
      secondary_groups = get_secondary_gear_groups(gear_groups)

      secondary_groups.each do |type, group|
        $stderr.puts "Restoring snapshot for #{type} gear"

        ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
        run_in_container_context("cat #{type}.tar.gz | #{GEAR_TO_GEAR_SSH} #{ssh_coords} 'restore'",
                        env: gear_env,
                        chdir: gear_env['OPENSHIFT_DATA_DIR'],
                        err: $stderr,
                        expected_exitstatus: 0)
      end
    end

    def status(cart_name)
      @cartridge_model.do_control("status", cart_name)
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
    # Public: Return an ApplicationContainer object loaded from the uuid on the system
    #
    # Caveat: the quota information will not be populated.
    #
    def self.from_uuid(uuid, logger=nil)
      config = OpenShift::Config.new
      gecos = config.get("GEAR_GECOS") || "OO application container"
      pwent = Etc.getpwnam(uuid)
      if pwent.gecos != gecos
        raise ArgumentError, "Not an OpenShift gear: #{gear_uuid}"
      end
      env = Utils::Environ.for_gear(pwent.dir)

      ApplicationContainer.new(env["OPENSHIFT_APP_UUID"], pwent.name, pwent.name,
                               env["OPENSHIFT_APP_NAME"], env["OPENSHIFT_GEAR_NAME"], 
                               env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,""),
                               nil, nil, logger)
    end

    #
    # Public: Return an enumerator which provides an ApplicationContainer object
    # for every OpenShift gear in the system.
    #
    # Caveat: the quota information will not be populated.
    #
    def self.all(logger=nil)
      Enumerator.new do |yielder|
        config = OpenShift::Config.new
        gecos = config.get("GEAR_GECOS") || "OO application container"

        # Some duplication with from_uuid; it may be expensive to keep re-parsing passwd.
        # Etc is not reentrent.  Capture the password table in one shot.
        pwents = []
        Etc.passwd do |pwent|
          pwents << pwent.clone
        end

        pwents.each do |pwent|
          if pwent.gecos == gecos
            begin
              env = Utils::Environ.for_gear(pwent.dir)
              a=ApplicationContainer.new(env["OPENSHIFT_APP_UUID"], pwent.name, pwent.uid,
                                         env["OPENSHIFT_APP_NAME"], env["OPENSHIFT_GEAR_NAME"],
                                         env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,""),
                                         nil, nil, logger)
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

    private

    # Private: Create and populate the users home dir.
    #
    # Examples
    #   initialize_@container_dir
    #   # => nil
    #   # Creates:
    #   # ~
    #   # ~/.tmp/
    #   # ~/.sandbox/$uuid
    #   # ~/.env/
    #   # APP_UUID, GEAR_UUID, APP_NAME, APP_DNS, @container_dir, DATA_DIR, \
    #   #   GEAR_DNS, GEAR_NAME, PATH, REPO_DIR, TMP_DIR, HISTFILE
    #   # ~/app-root
    #   # ~/app-root/data
    #   # ~/app-root/runtime/repo
    #   # ~/app-root/repo -> runtime/repo
    #   # ~/app-root/runtime/data -> ../data
    #
    # Returns nil on Success and raises on Failure.
    def initialize_container_dir
      notify_observers(:before_initialize_container_dir)
      cart_basedir = @config.get("CARTRIDGE_BASE_PATH")      
      @container_dir = @container_dir.end_with?('/') ? @container_dir : @container_dir + '/'

      # Required for polyinstantiated tmp dirs to work
      [".tmp", ".sandbox"].each do |poly_dir|
        full_poly_dir = File.join(@container_dir, poly_dir)
        FileUtils.mkdir_p full_poly_dir
        FileUtils.chmod(0o0000, full_poly_dir)
      end

      # Polydir runs before the marker is created so set up sandbox by hand
      sandbox_uuid_dir = File.join(@container_dir, ".sandbox", @uuid)
      FileUtils.mkdir_p sandbox_uuid_dir
      if @cartridge_format == :v1
        FileUtils.chmod(0o1755, sandbox_uuid_dir)
      else
        PathUtils.oo_chown(@uuid, nil, sandbox_uuid_dir)
      end

      env_dir = File.join(@container_dir, ".env")
      FileUtils.mkdir_p(env_dir)
      FileUtils.chmod(0o0750, env_dir)
      set_ro_permission(env_dir)

      ssh_dir = File.join(@container_dir, ".ssh")
      FileUtils.mkdir_p(ssh_dir)
      FileUtils.chmod(0o0750, ssh_dir)
      set_ro_permission(ssh_dir)

      geardir = File.join(@container_dir, @container_name, "/")
      gearappdir = File.join(@container_dir, "app-root", "/")

      add_env_var("APP_DNS",
                  "#{@application_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("APP_NAME", @application_name, true)
      add_env_var("APP_UUID", @application_uuid, true)

      data_dir = File.join(gearappdir, "data", "/")
      add_env_var("DATA_DIR", data_dir, true) {|v|
        FileUtils.mkdir_p(v, :verbose => @debug)
      }
      add_env_var("HISTFILE", File.join(data_dir, ".bash_history"))
      profile = File.join(data_dir, ".bash_profile")
      File.open(profile, File::WRONLY|File::TRUNC|File::CREAT, 0o0600) {|file|
        file.write %Q{
# Warning: Be careful with modifications to this file,
#          Your changes may cause your application to fail.
}
      }
      set_rw_permission(profile)

      add_env_var("GEAR_DNS",
                  "#{@container_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("GEAR_NAME", @container_name, true)
      add_env_var("GEAR_UUID", @uuid, true)

      add_env_var("HOMEDIR", @container_dir, true)

      # Ensure HOME exists for git support
      add_env_var("HOME", @container_dir, false)

      add_env_var("PATH",
                  "#{cart_basedir}/abstract-httpd/info/bin/:#{cart_basedir}/abstract/info/bin/:/bin:/sbin:/usr/bin:/usr/sbin:/$PATH",
                  false)

      add_env_var("REPO_DIR", File.join(gearappdir, "runtime", "repo", "/"), true) {|v|
        FileUtils.mkdir_p(v, :verbose => @debug)
        FileUtils.cd gearappdir do |d|
          FileUtils.ln_s("runtime/repo", "repo", :verbose => @debug)
        end
        FileUtils.cd File.join(gearappdir, "runtime") do |d|
          FileUtils.ln_s("../data", "data", :verbose => @debug)
        end
      }

      add_env_var("TMP_DIR", "/tmp/", true)
      add_env_var("TMP_DIR", "/tmp/", false)
      add_env_var("TMPDIR", "/tmp/", false)
      add_env_var("TMP", "/tmp/", false)

      # Update all directory entries ~/app-root/*
      Dir[gearappdir + "/*"].entries.reject{|e| [".", ".."].include? e}.each {|e|
        FileUtils.chmod_R(0o0750, e, :verbose => @debug)
        set_rw_permission_R(e)
      }
      set_ro_permission(gearappdir)
      raise "Failed to instantiate gear: missing application directory (#{gearappdir})" unless File.exist?(gearappdir)

      state_file = File.join(gearappdir, "runtime", ".state")
      File.open(state_file, File::WRONLY|File::TRUNC|File::CREAT, 0o0660) {|file|
        file.write "new\n"
      }
      set_rw_permission(state_file)

      OpenShift::FrontendHttpServer.new(@uuid,@container_name,@namespace).create

      # Fix SELinux context for cart dirs
      reset_permission_R(@container_dir)

      cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{@uuid} #{@quota_blocks ? @quota_blocks : ''} #{@quota_files ? @quota_files : ''}"
      out,err,rc = shellCmd(cmd)
      raise OpenShift::UserCreationException.new("Unable to setup pam/fs limits for #{@uuid}: stdout -- #{out} stderr -- #{err}") unless rc == 0
      notify_observers(:after_initialize_container_dir)
    end

    def get_build_model
      # TODO: When v2 is the default cartridge format change this default...
      build_model = :v1

      if @container_dir && File.exist?(@container_dir)
        build_model = :v2 if OpenShift::Utils::Sdk.new_sdk_app?(@container_dir)
      else
        build_model = OpenShift::Utils::Sdk.node_default_model(@config)
      end

      build_model
    end

    @@MODIFY_SSH_KEY_MUTEX = Mutex.new
    # private: Modify ssh authorized_keys file
    #
    # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
    # @return [Hash] authorized keys with the comment field as the key
    def modify_ssh_keys
      authorized_keys_file = File.join(@container_dir, ".ssh", "authorized_keys")
      keys = Hash.new
    
      @@MODIFY_SSH_KEY_MUTEX.synchronize do
        File.open("/var/lock/oo-modify-ssh-keys", File::RDWR|File::CREAT, 0o0600) do | lock |
          lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          lock.flock(File::LOCK_EX)
          begin
            File.open(authorized_keys_file, File::RDWR|File::CREAT, 0o0440) do |file|
              file.each_line do |line|
                begin
                  keys[line.split[-1].chomp] = line.chomp
                rescue
                end
              end
    
              if block_given?
                old_keys = keys.clone
    
                yield keys
    
                if old_keys != keys
                  file.seek(0, IO::SEEK_SET)
                  file.write(keys.values.join("\n")+"\n")
                  file.truncate(file.tell)
                end
              end
            end
            set_ro_permission(authorized_keys_file)
          ensure
            lock.flock(File::LOCK_UN)
          end
        end
      end
      keys
    end
  end
end

# Load plugin gems.
Dir["/etc/openshift/node-plugins.d/*.conf"].delete_if{ |x| x.end_with? "-dev.conf" }.map{|x| File.basename(x, ".conf")}.each {|plugin| require plugin}
