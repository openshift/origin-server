require 'open4'
require 'pp'
require 'parseconfig'
require 'shellwords'
require 'stickshift-controller'

module GearChanger
  class OddJobApplicationContainerProxy < StickShift::ApplicationContainerProxy
    attr_accessor :id
    def self.find_available_impl(node_profile=nil)
      OddJobApplicationContainerProxy.new('localhost')
    end

    def self.find_one_impl(node_profile=nil)
      OddJobApplicationContainerProxy.new('localhost')
    end

    def self.blacklisted_in_impl?(name)
      false
    end

    def initialize(id)
      @id = id
    end

    def reserve_uid
    end

    def unreserve_uid(uid)
    end

    def get_available_cartridges
      reply = exec_command('stickshift', 'cartridge-list', '--porcelain')
      result = parse_result(reply)
      cart_data = JSON.parse(result.resultIO.string)
      
      cart_data.map! do |cart_name|
        reply = exec_command('stickshift', 'cartridge-info', "--porcelain #{cart_name}")
        result = parse_result(reply)
        StickShift::Cartridge.new.from_descriptor(JSON.parse(result.resultIO.string))
      end

    end

    def create(app, gear)
      args = "--with-app-uuid '#{app.uuid}' --named '#{app.name}' --with-container-uuid '#{gear.uuid}' --with-namespace '#{app.domain.namespace}'"
      reply = exec_command("stickshift","app-create", args)
      parse_result(reply)
    end

    def destroy(app, gear)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}'"
      reply = exec_command("stickshift","app-destroy", args)
      parse_result(reply)
    end

    def add_authorized_ssh_key(app, gear, ssh_key, key_type=nil, comment=nil)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -s '#{ssh_key}'"
      args += " -t '#{key_type}'" if key_type
      args += " -m '-#{comment}'" if comment
      reply = exec_command("stickshift","authorized-ssh-key-add", args)
      parse_result(reply)
    end

    def remove_authorized_ssh_key(app, gear, ssh_key, comment=nil)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -s '#{ssh_key}'"
      args += " -m '-#{comment}'" if comment
      reply = exec_command("stickshift","authorized-ssh-key-remove", args)
      parse_result(reply)
    end

    def add_env_var(app, gear, key, value)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -k '#{key}' -v '#{value}'"
      reply = exec_command("stickshift","env-var-add", args)
      parse_result(reply)
    end

    def remove_env_var(app, gear, key)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -k '#{key}'"
      reply = exec_command("stickshift","env-var-remove", args)
      parse_result(reply)
    end

    def add_broker_auth_key(app, gear, iv, token)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -i '#{iv}' -t '#{token}'"
      reply = exec_command("stickshift","broker-auth-key-add", args)
      parse_result(reply)
    end

    def remove_broker_auth_key(app, gear)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}'"
      reply = exec_command("stickshift","broker-auth-key-remove", args)
      parse_result(reply)
    end

    def preconfigure_cartridge(app, gear, cart)
      Rails.logger.debug("Inside preconfigure_cartridge :: application: #{app.name} :: cartridge name: #{cart}")

      if framework_carts.include? cart
        run_cartridge_command(cart, app, gear, "preconfigure")
      else
        #no-op
        ResultIO.new
      end
    end

    def configure_cartridge(app, gear, cart, template_git_url=nil)
      Rails.logger.debug("Inside configure_cartridge :: application: #{app.name} :: cartridge name: #{cart}")

      result_io = ResultIO.new
      cart_data = nil

      if framework_carts.include? cart
        result_io = run_cartridge_command(cart, app, gear, "configure", template_git_url)
      elsif embedded_carts.include? cart
        result_io, cart_data = add_component(app, gear, cart)
      else
        #no-op
      end

      return result_io, cart_data
    end

    def deconfigure_cartridge(app, gear, cart)
      Rails.logger.debug("Inside deconfigure_cartridge :: application: #{app.name} :: cartridge name: #{cart}")

      if framework_carts.include? cart
        run_cartridge_command(cart, app, gear, "deconfigure")
      elsif embedded_carts.include? cart
        remove_component(app,gear,cart)
      else
        ResultIO.new
      end
    end

    def get_public_hostname
      "localhost"
    end

    def execute_connector(app, gear, cart, connector_name, input_args)
      args = "--gear-uuid '#{gear.uuid}' --cart-name '#{cart}' --hook-name '#{connector_name}' " + input_args.join(" ")
      reply = exec_command("stickshift","connector-execute", args)
      if reply and reply.length>0
        reply = reply[0]
        output = reply.results[:data][:output]
        exitcode = reply.results[:data][:exitcode]
        return [output, exitcode]
      end
      [nil, nil]
    end

    def start(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "start")
      elsif embedded_carts.include? cart
        start_component(app, gear, cart)
      else
        ResultIO.new
      end
    end

    def stop(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "stop")
      elsif embedded_carts.include? cart
        stop_component(app, gear, cart)
      else
        ResultIO.new
      end
    end

    def force_stop(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "force-stop")
      else
        ResultIO.new
      end
    end

    def restart(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "restart")
      elsif embedded_carts.include? cart
        restart_component(app, gear, cart)
      else
        ResultIO.new
      end
    end

    def reload(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "reload")
      elsif embedded_carts.include? cart
        reload_component(app, gear, cart)
      else
        ResultIO.new
      end
    end

    def status(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "status")
      elsif embedded_carts.include? cart
        component_status(app, gear, cart)
      else
        ResultIO.new
      end
    end

    def tidy(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "tidy")
      else
        ResultIO.new
      end
    end

    def threaddump(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "threaddump")
      else
        ResultIO.new
      end
    end

    def system_messages(app, gear, cart)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "system-messages")
      else
        ResultIO.new
      end
    end

    def expose_port(app, gear, cart)
      run_cartridge_command(cart, app, gear, "expose-port")
    end

    def conceal_port(app, gear, cart)
      run_cartridge_command(cart, app, gear, "conceal-port")
    end

    def show_port(app, gear, cart)
      run_cartridge_command(cart, app, gear, "show-port")
    end

    def add_alias(app, gear, cart, server_alias)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "add-alias", server_alias)
      else
        ResultIO.new
      end
    end

    def remove_alias(app, gear, cart, server_alias)
      if framework_carts.include?(cart)
        run_cartridge_command(cart, app, gear, "remove-alias", server_alias)
      else
        ResultIO.new
      end
    end

    def update_namespace(app, cart, new_ns, old_ns)
      if app.scalable
        app.gears.each { |gear|
          reply = exec_command(cart, 'update-namespace', "#{gear.name} #{new_ns} #{old_ns} #{gear.uuid}")
          parse_result(reply)
        }
      else
        reply = exec_command(cart, 'update-namespace', "#{app.name} #{new_ns} #{old_ns} #{app.uuid}")
        parse_result(reply)
      end
    end

    def framework_carts
      @framework_carts ||= CartridgeCache.cartridge_names('standalone')
    end

    def embedded_carts
      @embedded_carts ||= CartridgeCache.cartridge_names('embedded')
    end

    def add_component(app, gear, component)
      reply = ResultIO.new
      begin
        reply.append run_cartridge_command('embedded/' + component, app, gear, 'configure')
      rescue Exception => e
        begin
          Rails.logger.debug "DEBUG: Failed to embed '#{component}' in '#{app.name}' for user '#{app.user.login}'"
          reply.debugIO << "Failed to embed '#{component} in '#{app.name}'"
          reply.append run_cartridge_command('embedded/' + component, app, gear, 'deconfigure')
        ensure
          raise
        end
      end

      component_details = reply.appInfoIO.string.empty? ? '' : reply.appInfoIO.string
      reply.debugIO << "Embedded app details: #{component_details}"
      [reply, component_details]
    end

    def remove_component(app, gear, component)
      Rails.logger.debug "DEBUG: Deconfiguring embedded application '#{component}' in application '#{app.name}' on node '#{@id}'"
      return run_cartridge_command('embedded/' + component, app, gear, 'deconfigure')
    end

    def start_component(app, gear, component)
      run_cartridge_command('embedded/' + component, app, gear, "start")
    end

    def stop_component(app, gear, component)
      run_cartridge_command('embedded/' + component, app, gear, "stop")
    end

    def restart_component(app, gear, component)
      run_cartridge_command('embedded/' + component, app, gear, "restart")
    end

    def reload_component(app, gear, component)
      run_cartridge_command('embedded/' + component, app, gear, "reload")
    end

    def component_status(app, gear, component)
      run_cartridge_command('embedded/' + component, app, gear, "status")
    end

    def self.execute_parallel_jobs_impl(handle)
      proxy_impl = StickShift::ApplicationContainerProxy.find_one(nil)
      proxy_impl.execute_parallel_jobs_impl(handle)
    end

    def execute_parallel_jobs_impl(handle)
      id_list = handle.keys
      id_list.each { |id| 
        begin
          joblist = handle[id]

          pidlist = []
          joblist.each { |parallel_job|
            
            job = parallel_job[:job]
            begin
              reply = exec_command(job[:cartridge], job[:action], job[:args])
              parallel_job[:result_exit_code] = reply[:exitcode]
              parallel_job[:result_stdout] = reply[:output]
            rescue Exception =>e
              parallel_job[:result_exit_code] = 127
              parallel_job[:result_stdout] = e.message
              parallel_job[:result_stderr] = e.message
              next
            end
          }
        end
      }
    end

    def run_cartridge_command(framework, app, gear, command, arg=nil)
      if app.scalable and framework!=app.proxy_cartridge
        appname = gear.uuid[0..9]
      else
        appname = app.name
      end
      arguments = "'#{appname}' '#{app.domain.namespace}' '#{gear.uuid}'"
      arguments += " '#{arg}'" if arg

      result = exec_command(framework, command, arguments)
      resultIO = parse_result(result, app, command)

      if resultIO.exitcode != 0
        resultIO.debugIO << "Cartridge return code: " + resultIO.exitcode.to_s
        begin
          raise StickShift::NodeException.new("Node execution failure (invalid exit code from node).  If the problem persists please contact Red Hat support.", 143, resultIO)
        rescue StickShift::NodeException => e
          if command == 'deconfigure'
            if framework.start_with?('embedded/')
              if has_embedded_app?(app.uuid, framework[9..-1])
                raise
              else
                Rails.logger.debug "DEBUG: Component '#{framework}' in application '#{app.name}' not found on node '#{@id}'.  Continuing with deconfigure."
              end
            else
              if has_app?(app.uuid, app.name)
                raise
              else
                Rails.logger.debug "DEBUG: Application '#{app.name}' not found on node '#{@id}'.  Continuing with deconfigure."
              end
            end
          else
            raise
          end
        end
      end
      resultIO
    end

    def exec_command(cartridge, action, args)
      reply = {}
      exitcode = 1
      pid, stdin, stdout, stderr = nil, nil, nil, nil

      encoded_command = Shellwords::shellescape({:cartridge => cartridge, :action => action, :args => args}.to_json)
      Bundler.with_clean_env {
        pid, stdin, stdout, stderr = Open4::popen4("/usr/bin/oddjob_request -s com.redhat.oddjob.stickshift -o /com/redhat/oddjob/stickshift -i com.redhat.oddjob.stickshift run_command #{encoded_command} 2>&1")
        stdin.close
        ignored, status = Process::waitpid2 pid
        exitcode = status.exitstatus
      }

      # Do this to avoid cartridges that might hold open stdout
      command_stdout = ""
      begin
        Timeout::timeout(5) do
          while (line = stdout.gets)
            command_stdout << line
          end
        end
      rescue Timeout::Error
        Rails.logger.debug("exec_command WARNING - stdout read timed out")
      end

      if exitcode == 0
        command_output = JSON.parse(command_stdout)
        output = command_output['output']
        exitcode = command_output['exitcode']
      else
        output = command_stdout
      end

      reply[:output] = output
      reply[:exitcode] = exitcode
      Rails.logger.error("exec_command failed #{exitcode}.  Output #{output}") unless exitcode == 0
      reply
    end

    def parse_result(cmd_result, app=nil, command=nil)
      result = ResultIO.new

      Rails.logger.debug("cmd_reply:  #{cmd_result}")
      output = nil
      if (cmd_result && cmd_result.has_key?(:output))
        output = cmd_result[:output]
        result.exitcode = cmd_result[:exitcode]
      else
        raise StickShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
      end

      if output && !output.empty?
        output.each_line do |line|
          if line =~ /^CLIENT_(MESSAGE|RESULT|DEBUG|ERROR): /
            if line =~ /^CLIENT_MESSAGE: /
              result.messageIO << line['CLIENT_MESSAGE: '.length..-1]
            elsif line =~ /^CLIENT_RESULT: /
              result.resultIO << line['CLIENT_RESULT: '.length..-1]
            elsif line =~ /^CLIENT_DEBUG: /
              result.debugIO << line['CLIENT_DEBUG: '.length..-1]
            else
              result.errorIO << line['CLIENT_ERROR: '.length..-1]
            end
          elsif line =~ /^APP_INFO: /
            result.appInfoIO << line['APP_INFO: '.length..-1]
          elsif result.exitcode == 0
            if line =~ /^SSH_KEY_(ADD|REMOVE): /
              if line =~ /^SSH_KEY_ADD: /
                key = line['SSH_KEY_ADD: '.length..-1].chomp
                result.cart_commands.push({:command => "SYSTEM_SSH_KEY_ADD", :args => [key]})
              else
                result.cart_commands.push({:command => "SYSTEM_SSH_KEY_REMOVE", :args => []})
              end
            elsif line =~ /^ENV_VAR_(ADD|REMOVE): /
              if line =~ /^ENV_VAR_ADD: /
                env_var = line['ENV_VAR_ADD: '.length..-1].chomp.split('=')
                result.cart_commands.push({:command => "ENV_VAR_ADD", :args => [env_var[0], env_var[1]]})
              else
                key = line['ENV_VAR_REMOVE: '.length..-1].chomp
                result.cart_commands.push({:command => "ENV_VAR_REMOVE", :args => [key]})
              end
            elsif line =~ /^BROKER_AUTH_KEY_(ADD|REMOVE): /
              if line =~ /^BROKER_AUTH_KEY_ADD: /
                result.cart_commands.push({:command => "BROKER_KEY_ADD", :args => []})
              else
                result.cart_commands.push({:command => "BROKER_KEY_REMOVE", :args => []})
              end
            elsif line =~ /^ATTR: /
              attr = line['ATTR: '.length..-1].chomp.split('=')
              result.cart_commands.push({:command => "ATTR", :args => [attr[0], attr[1]]})
            else
              #result.debugIO << line
            end
          else # exitcode != 0
            result.debugIO << line
            Rails.logger.debug "DEBUG: server results: " + line
          end
        end
      end
      result
    end

    #
    # Returns whether this app is present
    #
    def has_app?(app_uuid, app_name)
      if File.exist?("/var/lib/stickshift/#{app_uuid}/#{app_name}")
        return true
      end
      return false
    end

    #
    # Returns whether this embedded app is present
    #
    def has_embedded_app?(app_uuid, embedded_type)
      if File.exist?("/var/lib/stickshift/#{app_uuid}/#{embedded_type}")
        return true
      end
      return false
    end

    def get_env_var_add_job(app, gear, key, value)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -k '#{key}' -v '#{value}'"
      job = RemoteJob.new('stickshift', 'env-var-add', args)
      job
    end
    
    def get_env_var_remove_job(app, gear, key)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -k '#{key}'"
      job = RemoteJob.new('stickshift', 'env-var-remove', args)
      job
    end

    def get_add_authorized_ssh_key_job(app, gear, ssh_key, key_type=nil, comment=nil)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -s '#{ssh_key}'"
      args += " -t '#{key_type}'" if key_type
      args += " -m '-#{comment}'" if comment
      job = RemoteJob.new('stickshift', 'authorized-ssh-key-add', args)
      job
    end
    
    def get_remove_authorized_ssh_key_job(app, gear, ssh_key, comment=nil)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -s '#{ssh_key}'"
      args += " -m '-#{comment}'" if comment
      job = RemoteJob.new('stickshift', 'authorized-ssh-key-remove', args)
      job
    end

    def get_broker_auth_key_add_job(app, gear, iv, token)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}' -i '#{iv}' -t '#{token}'"
      job = RemoteJob.new('stickshift', 'broker-auth-key-add', args)
      job
    end

    def get_broker_auth_key_remove_job(app, gear)
      args = "--with-app-uuid '#{app.uuid}' --with-container-uuid '#{gear.uuid}'"
      job = RemoteJob.new('stickshift', 'broker-auth-key-remove', args)
      job
    end

    def get_execute_connector_job(app, gear, cart, connector_name, input_args)
      args = "--gear-uuid '#{gear.uuid}' --cart-name '#{cart}' --hook-name '#{connector_name}' " + input_args.join(" ")
      job = RemoteJob.new('stickshift', 'connector-execute', args)
      job
    end

  end
end
