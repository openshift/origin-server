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
require 'ipaddr'

module OpenShift
  module Container
    module LibVirtLxcContainer
      def container_init
        unless @container_uid
          @container_uid = @container_gid = next_uid
        end
        @mcs_label = Utils::SELinux.get_mcs_label(@container_gid)
        @gear_shell = "/usr/bin/nsjoin"
      end
      
      def container_create
        skel_dir = @config.get("GEAR_SKEL_DIR") || DEFAULT_SKEL_DIR
        shell    = "/bin/bash"
        gecos    = @config.get("GEAR_GECOS")     || "OO application container"
        supplementary_groups = @config.get("GEAR_SUPL_GRPS")
        @container_gid = 500 #TODO: hack
        
        notify_observers(:before_unix_user_create)

        cmd = %{groupadd -f -g #{@container_gid} #{@application_uuid}}
        out,err,rc = shellCmd(cmd)
        raise UserCreationException.new(
                "ERROR: unable to create group(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                ) unless rc == 0

        cmd = %{useradd -u #{@container_uid} \
                -g #{@container_gid} \
                -d #{@container_dir} \
                -s #{shell} \
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

        set_ro_permission_R(@container_dir)
        FileUtils.chmod 0o0750, @container_dir

        container_metadata = File.join(@basedir, ".container", @uuid)
        FileUtils.mkdir_p(container_metadata)
        File.open(File.join(File.join(container_metadata, "container-id")), "w") do |f|
          f.write(@uuid)
        end
        
        #File.open(File.join(File.join(container_metadata, "passwd")), "w") do |f|
        #  f.write("root:x:0:0:root:/root:/bin/bash\n")
        #  f.write("#{@uuid}:x:#{@container_uid}:#{@container_gid}:#{gecos}:#{@container_dir}:/bin/bash\n")
        #end
        #File.open(File.join(File.join(container_metadata, "shadow")), "w") do |f|
        #  f.write("root:!!:15812:0:99999:7:::\n")
        #  f.write("#{@uuid}:!!:15812:0:99999:7:::\n")
        #end
        #File.open(File.join(File.join(container_metadata, "group")), "w") do |f|
        #  f.write("root:x:0:\n")
        #  f.write("#{@application_uuid}:x:#{@container_gid}:\n")
        #  unless supplementary_groups.nil?
        #    supplementary_groups.split(",").each do |grp|
        #      grpent = Etc.setgrent(grp)
        #      f.write("#{grpent.name}:x:#{grpent.gid}:#{@uuid}\n")
        #    end
        #  end
        #end
        
        File.open(File.join(File.join(container_metadata, "interfaces.json")), "w") do |f|
          f.write("{}\n")
        end
        set_ro_permission_R(container_metadata)
        
        security_field = "static,label=system_u:system_r:openshift_initrc_t:#{@mcs_label}"
        cmd = "/usr/bin/virt-sandbox-service create " +
            "-U #{@container_uid} " +
            "-G #{@container_gid} " +
            "-p #{@basedir} " +
            "-s #{security_field} " +
            "-N address=#{get_ip_addr}/#{dotted_to_cidr("255.0.0.0")}," +
            "route=10.0.0.0/#{dotted_to_cidr("255.0.0.0")}%10.0.0.1 " +
            "-f openshift_var_lib_t " +
            "-B /proc/meminfo=/proc/meminfo " +
            "   /dev/container-id=#{container_metadata}/container-id " +
            #"   /etc/passwd=#{container_metadata}/passwd " +
            #"   /etc/shadow=#{container_metadata}/shadow " +
            #"   /etc/group=#{container_metadata}/group " +
            " -- " +
            @uuid + " /usr/sbin/oo-gear-init"
        out, err, rc = run_in_root_context(cmd)
        raise OpenShift::UserCreationException.new( "Failed to create lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
        
        container_link = File.join(@container_dir, @uuid)
        FileUtils.ln_s("/var/lib/openshift", container_link)
        set_ro_permission(container_link)
        
        container_start

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
      
      # Private: Initialize OpenShift Port Proxy for this gear
      #
      # The port proxy range is determined by configuration and must
      # produce identical results to the abstract cartridge provided
      # range.
      #
      # Examples:
      # container_port_proxy_setup
      #    => true
      #    service openshift_port_proxy setproxy 35000 delete 35001 delete etc...
      #
      # Returns:
      #    true   - port proxy could be initialized properly
      #    false  - port proxy could not be initialized properly
      def container_port_proxy_setup
        notify_observers(:before_initialize_openshift_port_proxy)

        proxy_server = FrontendProxyServer.new
        proxy_server.delete_all_for_uid(@container_uid, true)

        notify_observers(:after_initialize_openshift_port_proxy)
      end
      
      def container_destroy
        if File.exist?("/etc/libvirt-sandbox/services/#{@uuid}.sandbox")
          container_stop if container_running?
          
          out, _, _ = run_in_root_context("/usr/bin/virt-sandbox-service list")
          if out.split("\n").include?(@uuid)
            out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service delete #{@uuid}")
            raise Exception.new( "Failed to delete lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
          end
          
          container_metadata = File.join(@basedir, ".container", @uuid)
          FileUtils.rm_rf container_metadata
        end
        
        last_access_dir = OpenShift::Config.new.get("LAST_ACCESS_DIR")
        run_in_root_context("rm -f #{last_access_dir}/#{@uuid} > /dev/null")

        purge_sysvipc(uuid)

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

        cmd = "/bin/sh #{File.join("/usr/libexec/openshift/lib", "teardown_pam_fs_limits.sh")} #{@uuid}"
        out,err,rc = shellCmd(cmd)
        raise OpenShift::UserCreationException.new("Unable to teardown pam/fs/nproc limits for #{@uuid}") unless rc == 0
        
        if File.exists?(@container_dir)
          sleep(5)                    # don't fear the reaper
          FileUtils.rm_rf(@container_dir)   # This is our last chance to nuke the polyinstantiated directories
          logger.warn("2nd attempt to remove \'#{@homedir}\' from filesystem failed.") if File.exists?(@container_dir)
        end
      end

      def with_no_cpu_limits
        #OpenShift::Utils::Cgroups::with_no_cpu_limits(@uuid) do
          yield
        #end
      end
      
      def container_running?
        out,err,rc = run_in_root_context("/usr/bin/virt-sandbox-service list -r")
        out.split("\n").include?(@uuid)
      end
      
      def container_start(options={})
        out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service start #{@uuid} < /dev/null > /dev/null 2> /dev/null &")
        raise Exception.new( "Failed to start lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
        
        #Wait for container to become available
        for i in 1..10
          sleep 1
          begin
            _,_,rc = run_in_container_context("ps")
            break if  rc == 0
          rescue => e
            #ignore
          end
        end
      end
      
      def container_stop(options={})
        stop_gear(options)
        out, err, rc = run_in_root_context("/usr/bin/virt-sandbox-service stop #{@uuid}")
        raise Exception.new( "Failed to stop lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
      end

      def container_force_stop(options={})
        stop_gear(options)
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
        options[:unsetenv_others] = true

        if options[:env].nil? or options[:env].empty?
          options[:env] = Utils::Environ.for_gear(@container_dir)
        end

        if not File.exist?("/dev/container-id")
          command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
          command = "/usr/bin/nsjoin #{uuid} \"#{command}\""
          OpenShift::Utils::oo_spawn(command, options)
        else
          options[:uid] = @container_uid
          OpenShift::Utils::oo_spawn(command, options)
        end
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
          options[:env] = Utils::Environ.for_gear(@container_dir)
        end

        if not File.exist?("/dev/container-id")
          command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
          command = "/usr/bin/virt-sandbox-service execute #{uuid} -- /bin/bash -c '#{command}'"
          OpenShift::Utils::oo_spawn(command, options)
        else
          OpenShift::Utils::oo_spawn(command, options)
        end
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
      
      def container_create_interface(ip,mask)
        interface_data = JSON.parse(File.read(File.join(@basedir, ".container", @uuid, "interfaces.json")))
        interface_data[ip] = mask
        File.open(File.join(@basedir, ".container", @uuid, "interfaces.json"), "w") do |f|
          f.write(interface_data.to_json)
        end
        container_reload_interfaces
      end
      
      def container_delete_interface(ip)
        interface_data = JSON.parse(File.read(File.join(@basedir, ".container", @uuid, "interfaces.json")))
        interface_data.delete ip
        File.open(File.join(@basedir, ".container", @uuid, "interfaces.json"), "w") do |f|
          f.write(interface_data.to_json)
        end
        container_reload_interfaces
      end
      
      def container_reload_interfaces
        interface_data = JSON.parse(File.read(File.join(@basedir, ".container", @uuid, "interfaces.json")))
        
        addrs = get_interface_addrs
        addrs_to_add = []
        addrs_to_del = []
        interface_data.each do |addr, mask|
          addrs_to_add << {ip:addr, mask:mask} unless addrs.has_key? addr
        end
        addrs.each do |addr, mask|
          addrs_to_del << {ip:addr, mask:mask} unless interface_data.has_key? addr
        end
        addrs_to_add.each { |addr| add_interface_addr(addr[:ip], addr[:mask]) }
        addrs_to_del.each { |addr| del_interface_addr(addr[:ip], addr[:mask]) }
        run_in_container_root_context("route del default ; route add default gw 10.0.0.1 dev eth0")
      end
      
      # Deterministically constructs an IP address for the given UID based on the given
      # host identifier (LSB of the IP). The host identifier must be a value between 1-127
      # inclusive.
      #
      # The global user IP range begins at 0x7F000000.
      #
      # Returns an IP address string in dotted-quad notation.
      def get_ip_addr(host_id=1)
        raise "Invalid host_id specified" unless host_id && host_id.is_a?(Integer)

        if @container_uid.to_i < 0 || @container_uid.to_i > 262143
          raise "User uid #{@container_uid} is outside the working range 0-262143"
        end

        if host_id < 1 || host_id > 127
          raise "Supplied host identifier #{host_id} must be between 1 and 127"
        end

        # Generate an IP (32-bit unsigned) in the user's range
        ip = 0x0A000000 + (@container_uid.to_i << 7)  + host_id

        # Return the IP in dotted-quad notation
        "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}"
      end
      
      private
      
      def get_interface_addrs
        for i in 1..5
          out, err, rc = run_in_container_root_context("ip addr show dev eth0")
          break if rc == 0
          sleep 1
        end
        raise Exception.new "Unable to retrieve container interfaces. Err: #{err}, Out: #{out}, rc: #{rc}" unless rc == 0
        addrs = {}
        ips = out.split("\n").map do |l| 
          m = l.match(/\s*inet ([\d\.\/]*) scope/) 
          unless m.nil?
            ip, mask = m[1].split("/")
            addrs[ip] = cidr_to_dotted(mask.to_i)
          end
        end
        addrs
      end
      
      def add_interface_addr(ip, mask)
        out, err, rc = run_in_container_root_context("ip addr add #{ip}/#{mask} dev eth0")
        raise Exception.new "Unable to add interafce IP #{ip} for container #{@uuid}" unless 0 == rc
      end
      
      def del_interface_addr(ip, mask)
        out, err, rc = run_in_container_root_context("ip addr del #{ip}/#{mask} dev eth0")
        raise Exception.new "Unable to add interafce IP #{ip} for container #{@uuid}" unless 0 == rc
      end
      
      def dotted_to_cidr(mask)
        IPAddr.new(mask, Socket::AF_INET).to_i.to_s(2).count('1')
      end
      
      def cidr_to_dotted(mask)
        IPAddr.new( ('1'*mask + '0'*(32-mask)).to_i(2), Socket::AF_INET).to_s
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
