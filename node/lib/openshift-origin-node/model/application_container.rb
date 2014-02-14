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
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/node'
require 'openshift-origin-node/model/gear_registry'
require 'openshift-origin-node/model/deployment_metadata'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/model/application_container_ext/environment'
require 'openshift-origin-node/model/application_container_ext/setup'
require 'openshift-origin-node/model/application_container_ext/snapshots'
require 'openshift-origin-node/model/application_container_ext/cartridge_actions'
require 'openshift-origin-node/model/application_container_ext/deployments'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/hourglass'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/tc'
require 'openshift-origin-common'
require 'yaml'
require 'active_model'
require 'json'
require 'rest-client'
require 'openshift-origin-node/utils/managed_files'
require 'timeout'

module OpenShift
  module Runtime
    class UserCreationException < Exception
    end

    class UserDeletionException < Exception
    end

    class GearCreationException < Exception
    end

    # == Application Container
    class ApplicationContainer
      include ActiveModel::Observing
      include NodeLogger
      include ManagedFiles
      include ApplicationContainerExt::Environment
      include ApplicationContainerExt::Setup
      include ApplicationContainerExt::Snapshots
      include ApplicationContainerExt::CartridgeActions
      include ApplicationContainerExt::Deployments

      GEAR_TO_GEAR_SSH = "/usr/bin/ssh -q -o 'BatchMode=yes' -o 'StrictHostKeyChecking=no' -i $OPENSHIFT_APP_SSH_KEY "
      DEFAULT_SKEL_DIR = PathUtils.join(OpenShift::Config::CONF_DIR,"skel")
      $OpenShift_ApplicationContainer_SSH_KEY_MUTEX = Mutex.new

      attr_reader :uuid, :application_uuid, :state, :container_name, :application_name, :namespace, :container_dir,
                  :quota_blocks, :quota_files, :base_dir, :gecos, :skel_dir, :supplementary_groups,
                  :cartridge_model, :container_plugin, :hourglass
      attr_accessor :uid, :gid

      containerization_plugin_gem = ::OpenShift::Config.new.get('CONTAINERIZATION_PLUGIN')
      containerization_plugin_gem ||= 'openshift-origin-container-selinux'

      begin
        require containerization_plugin_gem
      rescue LoadError => e
        raise ArgumentError.new("error loading #{containerization_plugin_gem}: #{e.message}")
      end

      if !::OpenShift::Runtime::Containerization::Plugin.respond_to?(:container_dir)
        raise ArgumentError.new('containerization plugin must respond to container_dir')
      end

      def initialize(application_uuid, container_uuid, user_uid = nil, application_name = nil, container_name = nil,
                     namespace = nil, quota_blocks = nil, quota_files = nil, hourglass = nil)
        @config           = ::OpenShift::Config.new
        @uuid             = container_uuid
        @application_uuid = application_uuid
        @container_name   = container_name
        @application_name = application_name
        @namespace        = namespace
        @quota_blocks     = quota_blocks
        @quota_files      = quota_files
        @base_dir         = @config.get("GEAR_BASE_DIR")
        @skel_dir         = @config.get("GEAR_SKEL_DIR") || DEFAULT_SKEL_DIR
        @supplementary_groups = @config.get("GEAR_SUPPLEMENTARY_GROUPS")
        @hourglass        = hourglass || ::OpenShift::Runtime::Utils::Hourglass.new(3600)

        begin
          user_info = user_uid
          [:uid, :gid, :gecos, :dir].each do |meth|
            if not user_info.respond_to?(meth)
              user_info = Etc.getpwnam(@uuid)
              break
            end
          end
          @uid              = user_info.uid
          @gid              = user_info.gid
          @gecos            = user_info.gecos
          @container_dir    = "#{user_info.dir}/"
          @container_plugin = Containerization::Plugin.new(self)
        rescue ArgumentError => e
          @uid              = user_uid
          @gid              = user_uid
          @gecos            = @config.get("GEAR_GECOS") || "OO application container"
          @container_dir    = Containerization::Plugin.container_dir(self)
          @container_plugin = nil
        end

        @state           = ::OpenShift::Runtime::Utils::ApplicationState.new(self)
        @cartridge_model = V2CartridgeModel.new(@config, self, @state, @hourglass)
      end

      #
      # Public: Return a ApplicationContainer object loaded from the gear_uuid on the system
      #
      # Caveat: the quota information will not be populated.
      #
      def self.from_uuid(container_uuid, hourglass=nil)

        raise ArgumentError, "container_uuid is required!" if container_uuid.nil? or container_uuid.empty?

        pwent = passwd_for(container_uuid)

        env = ::OpenShift::Runtime::Utils::Environ.load(File.join(pwent.dir, '.env', 'OPENSHIFT_{APP,GEAR}_{UUID,NAME,DNS}*'))

        if env['OPENSHIFT_GEAR_DNS'] == nil
          namespace = nil
        else
          namespace = env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,"")
        end

        raise "OPENSHIFT_APP_UUID is missing!" if env["OPENSHIFT_APP_UUID"].nil?
        raise "OPENSHIFT_APP_NAME is missing!" if env["OPENSHIFT_APP_NAME"].nil?
        raise "OPENSHIFT_GEAR_NAME is missing!" if env["OPENSHIFT_GEAR_NAME"].nil?

        ApplicationContainer.new(env["OPENSHIFT_APP_UUID"], container_uuid, pwent, env["OPENSHIFT_APP_NAME"],
                                 env["OPENSHIFT_GEAR_NAME"], namespace, nil, nil, hourglass)
      end

      def self.passwd_for(container_uuid)
        config = ::OpenShift::Config.new
        gecos  = config.get("GEAR_GECOS") || "OO application container"
        pwent  = Etc.getpwnam(container_uuid)
        raise ArgumentError, "Not an OpenShift gear: #{container_uuid}" if pwent.gecos != gecos
        pwent
      end

      def self.exists?(container_uuid)
        passwd_for(container_uuid) rescue false
      end

      def name
        @container_name
      end

      def get_ip_addr(host_id)
        @container_plugin.get_ip_addr(host_id)
      end

      # create gear
      #
      # - model/unix_user.rb
      # context: root
      # @param secret_token     [String]      value of OPENSHIFT_SECRET_TOKEN for application
      # @param generate_app_key [true, false] Should application ssh key be generated?
      # @return [String] output from operations creating gear
      def create(secret_token = nil, generate_app_key = false, create_initial_deployment_dir = true)
        output = ''
        notify_observers(:before_container_create)
        # lock to prevent race condition between create and delete of gear
        PathUtils.flock("/var/lock/oo-create.#{@uuid}") do
          resource             = OpenShift::Runtime::Node.resource_limits
          no_overcommit_active = resource.get_bool('no_overcommit_active', false)
          overcommit_lock_file = "/var/lock/oo-create.overcommit"
          File.open(overcommit_lock_file, File::RDWR|File::CREAT|File::TRUNC, 0600) do |overcommit_lock|
            overcommit_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

            begin
              if no_overcommit_active
                overcommit_lock.flock(File::LOCK_EX)

                nu = OpenShift::Runtime::Node.node_utilization
                if (nu['gears_active_usage_pct'] >= 100)
                  raise GearCreationException.new("ERROR: Node capacity exceeded, unable to create container #{@uuid}")
                end
              end

              @container_plugin = Containerization::Plugin.new(self)
              @container_plugin.create(create_initial_deployment_dir)
            ensure
              overcommit_lock.flock(File::LOCK_UN) if no_overcommit_active
            end
          end

          add_env_var('SECRET_TOKEN', secret_token, true) if secret_token

          output = generate_ssh_key if generate_app_key

          if @config.get("CREATE_APP_SYMLINKS").to_i == 1
            unobfuscated = PathUtils.join(File.dirname(@container_dir), "#{@container_name}-#{@namespace}")
            if not File.exists? unobfuscated
              FileUtils.ln_s File.basename(@container_dir), unobfuscated, :force => true
            end
          end
        end

        notify_observers(:after_container_create)
        output
      end

      # Destroy gear
      #
      # - model/unix_user.rb
      # context: root
      # @param skip_hooks should destroy call the gear's hooks before destroying the gear
      def destroy(skip_hooks=false)
        notify_observers(:before_container_destroy)

        if @uid.nil? or (@container_plugin.nil? or !File.directory?(@container_dir.to_s))
          # gear seems to have been deleted already... suppress any error
          # TODO : remove remaining stuff if it exists, e.g. .httpd/#{uuid}* etc

          remove_app_symlinks(@container_dir)
          FileUtils.rm_rf(@container_dir) if File.directory?(@container_dir)
          return ['', '', 0]
        end

        output  = ''
        errout  = ''
        retcode = -1

        # Don't try to delete a gear that is being scaled-up|created|deleted
        PathUtils.flock("/var/lock/oo-create.#@uuid") do
          begin
            @cartridge_model.each_cartridge do |cart|
              env = ::OpenShift::Runtime::Utils::Environ::for_gear(@container_dir)
              cart.public_endpoints.each do |endpoint|
                output << "NOTIFY_ENDPOINT_DELETE: #{@config.get('PUBLIC_IP')} #{env[endpoint.public_port_name]}\n"
              end
            end
            # possible mismatch across cart model versions
            out, errout, retcode = @cartridge_model.destroy(skip_hooks)
            output << out unless out.nil?
          rescue => e
            logger.warn %Q(Failure while deleting gear #@uuid: #{e.message})
            logger.debug %Q(Failure while deleting gear #@uuid: #{e.message}\n#{e.backtrace.join("\n")})
            output << %q(CLIENT_ERROR: Errors during gear delete. There may be extraneous data left on system.)
          end
          raise UserDeletionException.new %q[ERROR: unable to delete user account (nil)] if @uuid.nil?

          @container_plugin.destroy
          remove_app_symlinks(@container_dir)
        end

        notify_observers(:after_container_destroy)

        return output, errout, retcode
      end

      # Find and remove all symlinks for a gear
      #
      # @param container_dir [String] home dir for gear to cleanup
      def remove_app_symlinks(container_dir)
        if @config.get("CREATE_APP_SYMLINKS").to_i == 1
          Dir.foreach(File.dirname(container_dir)) do |dent|
            unobfuscate = PathUtils.join(File.dirname(container_dir), dent)
            if (File.symlink?(unobfuscate)) &&
                (File.readlink(unobfuscate) == File.basename(container_dir))
              File.unlink(unobfuscate)
            end
          end
        end
      end

      # Public: Sets the app state to "stopped" and causes an immediate forced
      # termination of all gear processes.
      #
      # TODO: exception handling
      def force_stop(options={})
        @state.value = State::STOPPED
        @cartridge_model.create_stop_lock
        @container_plugin.stop(options)
      end

      #
      # Kill processes belonging to this app container.
      #
      # Options:
      #    init_owned:   Only kill processes trees that start with a daemon (rooted in init).
      #    term_delay:   Send SIGTERM first, wait term_delay seconds then send SIGKILL.
      #
      # Note: The init_owned and term_delay parameters are combined to
      # safely kill daemons running in the gear without touching
      # processes being run from outside the gear (ex: git push, cron,
      # node API).
      #
      def kill_procs(options={})
        # Give it a good try to delete all processes.
        # This abuse is necessary to release locks on polyinstantiated
        #    directories by pam_namespace.

        procfilter="-u #{uid}"
        if options[:init_owned]
          procfilter << " -P 1"
        end

        # If the terminate delay is specified, try to terminate processes nicely
        # first and wait for them to die.
        if options[:term_delay]
          ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/pkill #{procfilter}")
          etime = Time.now + options[:term_delay].to_i
          while (Time.now <= etime)
            out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/pgrep #{procfilter}")
            break unless rc == 0
            sleep 0.5
          end
        end

        oldproclist=""
        stuckcount=0
        while stuckcount <= 10
          out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/pkill -9 #{procfilter}")
          break unless rc == 0

          sleep 0.5

          out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/pgrep #{procfilter}")
          if oldproclist == out
            stuckcount += 1
          else
            oldproclist = out
            stuckcount = 0
          end
        end

        out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/pgrep #{procfilter}")
        if rc == 0
          procset = out.split.join(' ')
          logger.error "ERROR: failed to kill all processes for #{uid}: PIDs #{procset}"
        end
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

        env      = ::OpenShift::Runtime::Utils::Environ::for_gear(@container_dir)
        gear_dir = env['OPENSHIFT_HOMEDIR']
        app_name = env['OPENSHIFT_APP_NAME']

        raise 'Missing required env var OPENSHIFT_HOMEDIR' unless gear_dir
        raise 'Missing required env var OPENSHIFT_APP_NAME' unless app_name

        gear_repo_dir = PathUtils.join(gear_dir, 'git', "#{app_name}.git")
        gear_tmp_dir  = PathUtils.join(gear_dir, '.tmp')

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
      # Idles the gear if there is no stop lock and state is not already +STOPPED+.
      #
      # +Note: + stop_lock is created here so Node start up scripts skip idled gears.
      #   stop_lock removed during unidle
      def idle_gear(options={})
        if not stop_lock? and (state.value != State::STOPPED)
          frontend = FrontendHttpServer.new(self)
          frontend.idle
          begin
            output = stop_gear(force: true, term_delay: 30, init_owned: true)
          ensure
            state.value = State::IDLE
          end
          output
        end
      end

      # Unidles the gear
      #
      # @param options [Hash<>] ignored
      # @return [String] output from starting gear
      def unidle_gear(options={})
        output = ''
        OpenShift::Runtime::Utils::Cgroups.new(@uuid).boost do
          # When invoked as gear, state may be set to Started before unidle is called
          frontend = FrontendHttpServer.new(self)
          frontend.unidle if frontend.idle?

          if state.value == State::IDLE
              state.value = State::STARTED
              output      = start_gear
          end
        end
        output
      end

      ##
      # Sets the application state to +STARTED+ and starts the gear. Gear state implementation
      # is model specific, but +options+ is provided to the implementation.
      def start_gear(options={})
        @cartridge_model.start_gear(options)
      end

      ##
      # Sets the application state to +STOPPED+ and stops the gear. Gear stop implementation
      # is model specific, but +options+ is provided to the implementation.
      #
      # Options:
      #    force       Forcibly kill gear processes after cartridges have been stopped.
      #    hot_deploy  if true, don't rotate-out from the web proxy
      #    init        if true, don't rotate-out from the web proxy
      #
      def stop_gear(options={})
        buffer = ''
        if proxy_cartridge = @cartridge_model.web_proxy
          unless options[:hot_deploy] == true or options[:init]
            result = update_proxy_status(cartridge: proxy_cartridge,
                                         action: :disable,
                                         gear_uuid: self.uuid,
                                         persist: false)
            result[:proxy_results].each do |proxy_gear_uuid, result|
              buffer << result[:messages].join("\n")
            end
          end
        end
        buffer << @cartridge_model.stop_gear(options)
        unless buffer.empty?
          buffer.chomp!
          buffer << "\n"
        end
        if options[:force]
          kill_procs(options)
        end
        buffer << stopped_status_attr
        buffer
      end

      def gear_level_tidy_tmp(gear_tmp_dir)
        # Temp dir cleanup
        tidy_action do
          FileUtils.rm_rf(Dir.glob(PathUtils.join(gear_tmp_dir, "*")))
          logger.debug("Cleaned gear temp dir at #{gear_tmp_dir}")
        end
      end

      def gear_level_tidy_git(gear_repo_dir)
        # Git pruning
        tidy_action do
          run_in_container_context('git prune', chdir: gear_repo_dir, expected_exitstatus: 0, timeout: @hourglass.remaining)
          logger.debug("Pruned git directory at #{gear_repo_dir}")
        end

        # Git GC
        tidy_action do
          run_in_container_context('git gc --aggressive', chdir: gear_repo_dir, expected_exitstatus: 0, timeout: @hourglass.remaining)
          logger.debug("Executed git gc for repo #{gear_repo_dir}")
        end
      end

      # Executes a block, trapping ShellExecutionExceptions and treating them
      # as warnings. Any other exceptions are unexpected and will bubble out.
      def tidy_action
        begin
          yield
        rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
          logger.warn(%Q{
            Tidy operation failed on gear #{@uuid}: #{e.message}
            --- stdout ---\n#{e.stdout}
            --- stderr ---\n#{e.stderr}
                      })
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

        params = broker_auth_params

        request = RestClient::Request.new(:method => :get,
                                          :url => url,
                                          :timeout => 30,
                                          :headers => { :accept => 'application/json;version=1.0', :user_agent => 'OpenShift' },
                                          :payload => params)

        response = request.execute

        if 300 <= response.code
          raise response
        end

        gear_groups = JSON.parse(response)

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

      ##
      # Send the deployments to the broker
      #
      def report_deployments(gear_env, options = {})
        broker_addr = @config.get('BROKER_HOST')
        domain = gear_env['OPENSHIFT_NAMESPACE']
        app_name = gear_env['OPENSHIFT_APP_NAME']
        app_uuid = gear_env['OPENSHIFT_APP_UUID']
        url = "https://#{broker_addr}/broker/rest/domain/#{domain}/application/#{app_name}/deployments"

        params = broker_auth_params
        if params
          deployments = calculate_deployments
          params['deployments[]'] = deployments
          params[:application_id] = app_uuid

          begin
            request = RestClient::Request.new(:method => :post,
                                              :url => url,
                                              :timeout => 30,
                                              :headers => { :accept => 'application/json;version=1.6', :user_agent => 'OpenShift' },
                                              :payload => params)

            response = request.execute { |response, request, result| response }
          rescue => e
            options[:out].puts "Failed to report deployment to broker.  This will be corrected on the next git push. Message: #{e.message}" if options[:out]
          else
            if 300 <= response.code
              options[:out].puts "Failed to report deployment to broker.  This will be corrected on the next git push." if options[:out]
            end
          end
        end
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

      def get_cartridge(cart_name)
        @cartridge_model.get_cartridge(cart_name)
      end

      def stop_lock?
        @cartridge_model.stop_lock?
      end

      #
      # Send a fire-and-forget request to the broker to report build analytics.
      #
      def report_build_analytics
        return unless @config.get_bool('REPORT_BUILD_ANALYTICS', true)

        broker_addr = @config.get('BROKER_HOST')
        url         = "https://#{broker_addr}/broker/analytics"

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

      def list_proxy_mappings
        @cartridge_model.list_proxy_mappings
      end

      #
      # Public: Return an enumerator which provides a list of uuids
      # for every OpenShift gear in the system.
      #
      def self.all_uuids(hourglass=nil)
        Enumerator.new do |yielder|
          config = OpenShift::Config.new
          gecos = config.get("GEAR_GECOS") || "OO application container"

          uuids = []
          Etc.passwd do |pwent|
            uuids << pwent.name if pwent.gecos == gecos
          end

          uuids.each do |uuid|
            yielder.yield(uuid)
          end
        end
      end

      #
      # Public: Return an enumerator which provides an ApplicationContainer object
      # for every OpenShift gear in the system.
      #
      # Caveat: the quota information will not be populated.
      #
      def self.all(hourglass=nil, loadenv=true)
        Enumerator.new do |yielder|
          config = OpenShift::Config.new
          gecos = config.get("GEAR_GECOS") || "OO application container"

          # Some duplication with from_uuid; it may be expensive to keep re-parsing passwd.
          # Etc is not reentrent.  Capture the password table in one shot.
          pwents = []
          Etc.passwd do |pwent|
            if pwent.gecos == gecos
              pwents << pwent.clone
            end
          end

          pwents.shuffle.each do |pwent|
            # The path is a performance hack to load only the variables we need
            if loadenv
              env = ::OpenShift::Runtime::Utils::Environ.load(File.join(pwent.dir, '.env', 'OPENSHIFT_{APP,GEAR}_{UUID,NAME,DNS}*'))
              else
              env = {}
            end

            if env['OPENSHIFT_GEAR_DNS'] == nil
              namespace = nil
            else
              namespace = env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,"")
            end

            begin
              a=ApplicationContainer.new(env["OPENSHIFT_APP_UUID"], pwent.name, pwent, env["OPENSHIFT_APP_NAME"],
                                         env["OPENSHIFT_GEAR_NAME"], namespace, nil, nil, hourglass)
            rescue => e
              NodeLogger.logger.error("Failed to instantiate ApplicationContainer for uid #{pwent.uid}/uuid #{env["OPENSHIFT_APP_UUID"]}: #{e}")
              NodeLogger.logger.error("Backtrace: #{e.backtrace}")
            else
              yielder.yield(a)
            end
          end
        end
      end

      ##
      # Returns +true+ if the user's disk block usage meets or exceeds +max_percent+ of
      # the configured block limit, otherwise +false+.
      def disk_usage_exceeds?(max_percent)
        raise 'Percent must be between 1-100 (inclusive)' unless (1..100).member?(max_percent)
        OpenShift::Runtime::Node.check_quotas(@uuid, max_percent).length != 0
      end

      # run_in_container_context(command, [, options]) -> [stdout, stderr, exit status]
      #
      # Executes specified command and return its stdout, stderr and exit status.
      # Or, raise exceptions if certain conditions are not met.
      # The command is as container user in a SELinux context using runuser/runcon.
      # The environment variables are cleared and mys be specified by :env.
      #
      # command: command line string which is passed to the standard shell
      #
      # options: hash
      #   :env: hash
      #     name => val : set the environment variable
      #     name => nil : unset the environment variable
      #   :chdir => path             : set current directory when running command
      #   :expected_exitstatus       : An Integer value for the expected return code of command
      #                              : If not set spawn() returns exitstatus from command otherwise
      #                              : raise an error if exitstatus is not expected_exitstatus
      #   :timeout                   : Maximum number of seconds to wait for command to finish. default: 3600
      #                              : stdin for the command is /dev/null
      #   :out                       : If specified, STDOUT from the child process will be redirected to the
      #                                provided +IO+ object.
      #   :err                       : If specified, STDERR from the child process will be redirected to the
      #                                provided +IO+ object.
      #
      # NOTE: If the +out+ or +err+ options are specified, the corresponding return value from +run_in_container_context+
      # will be the incoming/provided +IO+ objects instead of the buffered +String+ output. It's the
      # responsibility of the caller to correctly handle the resulting data type.
      def run_in_container_context(command, options = {})
        @container_plugin.run_in_container_context(command, options)
      end

      def reset_permission(paths)
        @container_plugin.reset_permission(paths)
      end

      def reset_permission_R(paths)
        @container_plugin.reset_permission_R(paths)
      end

      def set_ro_permission_R(paths)
        @container_plugin.set_ro_permission_R(paths)
      end

      def set_ro_permission(paths)
        @container_plugin.set_ro_permission(paths)
      end

      def set_rw_permission_R(paths)
        @container_plugin.set_rw_permission_R(paths)
      end

      def set_rw_permission(paths)
        @container_plugin.set_rw_permission(paths)
      end

      def chcon(path, label = nil, type=nil, role=nil, user=nil)
        @container_plugin.chcon(path, label, type, role, user)
      end

      def memory_in_bytes
        @container_plugin.memory_in_bytes(@uuid)
      end

      def address_bound?(ip, port, hourglass, ignoreClosed=false)
        @container_plugin.address_bound?(ip, port, hourglass, ignoreClosed)
      end

      def addresses_bound?(addresses, hourglass, ignoreClosed=false)
        @container_plugin.addresses_bound?(addresses, hourglass, ignoreClosed)
      end

      def gear_registry
        if @gear_registry.nil? and @cartridge_model.web_proxy
          @gear_registry = ::OpenShift::Runtime::GearRegistry.new(self)
        end

        @gear_registry
      end

      protected

      def broker_auth_params
        auth_token = PathUtils.join(@config.get('GEAR_BASE_DIR'), uuid, '.auth', 'token')
        auth_iv = PathUtils.join(@config.get('GEAR_BASE_DIR'), uuid, '.auth', 'iv')
        if File.exist?(auth_token) && File.exist?(auth_iv)
          params = {
            'broker_auth_key' => File.read(auth_token).chomp,
            'broker_auth_iv' => File.read(auth_iv).chomp
          }
        else
          params = nil
        end
        params
      end

      #
      # Invokes all the cartridges bin/metrics + metrics action hook
      #
      def metrics
        @cartridge_model.each do |cart|
          # Do something with these
          result, error, exit_status  = oo_spawn(cart.path + "bin/metrics")
        end
      end
    end
  end
end
