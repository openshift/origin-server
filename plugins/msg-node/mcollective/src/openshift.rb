require 'rubygems'
require 'open4'
require 'pp'
require 'json'
require 'openshift-origin-node'
require 'shellwords'
require 'facter'

module MCollective
  module Agent
    class Openshift<RPC::Agent
      metadata    :name        => "OpenShift Agent",
                  :description => "Agent to manage OpenShift services",
                  :author      => "Mike McGrath",
                  :license     => "ASL 2.0",
                  :version     => "0.1",
                  :url         => "http://www.openshift.com",
                  :timeout     => 240

      def echo_action
        validate :msg, String
        reply[:msg] = request[:msg]
      end

      def cleanpwd(arg)
        arg.gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]').gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i,'\\1[HIDDEN]')
      end

      def oo_app_create(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        app_uuid = args['--with-app-uuid']
        gear_uuid = args['--with-container-uuid']
        uid = args['--with-uid']
        uid = nil if uid && uid.to_s.empty?
        quota_blocks = args['--with-quota-blocks']
        quota_files = args['--with-quota-files']
        app_name = args['--with-app-name']
        gear_name = args['--with-container-name']
        namespace = args['--with-namespace']
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(app_uuid, gear_uuid, uid, app_name, gear_name,
                                                           namespace, quota_blocks, quota_files)
          container.create
        rescue OpenShift::UserCreationException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_app_destroy(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        app_uuid = args['--with-app-uuid']
        app_name = args['--with-app-name']
        gear_uuid = args['--with-container-uuid']
        gear_name = args['--with-container-name']
        namespace = args['--with-namespace']
        skip_hooks = args['--skip-hooks'] ? args['--skip-hooks'] : false
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(app_uuid, gear_uuid, nil, app_name, gear_name, 
                                                           namespace, nil, nil)
          out, err, rc = container.destroy(skip_hooks)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          output << out
          output << err
          return rc, output
        end
      end

      def oo_authorized_ssh_key_add(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        ssh_key = args['--with-ssh-key']
        key_type = args['--with-ssh-key-type']
        comment = args['--with-ssh-key-comment']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.add_ssh_key(ssh_key, key_type, comment)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_authorized_ssh_key_remove(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        ssh_key = args['--with-ssh-key']
        comment = args['--with-ssh-comment']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.remove_ssh_key(ssh_key, comment)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_broker_auth_key_add(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        iv = args['--with-iv']
        token = args['--with-token']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.add_broker_auth(iv, token)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_broker_auth_key_remove(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.remove_broker_auth
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_env_var_add(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        key = args['--with-key']
        value = args['--with-value']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.add_env_var(key, value)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_env_var_remove(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        uuid = args['--with-container-uuid']
        key = args['--with-key']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(uuid, uuid)
          container.user.remove_env_var(key)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_cartridge_list(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        list_descriptors = true if args['--with-descriptors']
        porcelain = true if args['--porcelain']

        output = ""
        begin
          output = OpenShift::Node.get_cartridge_list(list_descriptors, porcelain, false)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_app_state_show(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        container_uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']        
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(app_uuid, container_uuid)
          output = container.get_app_state()
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_get_quota(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        uuid = args['--uuid']

        output = ""
        begin
          output = OpenShift::Node.get_quota(uuid)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_set_quota(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        uuid   = args['--uuid']
        blocks = args['--blocks']
        inodes = args['--inodes']

        output = ""
        begin
          output = OpenShift::Node.set_quota(uuid, blocks, inodes)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_force_stop(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        container_uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']
        
        output = ""
        begin
          container = OpenShift::ApplicationContainer.new(app_uuid, container_uuid)
          container.force_stop
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_add_alias(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        container_uuid = args['--with-container-uuid']
        container_name = args['--with-container-name']
        namespace = args['--with-namespace']
        alias_name = args['--with-alias-name']

        output = ""
        begin
          frontend = OpenShift::FrontendHttpServer.new(container_uuid, container_name, namespace)
          out, err, rc = frontend.add_alias(alias_name)
        rescue OpenShift::FrontendHttpServerException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          output << out
          output << err
          return rc, output
        end
      end

      def oo_remove_alias(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        container_uuid = args['--with-container-uuid']
        container_name = args['--with-container-name']
        namespace = args['--with-namespace']
        alias_name = args['--with-alias-name']

        output = ""
        begin
          frontend = OpenShift::FrontendHttpServer.new(container_uuid, container_name, namespace)
          out, err, rc = frontend.remove_alias(alias_name)
        rescue OpenShift::FrontendHttpServerException => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return 129, e.message
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          output << out
          output << err
          return rc, output
        end
      end

      def oo_ssl_cert_add(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        container_uuid = args['--with-container-uuid']
        container_name = args['--with-container-name']
        namespace      = args['--with-namespace']

        ssl_cert      = args['--with-ssl-cert']
        ssl_cert_name = args['--with-ssl-cert-name']
        priv_key      = args['--with-priv-key']
        priv_key_name = args['--with-priv-key-name']
        server_alias  = args['--with-alias-name']

        output = ""
        begin
          frontend = OpenShift::FrontendHttpServer.new(container_uuid,
                                                       container_name, namespace)
          out, err, rc = frontend.add_ssl_cert(ssl_cert, ssl_cert_name,
                                               priv_key, priv_key_name,
                                               server_alias)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_ssl_cert_remove(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        
        container_uuid = args['--with-container-uuid']
        container_name = args['--with-container-name']
        namespace      = args['--with-namespace']

        ssl_cert_name = args['--with-ssl-cert-name']
        priv_key_name = args['--with-priv-key-name']
        server_alias  = args['--with-alias-name']

        output = ""
        begin
          frontend = OpenShift::FrontendHttpServer.new(container_uuid,
                                                       container_name, namespace)
          out, err, rc = frontend.remove_ssl_cert(ssl_cert_name, priv_key_name,
                                                  server_alias)
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, output
        end
      end

      def oo_tidy(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"

        container_uuid = args['--with-container-uuid']
        app_uuid = args['--with-app-uuid']

        begin
          # is it time for an options hash? lack of named params makes this very messy
          container = OpenShift::ApplicationContainer.new(app_uuid, container_uuid, nil, 
            nil, nil, nil, nil, nil, logger = Log.instance)
          container.tidy
        rescue Exception => e
          Log.instance.info e.message
          Log.instance.info e.backtrace
          return -1, e.message
        else
          return 0, ""
        end
      end

      def oo_connector_execute(cmd, args)
        Log.instance.info "COMMAND: #{cmd}"
        gear_uuid = args['--gear-uuid']
        cart_name = args['--cart-name']
        hook_name = args['--hook-name']
        input_args = args['--input-args']
        
        hook_path = "/usr/libexec/openshift/cartridges/#{cart_name}/info/connection-hooks/#{hook_name}"
        if File.exists? hook_path
           pid, stdin, stdout, stderr = Open4::popen4ext(true, "#{hook_path} #{input_args} 2>&1")
        else
           raise Exception.new("Could not find #{hook_path}")
        end
        return pid, stdin, stdout, stderr
      end

      def handle_oo_cmd(action, args)
        cmd = "oo-#{action}"
        case action
        when "app-create"
          rc, output = oo_app_create(cmd, args)
        when "app-destroy"
          rc, output = oo_app_destroy(cmd, args)
        when "authorized-ssh-key-add"
          rc, output = oo_authorized_ssh_key_add(cmd, args)
        when "authorized-ssh-key-remove"
          rc, output = oo_authorized_ssh_key_remove(cmd, args)
        when "broker-auth-key-add"
          rc, output = oo_broker_auth_key_add(cmd, args)
        when "broker-auth-key-remove"
          rc, output = oo_broker_auth_key_remove(cmd, args)
        when "env-var-add" 
          rc, output = oo_env_var_add(cmd, args)
        when "env-var-remove" 
          rc, output = oo_env_var_remove(cmd, args)
        when "cartridge-list"
          rc, output = oo_cartridge_list(cmd, args)
        when "app-state-show"
          rc, output = oo_app_state_show(cmd, args)
        when "get-quota"
          rc, output = oo_get_quota(cmd, args)
        when "set-quota"
          rc, output = oo_set_quota(cmd, args)
        when "ssl-cert-add"
          rc, output = oo_ssl_cert_add(cmd, args)
        when "ssl-cert-remove"
          rc, output = oo_ssl_cert_remove(cmd, args)
        when "force-stop"
          rc, output = oo_force_stop(cmd, args)
        when "add-alias"
          rc, output = oo_add_alias(cmd, args)
        when "remove-alias"
          rc, output = oo_remove_alias(cmd, args)
        when "tidy"
          rc, output = oo_tidy(cmd, args)
        else
          return nil, nil
        end
        return rc, output
      end

      def complete_process_gracefully(pid, stdin, stdout)
        stdin.close
        ignored, status = Process::waitpid2 pid
        exitcode = status.exitstatus
        # Do this to avoid cartridges that might hold open stdout
        output = ""
        begin
          Timeout::timeout(5) do
            while (line = stdout.gets)
              output << line
            end
          end
        rescue Timeout::Error
          Log.instance.info("WARNING: stdout read timed out")
        end

        if exitcode == 0
          Log.instance.info("(#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
        else
          Log.instance.info("ERROR: (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
        end
        return exitcode, output
      end

      def handle_cartridge_action(cartridge, action, args)
        exitcode = 0
        output = ""

        if File.exists? "/usr/libexec/openshift/cartridges/#{cartridge}/info/hooks/#{action}"
          cart_cmd = "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/#{cartridge}/info/hooks/#{action} #{args} 2>&1"
          Log.instance.info("handle_cartridge_action executing #{cart_cmd}")
          pid, stdin, stdout, stderr = Open4::popen4ext(true, cart_cmd)
        elsif File.exists? "/usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/hooks/#{action}"
          cart_cmd = "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/hooks/#{action} #{args} 2>&1"
          Log.instance.info("handle_cartridge_action executing #{cart_cmd}")
          pid, stdin, stdout, stderr = Open4::popen4ext(true, cart_cmd)
        else
          exitcode = 127
          output = "ERROR: action '#{action}' not found."
        end
        exitcode, output = complete_process_gracefully(pid, stdin, stdout) if exitcode == 0
        return exitcode, output
      end

      #
      # Passes arguments to cartridge for use
      #
      def cartridge_do_action
        Log.instance.info("cartridge_do_action call / request = #{request.pretty_inspect}")
        Log.instance.info("cartridge_do_action validation = #{request[:cartridge]} #{request[:action]} #{request[:args]}")
        validate :cartridge, /\A[a-zA-Z0-9\.\-\/]+\z/
        validate :cartridge, :shellsafe
        validate :action, /\A(app-create|app-destroy|env-var-add|env-var-remove|broker-auth-key-add|broker-auth-key-remove|authorized-ssh-key-add|authorized-ssh-key-remove|configure|ssl-cert-add|ssl-cert-remove|deconfigure|update-namespace|tidy|deploy-httpd-proxy|remove-httpd-proxy|restart-httpd-proxy|move|pre-move|post-move|info|post-install|post-remove|pre-install|reload|restart|start|status|stop|force-stop|add-alias|remove-alias|threaddump|cartridge-list|expose-port|conceal-port|show-port|system-messages|connector-execute|get-quota|set-quota)\Z/
        validate :action, :shellsafe
        cartridge = request[:cartridge]
        action = request[:action]
        args = request[:args]
        pid, stdin, stdout, stderr = nil, nil, nil, nil
        rc = nil
        output = ""
        if cartridge == 'openshift-origin-node'
          cmd = "oo-#{action}"
          if action == 'connector-execute'
            pid, stdin, stdout, stderr = oo_connector_execute(cmd, args)
            exitcode, output = complete_process_gracefully(pid, stdin, stdout)
          else
            exitcode, output = handle_oo_cmd(action, args)
          end
        else
          validate :args, /\A[\w\+\/= \{\}\"@\-\.:;\'\\\n~,]+\z/
          validate :args, :shellsafe
          exitcode, output = handle_cartridge_action(cartridge, action, args)
        end
        reply[:exitcode] = exitcode
        reply[:output] = output
        if exitcode == 0
          Log.instance.info("cartridge_do_action (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
        else
          Log.instance.info("cartridge_do_action failed (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
          reply.fail! "cartridge_do_action failed #{exitcode}. Output #{output}"
        end
      end
     
      #
      # Set the district for a node
      #
      def set_district_action
        Log.instance.info("set_district call / request = #{request.pretty_inspect}")
        validate :uuid, /^[a-zA-Z0-9]+$/
        uuid = request[:uuid]
        active = request[:active]

        begin
          district_home = '/var/lib/openshift/.settings'
          FileUtils.mkdir_p(district_home)

          File.open(File.join(district_home, 'district.info'), 'w') { |f|
            f.write("#Do not modify manually!\nuuid='#{uuid}'\nactive='#{active}'\n")
          }

          Facter.add(:district_uuid) do
            setcode { uuid }
          end
          Facter.add(:district_active) do
            setcode { active }
          end

          reply[:output] = "created/updated district #{uuid} with active = #{active}"
          reply[:exitcode] = 0
        rescue Exception => e
          reply[:output] = e.message
          reply[:exitcode] = 255
          reply.fail! "set_district failed #{reply[:exitcode]}.  Output #{reply[:output]}" 
        end

        Log.instance.info("set_district (#{reply[:exitcode]})\n------\n#{reply[:output]}\n------)")
      end

      #
      # Returns whether an app is on a server
      #
      def has_app_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :application, /^[a-zA-Z0-9]+$/
        uuid = request[:uuid]
        app_name = request[:application]
        if File.exist?("/var/lib/openshift/#{uuid}/#{app_name}")
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end
      
      #
      # Returns whether an embedded app is on a server
      #
      def has_embedded_app_action
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :embedded_type, /^.+$/
        uuid = request[:uuid]
        embedded_type = request[:embedded_type]
        if File.exist?("/var/lib/openshift/#{uuid}/#{embedded_type}")
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end
      
      #
      # Returns whether a uid or gid is already reserved on the system
      #
      def has_uid_or_gid_action
        validate :uid, /^[0-9]+$/
        uid = request[:uid].to_i

        uids = IO.readlines("/etc/passwd").map{ |line| line.split(":")[2].to_i }
        gids = IO.readlines("/etc/group").map{ |line| line.split(":")[2].to_i }

        if uids.include?(uid) || gids.include?(uid)
          reply[:output] = true
        else
          reply[:output] = false
        end
        reply[:exitcode] = 0
      end

      #
      # Get all gears
      #
      def get_all_gears_action
        gear_map = {}

        uid_map = {}
        uids = IO.readlines("/etc/passwd").map{ |line| 
          uid = line.split(":")[2]
          username = line.split(":")[0]
          uid_map[username] = uid
        }
        dir = "/var/lib/openshift/"
        filelist = Dir.foreach(dir) { |file| 
          if File.directory?(dir+file) and not File.symlink?(dir+file) and not file[0]=='.'
            if uid_map.has_key?(file)
              gear_map[file] = uid_map[file]
            end
          end
        }
        reply[:output] = gear_map
        reply[:exitcode] = 0
      end

      #
      # Get all gears
      #
      def get_all_active_gears_action
        active_gears = {}
        dir = "/var/lib/openshift/"
        filelist = Dir.foreach(dir) { |file|
          if File.directory?(dir+file) and not File.symlink?(dir+file) and not file[0]=='.'
            state_file = File.join(dir, file, 'app-root', 'runtime', '.state')
            if File.exist?(state_file)
              state = File.read(state_file).chomp
              active = !('idle' == state || 'stopped' == state)
              active_gears[file] = nil if active
            end
          end
        }
        reply[:output] = active_gears
        reply[:exitcode] = 0
      end

      def handle_oo_job(parallel_job)
        job = parallel_job[:job]
        rc, output = handle_oo_cmd(job[:action], job[:args])
        parallel_job[:result_exit_code] = rc
        if rc == 0
          parallel_job[:result_stdout] = output
          parallel_job[:result_stderr] = ""
        else
          parallel_job[:result_stdout] = ""
          parallel_job[:result_stderr] = output
        end
      end

      #
      # Executes a list of jobs parallely and returns their results embedded in args
      #
      def execute_parallel_action        
        Log.instance.info("execute_parallel_action call / request = #{request.pretty_inspect}")
        #validate :joblist, /\A[\w\+\/= \{\}\"@\-\.:\'\\\n~,_]+\z/
        #validate :joblist, :shellsafe

        joblist = request[config.identity]
        pidlist = []
        inline_list = []
        joblist.each { |parallel_job|
          job = parallel_job[:job]
          cartridge = job[:cartridge]
          action = job[:action]
          args = job[:args]
          if cartridge == 'openshift-origin-node' && action != 'connector-execute'
            inline_list << parallel_job
          else
            begin
              if cartridge == 'openshift-origin-node' && action == 'connector-execute'
                pid, stdin, stdout, stderr = oo_connector_execute(action, args)
              else
                pid, stdout, stderr = execute_parallel_job(cartridge, action, args)
              end
            rescue Exception =>e
              parallel_job[:result_exit_code] = 127
              parallel_job[:result_stdout] = e.message
              parallel_job[:result_stderr] = e.message
              next
            end
            pidlist << [parallel_job, pid, stdout, stderr]
          end
        }

        # All the inline calls are made using multiple threads instead of processes
        in_threads = []
        inline_list.each do |parallel_job|
          # BZ 876942: Disable threading until we can explore proper concurrency management
          # in_threads << Thread.new(parallel_job) do |pj|   # BZ 876942
            pj = parallel_job                                # BZ 876942
            begin
              handle_oo_job(pj)
            rescue Exception => e
              pj[:result_exit_code] = 1
              pj[:result_stdout] = e.message
              pj[:result_stderr] = e.message
              next
            end
          # end                                              # BZ 876942
        end
        in_threads.each { |thr| thr.join }

        pidlist.each { |reap_args|
          pj, pid, sout, serr = reap_args
          reap_output(pj, pid, sout, serr)
        }
        Log.instance.info("execute_parallel_action call - 10 #{joblist}")
        reply[:output] = joblist
        reply[:exitcode] = 0
      end

      def execute_parallel_job(cartridge, action, args)
        pid, stdin, stdout, stderr = nil, nil, nil, nil
        if cartridge == 'openshift-origin-node' && action == 'connector-execute'
          cmd = "oo-#{action}"
          pid, stdin, stdout, stderr = Open4::popen4("/usr/bin/runcon -l s0-s0:c0.c1023 #{cmd} #{args} 2>&1")
        else
          if File.exists? "/usr/libexec/openshift/cartridges/#{cartridge}/info/hooks/#{action}"                
            pid, stdin, stdout, stderr = Open4::popen4ext(true, "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/#{cartridge}/info/hooks/#{action} #{args} 2>&1")
            #pid, stdin, stdout, stderr = Open4::popen4("/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/#{cartridge}/info/hooks/#{action} #{args} 2>&1")
          elsif File.exists? "/usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/hooks/#{action}"                
            pid, stdin, stdout, stderr = Open4::popen4ext(true, "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/hooks/#{action} #{args} 2>&1")
          else
            raise Exception.new("cartridge_do_action ERROR action '#{action}' not found.")
          end
        end
        stdin.close
        return pid, stdout, stderr
      end

      def reap_output(parallel_job, pid, stdout, stderr)
        ignored, status = Process::waitpid2 pid
        exitcode = status.exitstatus
        # Do this to avoid cartridges that might hold open stdout
        output = ""
        begin
          Timeout::timeout(5) do
            while (line = stdout.gets)
              output << line
            end
          end
        rescue Timeout::Error
          Log.instance.info("cartridge_do_action WARNING - stdout read timed out")
        end

        if exitcode == 0
          Log.instance.info("cartridge_do_action (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
        else
          Log.instance.info("cartridge_do_action ERROR (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
        end

        parallel_job[:result_stdout] = output
        parallel_job[:result_exit_code] = exitcode
      end
    end
  end
end
