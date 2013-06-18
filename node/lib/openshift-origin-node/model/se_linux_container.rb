module OpenShift
  module Runtime
    module ApplicationContainerPlugin
      class SELinuxContainer
        include OpenShift::Runtime::Utils::ShellExec

        def initialize(application_container)
          @container = application_container
          @config    = OpenShift::Config.new
          @mcs_label = OpenShift::Runtime::Utils::SELinux.get_mcs_label(@container.uid)
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
          cmd = %{useradd -u #{@container.uid} \
                  -d #{@container.container_dir} \
                  -s #{@container.shell} \
                  -c '#{@container.gecos}' \
                  -m \
                  -k #{@container.skel_dir} \
                #{@container.uuid}}
          if @container.supplementary_groups != ""
            cmd << %{ -G "#{@container.supplementary_groups}"}
          end
          out,err,rc = run_in_root_context(cmd)
          raise UserCreationException.new(
                    "ERROR: unable to create user account(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                ) unless rc == 0

          set_ro_permission(@container.container_dir)
          FileUtils.chmod 0o0750, @container.container_dir
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
          kill_procs
          freeze_fs_limits
          freeze_cgroups
          last_access_dir = @config.get("LAST_ACCESS_DIR")
          run_in_root_context("rm -f #{last_access_dir}/#{@container.name} > /dev/null")
          kill_procs

          purge_sysvipc
          reset_openshift_port_proxy

          if @config.get("CREATE_APP_SYMLINKS").to_i == 1
            Dir.foreach(File.dirname(@container.container_dir)) do |dent|
              unobfuscate = File.join(File.dirname(@container.container_dir), dent)
              if (File.symlink?(unobfuscate)) &&
                  (File.readlink(unobfuscate) == File.basename(@container.container_dir))
                File.unlink(unobfuscate)
              end
            end
          end

          OpenShift::Runtime::FrontendHttpServer.new(@container).destroy

          dirs = list_home_dir(@container.container_dir)
          cmd = "userdel --remove -f \"#{@container.uuid}\""
          out,err,rc = run_in_root_context(cmd)
          raise UserDeletionException.new(
                    "ERROR: unable to destroy user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
                ) unless rc == 0

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
        def reset_openshift_port_proxy
          proxy_server = FrontendProxyServer.new
          proxy_server.delete_all_for_uid(@container.uid, true)
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
          kill_procs
        end

        def start
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

        def enable_cgroups
          out,err,rc = run_in_root_context("service cgconfig status > /dev/null 2>&1")

          if rc == 0
            out,err,rc = run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups startuser #{@container.uuid} > /dev/null")
            raise OpenShift::Runtime::UserCreationException.new("Unable to setup cgroups for #{@container.uuid}: stdout -- #{out} stderr --#{err}}") unless rc == 0
          end
        end

        def stop_cgroups
          out,err,rc = run_in_root_context("service cgconfig status > /dev/null 2>&1")
          run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups stopuser #{@container.uuid} > /dev/null") if rc == 0
        end

        def enable_fs_limits
          cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{@container.uuid} #{@container.quota_blocks ? @container.quota_blocks : ''} #{@container.quota_files ? @container.quota_files : ''}"
          out,err,rc = run_in_root_context(cmd)
          raise OpenShift::Runtime::UserCreationException.new("Unable to setup pam/fs limits for #{@container.name}: stdout -- #{out} stderr -- #{err}") unless rc == 0
        end

        def disable_fs_limits
          cmd = "/bin/sh #{File.join("/usr/libexec/openshift/lib", "teardown_pam_fs_limits.sh")} #{@container.uuid}"
          out,err,rc = run_in_root_context(cmd)
          raise OpenShift::Runtime::UserCreationException.new("Unable to teardown pam/fs/nproc limits for #{@container.uuid}") unless rc == 0
        end

        # run_in_root_context(command, [, options]) -> [stdout, stderr, exit status]
        #
        # Executes specified command and return its stdout, stderr and exit status.
        # Or, raise exceptions if certain conditions are not met.
        #
        # command: command line string which is passed to the standard shell
        #
        # options: hash
        #   :env: hash
        #     name => val : set the environment variable
        #     name => nil : unset the environment variable
        #   :unsetenv_others => true   : clear environment variables except specified by :env
        #   :chdir => path             : set current directory when running command
        #   :expected_exitstatus       : An Integer value for the expected return code of command
        #                              : If not set spawn() returns exitstatus from command otherwise
        #                              : raise an error if exitstatus is not expected_exitstatus
        #   :timeout                   : Maximum number of seconds to wait for command to finish. default: 3600
        #   :out                       : If specified, STDOUT from the child process will be redirected to the
        #                                provided +IO+ object.
        #   :err                       : If specified, STDERR from the child process will be redirected to the
        #                                provided +IO+ object.
        #
        # NOTE: If the +out+ or +err+ options are specified, the corresponding return value from +oo_spawn+
        # will be the incoming/provided +IO+ objects instead of the buffered +String+ output. It's the
        # responsibility of the caller to correctly handle the resulting data type.
        def run_in_root_context(command, options = {})
          options.delete(:uid)
          options.delete(:selinux_context)
          OpenShift::Runtime::Utils::oo_spawn(command, options)
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
          options[:selinux_context] = OpenShift::Runtime::Utils::SELinux.context_from_defaults(@mcs_label)
          OpenShift::Runtime::Utils::oo_spawn(command, options)
        end

        def reset_permission(*paths)
          OpenShift::Runtime::Utils::SELinux.clear_mcs_label(paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label(@mcs_label, paths)
        end

        def reset_permission_R(*paths)
          OpenShift::Runtime::Utils::SELinux.clear_mcs_label_R(paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
        end

        def set_ro_permission_R(*paths)
          PathUtils.oo_chown_R(0, @container.gid, paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
        end

        def set_ro_permission(*paths)
          PathUtils.oo_chown(0, @container.gid, paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label(@mcs_label, paths)
        end

        def set_rw_permission_R(*paths)
          PathUtils.oo_chown_R(@container.uid, @container.gid, paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
        end

        def set_rw_permission(*paths)
          PathUtils.oo_chown(@container.uid, @container.gid, paths)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label(@mcs_label, paths)
        end

        private

        def freeze_fs_limits
          cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{@container.uuid} 0 0 0"
          out,err,rc = run_in_root_context(cmd)
          raise OpenShift::Runtime::UserCreationException.new("Unable to setup pam/fs/nproc limits for #{@container.uuid}") unless rc == 0
        end

        def freeze_cgroups
          out,err,rc = run_in_root_context("service cgconfig status > /dev/null")
          if rc == 0
            run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups freezeuser #{@container.uuid} > /dev/null") if rc == 0
          end
        end

        # release resources (cgroups thaw), this causes Zombies to get killed
        def unfreeze_cgroups
          out,err,rc = run_in_root_context("service cgconfig status > /dev/null")
          run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups thawuser #{@container.uuid} > /dev/null") if rc == 0
        end

        def kill_procs
          # Give it a good try to delete all processes.
          # This abuse is neccessary to release locks on polyinstantiated
          #    directories by pam_namespace.
          out = err = rc = nil
          10.times do |i|
            run_in_root_context(%{/usr/bin/pkill -9 -u #{@container.uid}})
            out,err,rc = run_in_root_context(%{/usr/bin/pgrep -u #{@container.uid}})
            break unless 0 == rc

            NodeLogger.logger.error "ERROR: attempt #{i}/10 there are running \"killed\" processes for #{@container.uid}(#{rc}): stdout: #{out} stderr: #{err}"
            sleep 0.5
          end

          # looks backwards but 0 implies processes still existed
          if 0 == rc
            out,err,rc = run_in_root_context("ps -u #{@container.uid} -o state,pid,ppid,cmd")
            NodeLogger.logger.error "ERROR: failed to kill all processes for #{@container.uid}(#{rc}): stdout: #{out} stderr: #{err}"
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
            out,err,rc=run_in_root_context(%{/usr/bin/ipcs -c #{ipctype} 2> /dev/null})
            out.lines do |ipcl|
              next unless ipcl=~/^\d/
              ipcent = ipcl.split
              if ipcent[2] == @container.uuid
                # The ID may already be gone
                run_in_root_context(%{/usr/bin/ipcrm #{ipctype} #{ipcent[0]}})
              end
            end
          end
        end


      end
    end
  end
end
