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
require 'openshift-origin-node'

module OpenShift
  module Container
    module SELinuxContainer
      def container_init
        unless @container_uid
          @container_uid = @container_gid = next_uid
        end
        @mcs_label = Utils::SELinux.get_mcs_label(@container_uid)
      end
      
      def container_create
        skel_dir = @config.get("GEAR_SKEL_DIR") || DEFAULT_SKEL_DIR
        gecos    = @config.get("GEAR_GECOS")     || "OO application container"
        supplementary_groups = @config.get("GEAR_SUPL_GRPS")
        
        notify_observers(:before_unix_user_create)

        cmd = %{useradd -u #{@container_uid} \
                -d #{@container_dir} \
                -s #{@gear_shell} \
                -c '#{gecos}' \
                -m \
                -k #{skel_dir} \
                #{@uuid}}
        if supplementary_groups != ""
          cmd << %{ -G "#{supplementary_groups}"}
        end
        out,err,rc = shellCmd(cmd)
        raise UserCreationException.new(
                "ERROR: unable to create user account(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                ) unless rc == 0

        PathUtils.oo_chown("root", @uuid, @container_dir)
        FileUtils.chmod 0o0750, @container_dir

        if @config.get("CREATE_APP_SYMLINKS").to_i == 1
          unobfuscated = File.join(File.dirname(@container_dir),"#{@container_name}-#{@namespace}")
          if not File.exists? unobfuscated
            FileUtils.ln_s File.basename(@container_dir), unobfuscated, :force=>true
          end
        end

        out,err,rc = shellCmd("service cgconfig status > /dev/null 2>&1")
        if rc == 0
          out,err,rc = shellCmd("/usr/sbin/oo-admin-ctl-cgroups startuser #{@uuid} > /dev/null")
          raise OpenShift::UserCreationException.new("Unable to setup cgroups for #{@uuid}: stdout -- #{out} stderr --#{err}}") unless rc == 0
        end
        notify_observers(:after_unix_user_create)
      end
      
      def container_destroy
        # These calls and their order is designed to release pam_namespace's
        #   locks on .tmp and .sandbox. Change then at your peril.
        #
        # 1. Kill off the easy processes
        # 2. Lock down the user from creating new processes (cgroups freeze, nprocs 0)
        # 3. Attempt to move any processes that didn't die into state 'D' (re: cgroups freeze)
        kill_procs(@container_uid)
        
        cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{@uuid} 0 0 0"
        out,err,rc = shellCmd(cmd)
        raise OpenShift::UserCreationException.new("Unable to setup pam/fs/nproc limits for #{@uuid}") unless rc == 0
        
        out,err,rc = shellCmd("service cgconfig status > /dev/null")
        if rc == 0
          shellCmd("/usr/sbin/oo-admin-ctl-cgroups freezeuser #{@uuid} > /dev/null") if rc == 0
        end

        last_access_dir = OpenShift::Config.instance.get("LAST_ACCESS_DIR")
        shellCmd("rm -f #{last_access_dir}/#{@uuid} > /dev/null")
        
        kill_procs(@container_uid)

        purge_sysvipc(uuid)
        container_port_proxy_setup

        if @config.get("CREATE_APP_SYMLINKS").to_i == 1
          Dir.foreach(File.dirname(@container_dir)) do |dent|
            unobfuscate = File.join(File.dirname(@container_dir), dent)
            if (File.symlink?(unobfuscate)) &&
                (File.readlink(unobfuscate) == File.basename(@container_dir))
              File.unlink(unobfuscate)
            end
          end
        end

        OpenShift::FrontendHttpServer.new(@uuid,@container_name,@namespace).destroy

        dirs = list_home_dir(@container_dir)
        cmd = "userdel -f \"#{@uuid}\""
        out,err,rc = shellCmd(cmd)
        raise UserDeletionException.new(
              "ERROR: unable to destroy user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
              ) unless rc == 0

        # 1. Don't believe everything you read on the userdel man page...
        # 2. If there are any active processes left pam_namespace is not going
        #      to let polyinstantiated directories be deleted.
        FileUtils.rm_rf(@container_dir)
        if File.exists?(@container_dir)
          # Ops likes the verbose verbage
          logger.warn %Q{
1st attempt to remove \'#{@container_dir}\' from filesystem failed.
Dir(before)   #{@uuid}/#{@container_uid} => #{dirs}
Dir(after)    #{@uuid}/#{@container_uid} => #{list_home_dir(@container_dir)}
          }
        end

        # release resources (cgroups thaw), this causes Zombies to get killed
        # out,err,rc = shellCmd("service cgconfig status > /dev/null")
        shellCmd("/usr/sbin/oo-admin-ctl-cgroups thawuser #{@uuid} > /dev/null") if rc == 0
        shellCmd("/usr/sbin/oo-admin-ctl-cgroups stopuser #{@uuid} > /dev/null") if rc == 0

        cmd = "/bin/sh #{File.join("/usr/libexec/openshift/lib", "teardown_pam_fs_limits.sh")} #{@uuid}"
        out,err,rc = shellCmd(cmd)
        raise OpenShift::UserCreationException.new("Unable to teardown pam/fs/nproc limits for #{@uuid}") unless rc == 0
        
        notify_observers(:after_unix_user_destroy)

        # try one last time...
        if File.exists?(@container_dir)
          sleep(5)                    # don't fear the reaper
          FileUtils.rm_rf(@container_dir)   # This is our last chance to nuke the polyinstantiated directories
          logger.warn("2nd attempt to remove \'#{@homedir}\' from filesystem failed.") if File.exists?(@container_dir)
        end
      end

      def container_force_stop
        kill_procs(@container_uid)
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
        OpenShift::Utils::oo_spawn(command, options)
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
        options[:uid] = @container_uid
        options[:selinux_context] = OpenShift::Utils::SELinux.context_from_defaults(@mcs_label)
        OpenShift::Utils::oo_spawn(command, options)
      end
      
      def reset_permission(*paths)
        OpenShift::Utils::SELinux.clear_mcs_label(paths)
        OpenShift::Utils::SELinux.set_mcs_label(@mcs_label, paths)
      end
      
      def reset_permission_R(*paths)
        OpenShift::Utils::SELinux.clear_mcs_label_R(paths)
        OpenShift::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
      end
      
      def set_ro_permission_R(*paths)
        PathUtils.oo_chown_R(0, @container_gid, paths)
        OpenShift::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
      end
      
      def set_ro_permission(*paths)
        PathUtils.oo_chown(0, @container_gid, paths)
        OpenShift::Utils::SELinux.set_mcs_label(@mcs_label, paths)
      end
      
      def set_rw_permission_R(*paths)
        PathUtils.oo_chown_R(@container_uid, @container_gid, paths)
        OpenShift::Utils::SELinux.set_mcs_label_R(@mcs_label, paths)
      end
      
      def set_rw_permission(*paths)
        PathUtils.oo_chown(@container_uid, @container_gid, paths)
        OpenShift::Utils::SELinux.set_mcs_label(@mcs_label, paths)
      end
      
      def container_create_interface(private_ip)
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
        raise "Invalid UID specified" unless @container_uid && @container_uid.is_a?(Integer)

        if @container_uid.to_i < 0 || @container_uid.to_i > 262143
          raise "User uid #{@container_uid} is outside the working range 0-262143"
        end

        if host_id < 1 || host_id > 127
          raise "Supplied host identifier #{host_id} must be between 1 and 127"
        end

        # Generate an IP (32-bit unsigned) in the user's range
        ip = 0x7F000000 + (@container_uid.to_i << 7)  + host_id

        # Return the IP in dotted-quad notation
        "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}"
      end

      # Deterministically constructs a network and netmask for the given UID
      #
      # The global user IP range begins at 0x7F000000.
      #
      # Returns an IP network and netmask in dotted-quad notation.
      def get_ip_network(uid)
        raise "Invalid UID specified" unless uid && uid.is_a?(Integer)

        if uid.to_i < 0 || uid.to_i > 262143
          raise "User uid #{@uid} is outside the working range 0-262143"
        end
        # Generate the network (32-bit unsigned) for the user's range
        ip = 0x7F000000 + (uid.to_i << 7)

        # Return the network/netmask in dotted-quad notation
        [ "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}", "255.255.255.128" ]
      end
      
      private
      
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
      def kill_procs(id)
        if id.nil? or id == ""
          raise ArgumentError, "Supplied ID must be a uid."
        end

        # Give it a good try to delete all processes.
        # This abuse is neccessary to release locks on polyinstantiated
        #    directories by pam_namespace.
        out = err = rc = nil
        10.times do |i|
          OpenShift::Utils::ShellExec.shellCmd(%{/usr/bin/pkill -9 -u #{id}})
          out,err,rc = OpenShift::Utils::ShellExec.shellCmd(%{/usr/bin/pgrep -u #{id}})
          break unless 0 == rc

          NodeLogger.logger.error "ERROR: attempt #{i}/10 there are running \"killed\" processes for #{id}(#{rc}): stdout: #{out} stderr: #{err}"
          sleep 0.5
        end

        # looks backwards but 0 implies processes still existed
        if 0 == rc
          out,err,rc = OpenShift::Utils::ShellExec.shellCmd("ps -u #{@uid} -o state,pid,ppid,cmd")
          NodeLogger.logger.error "ERROR: failed to kill all processes for #{id}(#{rc}): stdout: #{out} stderr: #{err}"
        end
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
      def purge_sysvipc(id)
        if id.nil? or id == ""
          raise ArgumentError.new("Supplied ID must be a user name or uid.")
        end

        ['-m', '-q', '-s' ].each do |ipctype|
          out,err,rc=shellCmd(%{/usr/bin/ipcs -c #{ipctype} 2> /dev/null})
          out.lines do |ipcl|
            next unless ipcl=~/^\d/
            ipcent = ipcl.split
            if ipcent[2] == id
              # The ID may already be gone
              shellCmd(%{/usr/bin/ipcrm #{ipctype} #{ipcent[0]}})
            end
          end
        end
      end

      # Private: Determine next available user id.  This is usually determined
      #           and provided by the broker but is auto determined if not
      #           provided.
      #
      # Examples:
      #   next_uid =>
      #   # => 504
      #
      # Returns Integer value for next available uid.
      def next_uid
        uids = IO.readlines("/etc/passwd").map{ |line| line.split(":")[2].to_i }
        gids = IO.readlines("/etc/group").map{ |line| line.split(":")[2].to_i }
        min_uid = (@config.get("GEAR_MIN_UID") || "500").to_i
        max_uid = (@config.get("GEAR_MAX_UID") || "1500").to_i

        (min_uid..max_uid).each do |i|
          if !uids.include?(i) and !gids.include?(i)
            return i
          end
        end
      end

      

    end
  end
end
