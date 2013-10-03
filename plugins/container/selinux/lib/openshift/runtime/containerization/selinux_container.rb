require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Runtime
    module Containerization
      class Plugin
        include OpenShift::Runtime::NodeLogger

        attr_reader :gear_shell

        def self.container_dir(container)
          File.join(container.base_dir, container.uuid)
        end

        def initialize(application_container)
          @container  = application_container
          @config     = ::OpenShift::Config.new
          @gear_shell = @config.get("GEAR_SHELL")    || "/bin/bash"
        end

        # Public
        #
        # Lazy load the MCS label only when its needed
        def mcs_label
          if not @mcs_label
            if @container.uid
              @mcs_label = ::OpenShift::Runtime::Utils::SELinux.get_mcs_label(@container.uid)
            end
          end
          @mcs_label
        end

        # Public: Create an empty gear.
        #
        # Examples
        #
        #   create
        #   # => nil
        #   # a user
        #   # Setup permissions
        #
        # Returns nil on Success or raises on Failure
        def create
          # Lock to prevent race condition on obtaining a UNIX user uid.
          # When running without districts, there is a simple search on the
          #   passwd file for the next available uid.
          File.open("/var/lock/oo-create", File::RDWR|File::CREAT|File::TRUNC, 0o0600) do | uid_lock |
            uid_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
            uid_lock.flock(File::LOCK_EX)

            unless @container.uid
              @container.uid = @container.gid = @container.next_uid
            end

            cmd = %{useradd -u #{@container.uid} \
                    -d #{@container.container_dir} \
                    -s #{@gear_shell} \
                    -c '#{@container.gecos}' \
                    -m \
                    -k #{@container.skel_dir} \
                    #{@container.uuid}}
            if @container.supplementary_groups != ""
              cmd << %{ -G "#{@container.supplementary_groups}"}
            end
            out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
            raise ::OpenShift::Runtime::UserCreationException.new(
                      "ERROR: unable to create user account(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                  ) unless rc == 0

            set_ro_permission(@container.container_dir)
            FileUtils.chmod 0o0750, @container.container_dir
          end

          enable_cgroups
          enable_traffic_control

          @container.initialize_homedir(@container.base_dir, @container.container_dir)

          enable_fs_limits
          delete_all_public_endpoints
        end

        # Public: Destroys a gear stopping all processes and removing all files
        #
        # The order of the calls and gyrations done in this code is to prevent
        #   pam_namespace from locking polyinstantiated directories during
        #   their deletion. If you see "broken" gears, i.e. ~uuid/.tmp and
        #    ~/uuid/.sandbox after #destroy has been called, this method is broken.
        # See Bug 853582 for history.
        #
        # Examples
        #
        #   destroy
        #   # => nil
        #
        # Returns nil on Success or raises on Failure
        def destroy
          # These calls and their order is designed to release pam_namespace's
          #   locks on .tmp and .sandbox. Change then at your peril.
          #
          # 1. Kill off the easy processes
          # 2. Lock down the user from creating new processes (cgroups freeze, nprocs 0)
          # 3. Attempt to move any processes that didn't die into state 'D' (re: cgroups freeze)
          @container.kill_procs
          freeze_fs_limits
          freeze_cgroups
          disable_traffic_control
          last_access_dir = @config.get("LAST_ACCESS_DIR")
          ::OpenShift::Runtime::Utils::oo_spawn("rm -f #{last_access_dir}/#{@container.name} > /dev/null")
          @container.kill_procs

          purge_sysvipc
          delete_all_public_endpoints

          ::OpenShift::Runtime::FrontendHttpServer.new(@container).destroy

          dirs = list_home_dir(@container.container_dir)
          begin
            cmd = "userdel --remove -f \"#{@container.uuid}\""
            out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
            # Ref man userdel(8) for exit codes.
            case rc
            when 0
            when 6
              logger.debug("Userdel: user does not exist: #{@container.uuid}")
            when 12
              logger.debug("Userdel: could not remove home directory, we will retry: #{@container.uuid}")
            else
              # 1 == cannot update password file.
              # 2 == invalid command syntax.
              # 8 == currently logged in, should not be possible after we kill the pids.
              # 10 == can't update group file
              msg = "ERROR: unable to delete user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
              raise ::OpenShift::Runtime::UserDeletionException.new(msg)
            end
          rescue ArgumentError => e
            logger.debug("user does not exist. ignore.")
          end

          # 1. Don't believe everything you read on the userdel man page...
          # 2. If there are any active processes left pam_namespace is not going
          #      to let polyinstantiated directories be deleted.
          FileUtils.rm_rf(@container.container_dir)
          if File.exists?(@container.container_dir)
            # Ops likes the verbose verbage
            logger.warn %Q{
1st attempt to remove \'#{@container.container_dir}\' from filesystem failed.
Dir(before)   #{@container.uuid}/#{@container.uid} => #{dirs}
Dir(after)    #{@container.uuid}/#{@container.uid} => #{list_home_dir(@container.container_dir)}
            }
          end

          # release resources (cgroups thaw), this causes Zombies to get killed
          unfreeze_cgroups
          stop_cgroups
          disable_fs_limits

          # try one last time...
          if File.exists?(@container.container_dir)
            sleep(5)                    # don't fear the reaper
            FileUtils.rm_rf(@container.container_dir)   # This is our last chance to nuke the polyinstantiated directories
            logger.warn("2nd attempt to remove \'#{@container.container_dir}\' from filesystem failed.") if File.exists?(@container.container_dir)
          end

          [out,err,rc]
        end

        # Private: Kill all processes for a given gear
        #
        # Kill all processes owned by the uid or uuid.
        # No reason for graceful shutdown first, the directories and user are going
        #   to be removed from the system.
        #
        # Examples:
        # kill_gear_procs
        #    => true
        #    pkill -u id
        #
        # Raises exception on error.
        #
        def stop
          @container.kill_procs
        end

        def start
          restore_cgroups
        end

        # Deterministically constructs an IP address for the given UID based on the given
        # host identifier (LSB of the IP). The host identifier must be a value between 1-127
        # inclusive.
        #
        # The global user IP range begins at 0x7F000000.
        #
        # Returns an IP address string in dotted-quad notation.
        def get_ip_addr(host_id)
          raise "Invalid host_id specified" unless host_id && host_id.is_a?(Integer)

          if @container.uid.to_i < 0 || @container.uid.to_i > 262143
            raise "User uid #{@container.uid} is outside the working range 0-262143"
          end

          if host_id < 1 || host_id > 127
            raise "Supplied host identifier #{host_id} must be between 1 and 127"
          end

          # Generate an IP (32-bit unsigned) in the user's range
          ip = 0x7F000000 + (@container.uid.to_i << 7)  + host_id

          # Return the IP in dotted-quad notation
          "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}"
        end

        def create_public_endpoint(private_ip, private_port)
          proxy = ::OpenShift::Runtime::FrontendProxyServer.new
          # Add the public-to-private endpoint-mapping to the port proxy
          public_port = proxy.add(@container.uid, private_ip, private_port)
        end

        def delete_public_endpoints(proxy_mappings)
          proxy = ::OpenShift::Runtime::FrontendProxyServer.new
          proxy.delete_all(proxy_mappings.map{|p| p[:proxy_port]}, true)
        end

        # Public: Initialize OpenShift Port Proxy for this gear
        #
        # The port proxy range is determined by configuration and must
        # produce identical results to the abstract cartridge provided
        # range.
        #
        # Examples:
        # reset_openshift_port_proxy
        #    => true
        #    service openshift_port_proxy setproxy 35000 delete 35001 delete etc...
        #
        # Returns:
        #    true   - port proxy could be initialized properly
        #    false  - port proxy could not be initialized properly
        def delete_all_public_endpoints
          proxy_server = ::OpenShift::Runtime::FrontendProxyServer.new
          proxy_server.delete_all_for_uid(@container.uid, true)
        end

        def enable_cgroups
          ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).create
        end

        def stop_cgroups
          ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).delete
        end

        def enable_traffic_control
          begin
            ::OpenShift::Runtime::Utils::TC.new.startuser(@container.uuid)
          rescue RuntimeError, ArgumentError => e
            raise ::OpenShift::Runtime::UserCreationException.new("Unable to setup tc for #{@container.uuid}")
          end
        end

        def disable_traffic_control
          begin
            ::OpenShift::Runtime::Utils::TC.new.deluser(@container.uuid)
          rescue RuntimeError, ArgumentError => e
          end
        end

        def enable_fs_limits
          ::OpenShift::Runtime::Node.init_quota(@container.uuid, @container.quota_blocks, @container.quota_files)
          ::OpenShift::Runtime::Node.init_pam_limits(@container.uuid)
        end

        def disable_fs_limits
          ::OpenShift::Runtime::Node.remove_pam_limits(@container.uuid)
          ::OpenShift::Runtime::Node.remove_quota(@container.uuid)
        end

        # Returns true if the given IP and port are currently bound
        # according to lsof, otherwise false.
        def address_bound?(ip, port, hourglass)
          _, _, rc = Utils.oo_spawn("/usr/sbin/lsof -i @#{ip}:#{port}", timeout: hourglass.remaining)
          rc == 0
        end

        def addresses_bound?(addresses, hourglass)
          command = "/usr/sbin/lsof"
          addresses.each do |addr|
            command << " -i @#{addr[:ip]}:#{addr[:port]}"
          end

          _, _, rc = Utils.oo_spawn(command, timeout: hourglass.remaining)
          rc == 0
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
        # NOTE: If the +out+ or +err+ options are specified, the corresponding return value from +oo_spawn+
        # will be the incoming/provided +IO+ objects instead of the buffered +String+ output. It's the
        # responsibility of the caller to correctly handle the resulting data type.
        def run_in_container_context(command, options = {})
          require 'openshift-origin-node/utils/selinux'
          options[:unsetenv_others] = true
          options[:uid] = @container.uid
          options[:gid] = @container.gid
          options[:selinux_context] = ::OpenShift::Runtime::Utils::SELinux.context_from_defaults(mcs_label)
          ::OpenShift::Runtime::Utils::oo_spawn(command, options)
        end

        def reset_permission(paths)
          ::OpenShift::Runtime::Utils::SELinux.clear_mcs_label(paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label(mcs_label, paths)
        end

        def reset_permission_R(paths)
          ::OpenShift::Runtime::Utils::SELinux.clear_mcs_label_R(paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(mcs_label, paths)
        end

        def set_ro_permission_R(paths)
          PathUtils.oo_chown_R(0, @container.gid, paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(mcs_label, paths)
        end

        def set_ro_permission(paths)
          PathUtils.oo_chown(0, @container.gid, paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label(mcs_label, paths)
        end

        def set_rw_permission_R(paths)
          PathUtils.oo_chown_R(@container.uid, @container.gid, paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(mcs_label, paths)
        end

        def set_rw_permission(paths)
          PathUtils.oo_chown(@container.uid, @container.gid, paths)
          ::OpenShift::Runtime::Utils::SELinux.set_mcs_label(mcs_label, paths)
        end

        private

        def freeze_fs_limits
          ::OpenShift::Runtime::Node.pam_freeze(@container.uuid)
        end

        def freeze_cgroups
          begin
            cg = ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid)
            cg.freeze
            20.times do
              pids = cg.processes
              if pids.empty?
                return
              else
                Process::Kill("KILL",*pids)
                cg.thaw
                sleep(0.1)
                cg.freeze
              end
            end
          rescue
          end
        end

        # release resources (cgroups thaw), this causes Zombies to get killed
        def unfreeze_cgroups
          begin
            ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).thaw
          rescue
          end
        end

        def restore_cgroups
          begin
            ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).restore
          rescue
          end
        end

        # Private: list directories (cartridges) in home directory
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

        # Private: Purge IPC entities for a given gear
        #
        # Enumerate and remove all IPC entities for a given user ID or
        # user name.
        #
        # Examples:
        # purge_sysvipc
        #    => true
        #    ipcs -c
        #    ipcrm -s id
        #    ipcrm -m id
        #
        # Raises exception on error.
        #
        def purge_sysvipc
          ['-m', '-q', '-s' ].each do |ipctype|
            out,err,rc=::OpenShift::Runtime::Utils::oo_spawn(%{/usr/bin/ipcs -c #{ipctype} 2> /dev/null})
            out.lines do |ipcl|
              next unless ipcl=~/^\d/
              ipcent = ipcl.split
              if ipcent[2] == @container.uuid
                # The ID may already be gone
                ::OpenShift::Runtime::Utils::oo_spawn(%{/usr/bin/ipcrm #{ipctype} #{ipcent[0]}})
              end
            end
          end
        end
      end
    end
  end
end
