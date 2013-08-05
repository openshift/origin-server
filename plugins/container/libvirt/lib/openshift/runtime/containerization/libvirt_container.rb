require 'openshift-origin-node/utils/node_logger'
require 'ipaddr'
require_relative 'libvirt_resource_manager'

::OpenShift::Runtime::Utils::Cgroups.implementation_class = ::OpenShift::Runtime::Containerization::Cgroups::LibvirtResourceManager
module OpenShift
  module Runtime
    module Containerization
      class Plugin
        include OpenShift::Runtime::NodeLogger
        CONF_DIR = '/etc/openshift/'

        attr_reader :gear_shell, :mcs_label

        def self.container_dir(container)
          File.join(container.base_dir,'gear',container.uuid)
        end

        ##
        # Public: Initialize a LibVirt Sandbox based container plugin
        #
        # Configuration for this container is kept in /etc/openshift/container-libvirt.conf.
        # Config variables:
        #   LIBVIRT_PRIVATE_IP_RANGE:
        #     IP range to use when assigning container IP addresses. Eg: 172.16.0.0/12
        #   LIBVIRT_PRIVATE_IP_ROUTE:
        #     Default route for the container. Eg: 172.16.0.0/12
        #   LIBVIRT_PRIVATE_IP_GW:
        #     The gateway IP address. This is the IP of the host machine on the VLan. Eg: 172.16.0.1
        #
        # @param [ApplicationContainer] application_container The parent container object for this plugin.
        def initialize(application_container)
          @container  = application_container
          @config     = OpenShift::Config.new
          @container_config     = OpenShift::Config.new(File.join(CONF_DIR, "container-libvirt.conf"))
          @gear_shell = "/usr/bin/virt-login-shell"
          @mcs_label  = OpenShift::Runtime::Utils::SELinux.get_mcs_label(@container.gid) if @container.uid

          @port_begin = (@config.get("PORT_BEGIN") || "35531").to_i
          @ports_per_user = (@config.get("PORTS_PER_USER") || "5").to_i
          @uid_begin = (@config.get("GEAR_MIN_UID") || "500").to_i
          @container_metadata = File.join(@container.base_dir, ".container", @container.uuid)
        end

        ##
        # Public: Creates a new new POSIX user and group. Initialized a new LibVirt Sandbox based container and
        # creates the basic layout of a OpenShift gear. The container will be started at the before this method
        # returns. You can query the list of available containers with:
        #   virsh -c lxc:/// list --all
        #
        # If the container is not passed a UID, we attempt to generate a UID/GID.
        def create
          unless @container.uid
            @container.uid = @container.gid = @container.next_uid
            @mcs_label  = OpenShift::Runtime::Utils::SELinux.get_mcs_label(@container.gid)
          end

          cmd = %{groupadd -g #{@container.gid} \
          #{@container.uuid}}
          out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
          raise ::OpenShift::Runtime::UserCreationException.new(
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
          if @container.supplementary_groups
            cmd << %{ -G "openshift,#{@container.supplementary_groups}" }
          else
            cmd << %{ -G "openshift" }
          end
          out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
          raise ::OpenShift::Runtime::UserCreationException.new(
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

          tmp_dir = File.join(@container.container_dir, ".tmp")
          FileUtils.mkdir_p(tmp_dir)
          set_rw_permission_R(tmp_dir)
          FileUtils.chmod(0o1777, tmp_dir)

          security_field = "static,label=unconfined_u:system_r:openshift_t:#{@mcs_label}"
          external_ip_addr = "#{get_nat_ip_address}/#{get_nat_ip_mask}"
          external_ip_mask = get_nat_ip_mask
          route            = @container_config.get('LIBVIRT_PRIVATE_IP_ROUTE')
          gw               = @container_config.get('LIBVIRT_PRIVATE_IP_GW')

          cmd = "create " +
              "-U #{@container.uid} -G #{@container.gid} " +
              "-p #{File.join(@container.base_dir,'gear')} -s #{security_field} " +
              "-N address=#{external_ip_addr}," +
              "route=#{route}%#{gw} " +
              "-f openshift_var_lib_t " +
              "-m host-bind:/dev/container-id=#{@container_metadata}/container-id " +
                 "host-bind:/proc/meminfo=/proc/meminfo " +
                 "host-bind:/tmp=#{tmp_dir} " +
                 "host-bind:/var/tmp=#{tmp_dir} " +
              " -- " +
              "#{@container.uuid} /usr/sbin/oo-gear-init"
          out, err, rc = virt_sandbox_command(cmd)
          raise ::OpenShift::Runtime::UserCreationException.new( "Failed to create lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0

          container_link = File.join(@container.container_dir, @container.uuid)
          FileUtils.ln_s(File.join(@container.base_dir,'gear'), container_link)
          set_ro_permission(container_link)

          @container.initialize_homedir(@container.base_dir, @container.container_dir)

          @container.add_env_var("OPENSHIFT_PROXY_IP", @config.get('PUBLIC_IP'))

          start
        end

        ##
        # Public: Starts the LibVirt Sandbox based container and re-initialized the forwarding rules and proxy mappings.
        # This is the equavalent of unidling the container.
        #
        # If the container is already running, this method will reload the network mappings for the container.
        def start(options={})
          return if File.exists?("/dev/container-id")

          was_running = container_running?

          unless was_running
            out, err, rc = virt_command("start #{@container.uuid}")
            raise Exception.new( "Failed to start lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
          end

          if (not was_running) || (options.has_key?(:from_libvirt_hook) && options[:from_libvirt_hook])
            #Wait for container to become available
            for i in 1..10
              begin
                if not container_running?
                  sleep 1
                  next
                end
                _,_,rc = run_in_container_context("echo 0")
                break if  rc == 0
                sleep 1
              rescue => e
                #ignore
              end
            end

            _,_,rc = run_in_container_context("echo 0")
            raise Exception.new( "Failed to start lxc container. rc=#{rc}" ) if rc != 0

            reload_network

            #fix tmp permissions
            run_in_container_root_context("chmod a+rwxt /tmp /var/tmp")
          end
        end

        ##
        # Public: Destroys the LibVirt Sandbox based container and deletes the associated POSIX user and group.
        # If the container is running, it will be stopped and all processed killed before it is destroyed.
        # This method will also clean up firewalld forwarding rules and HTTP proxy mappings.
        def destroy
          if container_exists?
            stop() if container_running?

            out, err, rc = virt_sandbox_command("delete #{@container.uuid}")
            raise Exception.new( "Failed to delete lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0

            FileUtils.rm_rf @container_metadata
          end

          last_access_dir = @config.get("LAST_ACCESS_DIR")
          ::OpenShift::Runtime::Utils::oo_spawn("rm -f #{last_access_dir}/#{@container.name} > /dev/null")
          delete_all_public_endpoints

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
            out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
            raise ::OpenShift::Runtime::UserDeletionException.new(
                      "ERROR: unable to delete user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
                  ) unless rc == 0
          rescue ArgumentError => e
            logger.debug("user does not exist. ignore.")
          end

          begin
            group = Etc.getgrnam(@container.uuid)

            cmd = "groupdel \"#{@container.uuid}\""
            out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
            raise ::OpenShift::Runtime::UserDeletionException.new(
                      "ERROR: unable to delete group of user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
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

          # try one last time...
          if File.exists?(@container.container_dir)
            sleep(5)                    # don't fear the reaper
            FileUtils.rm_rf(@container.container_dir)   # This is our last chance to nuke the polyinstantiated directories
            logger.warn("2nd attempt to remove \'#{@container.container_dir}\' from filesystem failed.") if File.exists?(@container.container_dir)
          end
        end

        ##
        # Public: Stops the LibVirt Sandbox based container but does not destroy it. This is the equavalent of
        # Idling the container.
        def stop(option={})
          return if File.exists?("/dev/container-id")

          out, err, rc = virt_command("shutdown #{@container.uuid}")
          raise Exception.new( "Failed to stop lxc container. rc=#{rc}, out=#{out}, err=#{err}" ) if rc != 0
        end

        def idle(options={})
          stop(options)
        end

        def unidle(options={})
          start(options)
        end

        def boost(&block)
          yield block
        end

        ##
        # Public: Deterministically constructs an IP address for the given UID based on the given
        # host identifier (LSB of the IP). The host identifier must be a value between 1-127
        # inclusive.
        #
        # The global user IP range begins at 0x7F000000.
        #
        # @param [Integer] host_id A unique numberic ID for a cartridge mapping
        # @return an IP address string in dotted-quad notation.
        def get_ip_addr(host_id)
          raise "Invalid host_id specified" unless host_id && host_id.is_a?(Integer)

          if host_id < 1 || host_id > 127
            raise "Supplied host identifier #{host_id} must be between 1 and 127"
          end
          "169.254.169." + host_id.to_s
        end

        ##
        # Public: Given a private IP and port within the container, creates iptables/firewall rules to forward
        # traffic to the external IP of the host machine.
        #
        # @param private_ip [String] Container internal IP that the service is bound to in dotted quad notation.
        # @param private_port [String] Port number that the service is bound to in dotted quad notation.
        # @return [Integer] public port number that the service has been forwarded to.
        def create_public_endpoint(cartridge, endpoint)
          container_endpoint_ip, container_endpoint_port = get_container_cartridge_endpoint(cartridge, endpoint)

          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
          container_internal_ip   = env[endpoint.private_ip_name]
          container_internal_port = endpoint.private_port

          public_port    = get_open_proxy_port
          node_ip        = @config.get('PUBLIC_IP')

          iptables_rules(:add, node_ip, public_port, container_endpoint_ip, container_endpoint_port, container_internal_ip, container_internal_port)

          public_port
        end

        ##
        # Public: Given a list of proxy mappings, removes any iptables/firewall rules that are forwarding traffic.
        #
        # @param proxy_mappings [Array] Array of proxy mappings
        def delete_public_endpoints(proxy_mappings)
          proxy_mappings.each do |mapping|
            node_ip      = @config.get('PUBLIC_IP')
            public_port  = mapping[:proxy_port]
            container_endpoint_ip = mapping[:container_endpoint_ip]
            container_endpoint_port = mapping[:container_endpoint_port]
            container_internal_ip   = mapping[:private_ip]
            container_internal_port = mapping[:private_port]

            iptables_rules(:delete, node_ip, public_port, container_endpoint_ip, container_endpoint_port, container_internal_ip, container_internal_port)
          end
        end

        ##
        # Public: Removes all iptables/firewall rules that are forwarding traffic for this container
        def delete_all_public_endpoints
          delete_public_endpoints(@container.list_proxy_mappings)
        end

        ##
        # Public: Executes specified command inside the container and return its stdout, stderr and exit status or,
        # raise exceptions if certain conditions are not met. If executed from within a container, it does not
        # attempt to re-enter container context.
        #
        # The command is run within the container and is automiatically constrainged by SELinux context.
        # The environment variables are cleared and may be specified by :env.
        #
        # @param [String] command command line string which is passed to the standard shell
        # @param [Hash] options
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
        # @return [Array] stdout, stderr, exit status
        #
        # NOTE: If the +out+ or +err+ options are specified, the corresponding return value from +oo_spawn+
        # will be the incoming/provided +IO+ objects instead of the buffered +String+ output. It's the
        # responsibility of the caller to correctly handle the resulting data type.
        def run_in_container_context(command, options = {})
          require 'openshift-origin-node/utils/selinux'
          options[:unsetenv_others] = true
          options[:force_selinux_context] = false

          if options[:env].nil? or options[:env].empty?
            options[:env] = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
          end

          if not File.exists?("/dev/container-id")
            #options[:cgroup] = "/machine/#{@container.uuid}.libvirt-lxc"
            command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
            options.delete :uid

            command = %Q{execute #{@container.uuid} -- /sbin/runuser -s /bin/bash #{@container.uuid} -c "#{command}"}
            virt_sandbox_command(command, options)
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

        ##
        # Maps a given endpoint to the container IP and port where it is avaible.
        #
        # @param [Cartridge] cartridge the endpoint belongs to
        # @param [Endpoint] endpoint to map to ip and host
        # @return [String] Mapped endpoint in "IP:Port" format
        def get_container_cartridge_endpoint(cartridge, endpoint)
          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
          [get_nat_ip_address, env["OPENSHIFT_INT_" + endpoint.private_port_name]]
        end

        ##
        # Maps a
        def create_container_cartridge_endpoint(cartridge, endpoint, private_ip)
          private_port = endpoint.private_port
          container_port = get_open_container_proxy_port
          container_ip = get_nat_ip_address
          @container.add_env_var("OPENSHIFT_INT_" + endpoint.private_port_name, container_port)

          command = "iptables -t nat -A PREROUTING " +
              "-d #{container_ip} -p tcp --dport=#{container_port} " +
              "-j DNAT --to-destination #{private_ip}:#{private_port};" +
              #"iptables -t nat -A OUTPUT " +
              #"-d #{container_ip} -p tcp --dport=#{container_port} " +
              #"-j DNAT --to-destination #{private_ip}:#{private_port};" +
              "iptables-save > #{@container.container_dir}/.iptables;"
          run_in_container_root_context(command)
          [container_ip, container_port]
        end

        def delete_container_cartridge_endpoint(cartridge, endpoint, private_ip)
          private_port = endpoint.private_port
          container_port = get_open_container_proxy_port
          container_ip = get_nat_ip_address
          @container.remove_env_var("OPENSHIFT_INT_" + endpoint.private_port_name, container_port)

          command = "iptables -t nat -D PREROUTING " +
              "-d #{container_ip} -p tcp --dport=#{container_port} " +
              "-j DNAT --to-destination #{private_ip}:#{private_port};" +
              #"iptables -t nat -D OUTPUT " +
              #"-d #{container_ip} -p tcp --dport=#{container_port} " +
              #"-j DNAT --to-destination #{private_ip}:#{private_port};" +
              "iptables-save > #{@container.container_home}/.iptables;"
          run_in_container_root_context(command)
        end

        private

        def set_default_route
          gw = @container_config.get('LIBVIRT_PRIVATE_IP_GW')
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
          endpoints = @container.list_proxy_mappings
          used_ports = endpoints.map{|entry| entry[:proxy_port]}
          port_range.each do |port|
            return port unless used_ports.include? port
          end
          nil
        end

        def get_open_container_proxy_port
          env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)

          used_ports = []
          env.each do |name, val|
            used_ports << val.to_i if name.start_with? "OPENSHIFT_INT_"
          end

          (1025..65536).each do |port|
            return port unless used_ports.include? port
          end
          nil
        end

        def reload_network
          set_default_route
          define_dummy_iface
          recreate_all_container_endpoints
          recreate_all_public_endpoints
        end

        def run_in_container_root_context(command, options = {})
          options[:unsetenv_others] = true
          options[:force_selinux_context] = false
          options[:cgroup] = "/machine/#{@container.uuid}.libvirt-lxc"

          if options[:env].nil? or options[:env].empty?
            options[:env] = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
          end

          if not File.exist?("/dev/container-id")
            command = "cd #{options[:chdir]} ; #{command}" if options[:chdir]
            command = "execute #{@container.uuid} -- /bin/bash -c '#{command}'"
            virt_sandbox_command(command, options)
          else
            OpenShift::Runtime::Utils::oo_spawn(command, options)
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

        def dotted_to_cidr(mask)
          IPAddr.new(mask, Socket::AF_INET).to_i.to_s(2).count('1')
        end

        def cidr_to_dotted(mask)
          IPAddr.new( ('1'*mask + '0'*(32-mask)).to_i(2), Socket::AF_INET).to_s
        end

        def get_nat_ip_address
          iprange = @container_config.get('LIBVIRT_PRIVATE_IP_RANGE')

          valid_ips = IPAddr.new(iprange).to_range
          first_ip = valid_ips.first.to_i + 1
          last_ip  = valid_ips.first.to_i
          gw_ip    = IPAddr.new(@container_config.get('LIBVIRT_PRIVATE_IP_GW')).to_i

          uid_offset = @container.uid.to_i - @uid_begin
          nat_ip = first_ip + uid_offset

          nat_ip += 1 if( nat_ip >= gw_ip )

          IPAddr.new(nat_ip, Socket::AF_INET).to_s
        end

        def get_nat_ip_mask
          iprange = @container_config.get('LIBVIRT_PRIVATE_IP_RANGE')
          mask = iprange.split('/')[1]
          mask = dotted_to_cidr(mask) if mask.match('\.')

          mask
        end

        def recreate_all_container_endpoints
          run_in_container_root_context("iptables-restore < #{@container.container_dir}/.iptables")
        end

        ##
        # Private: Delete and recreate all iptables/firewall rules for this container.
        # This is useful when restarting or restoring a LibVirt Sandbox based container.
        def recreate_all_public_endpoints
          proxy_mappings = @container.list_proxy_mappings
          delete_public_endpoints(proxy_mappings)
          proxy_mappings.each do |mapping|
            node_ip      = @config.get('PUBLIC_IP')
            public_port  = mapping[:proxy_port]
            container_endpoint_ip = mapping[:container_endpoint_ip]
            container_endpoint_port = mapping[:container_endpoint_port]
            container_internal_ip = mapping[:private_ip]
            container_internal_port = mapping[:private_port]

            iptables_rules(:add, node_ip, public_port, container_endpoint_ip, container_endpoint_port, container_internal_ip, container_internal_port)
          end
        end

        def iptables_rules(action, node_ip, public_port, container_endpoint_ip, container_endpoint_port, container_internal_ip, container_internal_port)
          if action == :add
            cmd = "iptables -t nat -A PREROUTING " +
                "-d #{node_ip} -p tcp --dport=#{public_port} " +
                "-j DNAT --to-destination #{container_endpoint_ip}:#{container_endpoint_port};" +
                "iptables -t nat -A OUTPUT " +
                "-d #{node_ip} -p tcp --dport=#{public_port} " +
                "-j DNAT --to-destination #{container_endpoint_ip}:#{container_endpoint_port};" +
                "iptables -t filter -I FORWARD " +
                "-p tcp --dport #{container_endpoint_port} -d #{container_endpoint_ip} -j ACCEPT"
            #cmd = "firewall-cmd --zone=public --add-forward-port=port=#{public_port}:proto=tcp:toaddr=#{container_endpoint_ip}:toport=#{container_endpoint_port}"
            ::OpenShift::Runtime::Utils::oo_spawn(cmd)

            cmd = "iptables -t nat -I OUTPUT -d #{node_ip} -p tcp -m tcp --dport #{public_port} " +
                    "-j DNAT --to-destination #{container_internal_ip}:#{container_internal_port};" +
                  "iptables-save > #{@container.container_dir}/.iptables;"
            run_in_container_root_context(cmd)
          end

          if action == :delete
            cmd = "iptables -t nat -D PREROUTING " +
                "-d #{node_ip} -p tcp --dport=#{public_port} " +
                "-j DNAT --to-destination #{container_endpoint_ip}:#{container_endpoint_port};" +
                "iptables -t nat -D OUTPUT " +
                "-d #{node_ip} -p tcp --dport=#{public_port} " +
                "-j DNAT --to-destination #{container_endpoint_ip}:#{container_endpoint_port};" +
                "iptables -t filter -D FORWARD " +
                "-p tcp --dport #{container_endpoint_port} -d #{container_endpoint_ip} -j ACCEPT"
            #cmd = "firewall-cmd --zone=public --remove-forward-port=port=#{public_port}:proto=tcp:toaddr=#{container_endpoint_ip}:toport=#{container_endpoint_port}"
            ::OpenShift::Runtime::Utils::oo_spawn(cmd)
            cmd = "iptables -t nat -D OUTPUT -d #{node_ip} -p tcp -m tcp --dport #{public_port} " +
                "-j DNAT --to-destination #{container_internal_ip}:#{container_internal_port};" +
                "iptables-save > #{@container.container_dir}/.iptables;"
            run_in_container_root_context(cmd)
          end
        end

        def container_list
          out, _, _ = virt_command("list --all")
          out.split("\n")[2..-1].map! do |m|
            m = m.split(" ")
            {
              name:  m[1],
              state: m[2..-1].join(" "),
            }
          end
        end

        def container_exists?
          return false unless File.exist?("/etc/libvirt-sandbox/services/#{@container.uuid}")
          container_list.each do |m|
            return true if m[:name] == @container.uuid
          end
          return false
        end

        def container_running?
          container_list.each do |m|
            return true if m[:name] == @container.uuid and m[:state] == "running"
          end
          return false
        end

        def virt_command(cmd, options={})
          virt_lock_file = "/var/lock/oo-virt"
          out, err, rc = 0
          File.open(virt_lock_file, File::RDWR|File::CREAT|File::TRUNC, 0o0600) do | virt_lock |
            virt_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
            virt_lock.flock(File::LOCK_EX)

            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/virsh -c lxc:/// #{cmd}", options)

            virt_lock.flock(File::LOCK_UN)
          end

          [out, err, rc]
        end

        def virt_sandbox_command(cmd, options={})
          virt_lock_file = "/var/lock/oo-virt"
          out, err, rc = 0

          File.open(virt_lock_file, File::RDWR|File::CREAT|File::TRUNC, 0o0600) do | virt_lock |
            virt_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
            virt_lock.flock(File::LOCK_EX)

            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("/usr/bin/virt-sandbox-service #{cmd}", options)

            virt_lock.flock(File::LOCK_UN)
          end

          [out, err, rc]
        end
      end
    end
  end
end
