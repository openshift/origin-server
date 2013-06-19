require 'openshift-origin-node/utils/node_logger'
require 'ipaddr'

module OpenShift
  module Runtime
    module ApplicationContainerPlugin
      class LibvirtContainer
        include OpenShift::Runtime::Utils::ShellExec
        include OpenShift::Runtime::NodeLogger

        attr_reader :gear_shell, :mcs_label

        def self.container_dir(container)
          File.join(container.base_dir,'gears',container.uuid)
        end

        def initialize(application_container)
          @container  = application_container
          @config     = OpenShift::Config.new
          @gear_shell = "/usr/bin/nsjoin"
          @mcs_label  = OpenShift::Runtime::Utils::SELinux.get_mcs_label(@container.gid)

          @port_begin = (@config.get("PORT_BEGIN") || "35531").to_i
          @ports_per_user = (@config.get("PORTS_PER_USER") || "5").to_i
          @uid_begin = (@config.get("GEAR_MIN_UID") || "500").to_i
          @container_metadata = File.join(@container.base_dir, ".container", @container.uuid)
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
          cmd = %{groupadd -g #{@container.gid} \
          #{@container.uuid}}
          out,err,rc = run_in_root_context(cmd)
          raise UserCreationException.new(
                    "ERROR: unable to create group for user account(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                ) unless rc == 0

          FileUtils.mkdir_p @container.container_dir
          cmd = %{useradd -u #{@container.uid} \
                  -g #{@container.gid} \
                  -d #{@container.container_dir} \
                  -s /bin/bash \
                  -c '#{@container.gecos}' \
                  -m \
                  -N \
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

          FileUtils.mkdir_p(@container_metadata)
          File.open(File.join(File.join(@container_metadata, "container-id")), "w") do |f|
            f.write(@container.uuid)
          end
          File.open(File.join(File.join(@container_metadata, "interfaces.json")), "w") do |f|
            f.write("[]\n")
          end
          set_ro_permission_R(@container_metadata)

          security_field = "static,label=unconfined_u:system_r:openshift_t:#{@mcs_label}"
          external_ip_addr = get_nat_ip_address
          external_ip_mask = get_nat_ip_mask
          route            = @config.get('LIBVIRT_PRIVATE_IP_ROUTE')
          gw               = @config.get('LIBVIRT_PRIVATE_IP_GW')

          cmd = "/usr/bin/virt-sandbox-service create " +
              "-U #{@container.uid} -G #{@container.gid} " +
              "-p #{File.join(@container.base_dir,'gears')} -s #{security_field} " +
              "-N address=#{external_ip_addr}/#{external_ip_mask}," +
              "route=#{route}%#{gw} " +
              "-f openshift_var_lib_t " +
              "-m host-bind:/dev/container-id=#{@container_metadata}/container-id " +
                 "host-bind:/proc/meminfo=/proc/meminfo " +
              " -- " +
              "#{@container.uuid} /usr/sbin/oo-gear-init"
          out, err, rc = run_in_root_context(cmd)
          raise UserCreationException.new( "Failed to create lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0

          container_link = File.join(@container.container_dir, @container.uuid)
          FileUtils.ln_s("/var/lib/openshift/gears", container_link)
          set_ro_permission(container_link)

          start
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
          if File.exist?("/etc/libvirt-sandbox/services/#{@uuid}.sandbox")
            container_stop if container_running?

            out, _, _ = run_in_root_context("/usr/bin/virt-sandbox-service list")
            if out.split("\n").include?(@uuid)
              out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service delete #{@uuid}")
              raise Exception.new( "Failed to delete lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
            end

            FileUtils.rm_rf @container_metadata
          end


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
          delete_public_endpoints

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
          begin
            user = Etc.getpwnam(@container.uuid)

            cmd = "userdel --remove -f \"#{@container.uuid}\""
            out,err,rc = run_in_root_context(cmd)
            raise UserDeletionException.new(
                      "ERROR: unable to destroy user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
                  ) unless rc == 0
          rescue ArgumentError => e
            logger.debug("user does not exist. ignore.")
          end

          begin
            group = Etc.getgrnam(@container.uuid)

            cmd = "groupdel \"#{@container.uuid}\""
            out,err,rc = run_in_root_context(cmd)
            raise UserDeletionException.new(
                      "ERROR: unable to destroy group of user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
                  ) unless rc == 0
          rescue ArgumentError => e
            logger.debug("group does not exist. ignore.")
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
          out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service stop #{@uuid}")
          raise Exception.new( "Failed to stop lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
        end

        def start
          out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service start #{@container.uuid} < /dev/null > /dev/null 2> /dev/null &")
          raise Exception.new( "Failed to start lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0

          #Wait for container to become available
          for i in 1..10
            sleep 1
            begin
              _,_,rc = run_in_container_context("echo 0")
              break if  rc == 0
            rescue => e
              #ignore
            end
          end

          _,_,rc = run_in_container_context("echo 0")
          raise Exception.new( "Failed to start lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0

          reload_network
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

          if host_id < 1 || host_id > 127
            raise "Supplied host identifier #{host_id} must be between 1 and 127"
          end
          "169.254.169." + host_id.to_s
        end

        def create_public_endpoint(private_ip, private_port)
          get_open_proxy_port
        end

        def delete_public_endpoints

        end

        def enable_cgroups
          #out,err,rc = run_in_root_context("service cgconfig status > /dev/null 2>&1")
          #
          #if rc == 0
          #  out,err,rc = run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups startuser #{@container.uuid} > /dev/null")
          #  raise OpenShift::Runtime::UserCreationException.new("Unable to setup cgroups for #{@container.uuid}: stdout -- #{out} stderr --#{err}}") unless rc == 0
          #end
        end

        def stop_cgroups
          #out,err,rc = run_in_root_context("service cgconfig status > /dev/null 2>&1")
          #run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups stopuser #{@container.uuid} > /dev/null") if rc == 0
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

          if options[:env].nil? or options[:env].empty?
            options[:env] = Utils::Environ.for_gear(@container.container_dir)
          end

          if not File.exist?("/dev/container-id")
            command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
            command = "/usr/bin/nsjoin #{@container.uuid} \"#{command}\""
            OpenShift::Runtime::Utils::oo_spawn(command, options)
          else
            options[:uid] = @container.uid
            OpenShift::Runtime::Utils::oo_spawn(command, options)
          end
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

        def set_default_route
          gw = @config.get('LIBVIRT_PRIVATE_IP_GW')
          out, _, _ = run_in_container_root_context(%{ip route show})
          m = out.match(/default via ([\d\.]+) dev eth0 \n/)
          if !m || m[1] != gw
            run_in_container_root_context(%{
              ip route del default;
              ip route add default via #{gw} dev eth0
            })
          end
        end

        def define_dummy_iface
          _, _, rc = run_in_container_root_context(%{ip link show dummy0})
          if rc != 0
            cmd = "ip link add dummy0 type dummy; "
            (1..127).each do |i|
              cmd += "ip addr add 169.254.169.#{i} dev dummy0; "
            end
            run_in_container_root_context(cmd)
          end
        end

        # Returns a Range representing the valid proxy port values
        def port_range
          uid_offset = @container.uid - @uid_begin
          proxy_port_begin = @port_begin + uid_offset * @ports_per_user

          proxy_port_range = (proxy_port_begin ... (proxy_port_begin + @ports_per_user))
          return proxy_port_range
        end

        def get_open_proxy_port
          interface_data = JSON.parse(File.read(File.join(@container_metadata, "interfaces.json")))
          used_ports = interface_data.map{|entry| entry[:proxy_port]} || []
          port_range.each do |port|
            return port unless used_ports.include? port
          end
          nil
        end

        def reload_network
          set_default_route
          define_dummy_iface
        end

        # run_in_container_root_context(command, [, options]) -> [stdout, stderr, exit status]
        #
        # Executes specified command and return its stdout, stderr and exit status.
        # Or, raise exceptions if certain conditions are not met.
        # The command is run as root within the container.
        # The environment variables are cleared and may be specified by :env.
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
        def run_in_container_root_context(command, options = {})
          options[:unsetenv_others] = true

          if options[:env].nil? or options[:env].empty?
            options[:env] = Utils::Environ.for_gear(@container.container_dir)
          end

          if not File.exist?("/dev/container-id")
            command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
            command = "/usr/bin/virt-sandbox-service execute #{@container.uuid} -- /bin/bash -c '#{command}'"
            OpenShift::Runtime::Utils::oo_spawn(command, options)
          else
            OpenShift::Runtime::Utils::oo_spawn(command, options)
          end
        end

        def freeze_fs_limits
          cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{@container.uuid} 0 0 0"
          out,err,rc = run_in_root_context(cmd)
          raise OpenShift::Runtime::UserCreationException.new("Unable to setup pam/fs/nproc limits for #{@container.uuid}") unless rc == 0
        end

        def freeze_cgroups
          #out,err,rc = run_in_root_context("service cgconfig status > /dev/null")
          #if rc == 0
          #  run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups freezeuser #{@container.uuid} > /dev/null") if rc == 0
          #end
        end

        # release resources (cgroups thaw), this causes Zombies to get killed
        def unfreeze_cgroups
          #out,err,rc = run_in_root_context("service cgconfig status > /dev/null")
          #run_in_root_context("/usr/sbin/oo-admin-ctl-cgroups thawuser #{@container.uuid} > /dev/null") if rc == 0
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

        def dotted_to_cidr(mask)
          IPAddr.new(mask, Socket::AF_INET).to_i.to_s(2).count('1')
        end

        def cidr_to_dotted(mask)
          IPAddr.new( ('1'*mask + '0'*(32-mask)).to_i(2), Socket::AF_INET).to_s
        end

        def get_nat_ip_address
          iprange = @config.get('LIBVIRT_PRIVATE_IP_RANGE')

          valid_ips = IPAddr.new(iprange).to_range
          uid_offset = @container.uid.to_i - @uid_begin
          gw_ip = @config.get('LIBVIRT_PRIVATE_IP_GW')

          #offset to skip address ending in .0
          nat_ip = valid_ips.first(uid_offset + 2).last.to_s
          if( nat_ip == gw_ip )
            nat_ip = valid_ips.first(uid_offset + 3).last.to_s
          end

          mask = iprange.split('/')[1]
          mask = dotted_to_cidr(mask) if mask.match('\.')

          "#{nat_ip}/#{get_nat_ip_mask}"
        end

        def get_nat_ip_mask
          iprange = @config.get('LIBVIRT_PRIVATE_IP_RANGE')
          mask = iprange.split('/')[1]
          mask = dotted_to_cidr(mask) if mask.match('\.')

          mask
        end
      end
    end
  end
end
