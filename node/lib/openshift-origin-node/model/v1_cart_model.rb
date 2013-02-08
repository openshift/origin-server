require 'rubygems'
require 'open4'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'

module OpenShift
  class V1CartridgeModel
    include OpenShift::Utils::ShellExec
    include NodeLogger

    attr_reader :logger

    def initialize(config, user)
      @config = config
      @user = user
    end

    def get_cartridge(cart_name)
      begin
        manifest_path = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart_name, 'info', 'manifest.yml')
        manifest = YAML.load_file(manifest_path)
        return OpenShift::Runtime::Cartridge.new(manifest)
      rescue => e
        logger.error(e.backtrace)
        raise "Failed to load cart manifest from #{manifest_path} for cart #{cart_name} in gear #{@user.uuid}: #{e.message}"
      end
    end

    def destroy(skip_hooks = false)
      hook_timeout=30

      output = ""
      errout = ""
      retcode = 0

      hooks={}
      ["pre", "post"].each do |hooktype|
        if @user.homedir.nil? || ! File.exists?(@user.homedir)
          hooks[hooktype]=[]
        else
          hooks[hooktype] = Dir.entries(@user.homedir).map { |cart|
            [ File.join(@config.get("CARTRIDGE_BASE_PATH"),cart,"info","hooks","#{hooktype}-destroy"),
              File.join(@config.get("CARTRIDGE_BASE_PATH"),"embedded",cart,"info","hooks","#{hooktype}-destroy"),
            ].select { |hook| File.exists? hook }[0]
          }.select { |hook|
            not hook.nil?
          }.map { |hook|
            "#{hook} #{@user.container_name} #{@user.namespace} #{@user.container_uuid}"
          }
        end
      end

      unless skip_hooks
        hooks["pre"].each do | cmd |
          out,err,rc = shellCmd(cmd, "/", true, 0, hook_timeout)
          errout << err if not err.nil?
          output << out if not out.nil?
          retcode = 121 if rc != 0
        end
      end

      @user.destroy

      unless skip_hooks
        hooks["post"].each do | cmd |
          out,err,rc = shellCmd(cmd, "/", true, 0, hook_timeout)
          errout << err if not err.nil?
          output << out if not out.nil?
          retcode = 121 if rc != 0
        end
      end

      return output, errout, retcode
    end

    def tidy
      # Execute the tidy hooks in any installed carts, in the context
      # of the gear user. For now, we detect cart installations by iterating
      # over the gear subdirs and using the dir names to construct a path
      # to cart scripts in the base cartridge directory. If such a file exists,
      # it's assumed the cart is installed on the gear.
      cart_tidy_timeout = 30
      Dir.entries(@user.homedir).each do |gear_subdir|
        tidy_script = File.join(@config.get("CARTRIDGE_BASE_PATH"), gear_subdir, "info", "hooks", "tidy")
          
        next unless File.exists?(tidy_script)

        begin
          # Execute the hook in the context of the gear user
          logger.debug("Executing cart tidy script #{tidy_script} in gear #{@user.uuid} as user #{@user.uid}:#{@user.gid}")
          OpenShift::Utils::ShellExec.run_as(@user.uid, @user.gid, tidy_script, @user.homedir, false, 0, cart_tidy_timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          logger.warn("Cartridge tidy operation failed on gear #{@user.uuid} for cart #{gear_subdir}: #{e.message} (rc=#{e.rc})")
        end
      end
    end

    def update_namespace(cart_name, old_namespace, new_namespace)
      do_control('update-namespace', cart_name, "#{@user.container_name} #{new_namespace} #{old_namespace} #{@user.container_uuid}")
    end

    def configure(cart_name, template_git_url)
      do_control('configure', cart_name, "#{@user.container_name} #{@user.namespace} #{@user.container_uuid} #{template_git_url}")
    end

    def deconfigure(cart_name)
      do_control('deconfigure', cart_name)
    end

    def deploy_httpd_proxy(cart_name)
      do_control('deploy-httpd-proxy', cart_name)
    end

    def remove_httpd_proxy(cart_name)
      do_control('remove-httpd-proxy', cart_name)
    end

    def restart_httpd_proxy(cart_name)
      do_control('restart-httpd-proxy', cart_name)
    end

    def move(cart_name, idle)
      args = idle ? "#{@user.container_name} #{@user.namespace} #{@user.container_uuid} --idle"
        : "#{@user.container_name} #{@user.namespace} #{@user.container_uuid}"

      do_control('move', cart_name, args)
    end

    def pre_move(cart_name)
      do_control('pre-move', cart_name)
    end

    def post_move(cart_name)
      do_control('post-move', cart_name)
    end

    def connector_execute(cart_name, connector, args)
      do_control(connector, cart_name, args, "connection-hooks")
    end

    def do_control(action, cart_name, args=nil, hook_dir="hooks")
      args = args ||= "#{@user.container_name} #{@user.namespace} #{@user.container_uuid}"

      exitcode, output = handle_cartridge_action(cart_name, action, hook_dir, args)

      if exitcode != 0
        raise OpenShift::Utils::ShellExecutionException.new(
          "Control action '#{action}' returned an error. rc=#{exitcode}", exitcode, output)
      end

      output
    end

    #------------------------------------
    # XXX: below code ripped from mcollective agent

    # pre-refactor, V1 cartridges were added by the mcollective agent by 
    # calling the configure hook directly.
    def handle_cartridge_action(cartridge, action, hook_dir, args)
      exitcode = 0
      output = ""

      if File.exists? "/usr/libexec/openshift/cartridges/#{cartridge}/info/#{hook_dir}/#{action}"
        cart_cmd = "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/#{cartridge}/info/#{hook_dir}/#{action} #{args} 2>&1"
        logger.info("handle_cartridge_action executing #{cart_cmd}")
        pid, stdin, stdout, stderr = Open4::popen4ext(true, cart_cmd)
      elsif File.exists? "/usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/hooks/#{action}"
        cart_cmd = "/usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/#{cartridge}/info/#{hook_dir}/#{action} #{args} 2>&1"
        logger.info("handle_cartridge_action executing #{cart_cmd}")
        pid, stdin, stdout, stderr = Open4::popen4ext(true, cart_cmd)
      else
        exitcode = 127
        output = "ERROR: action '#{action}' not found."
      end
      exitcode, output = complete_process_gracefully(pid, stdin, stdout) if exitcode == 0

      #XXX: account for run_hook vs. run_hook_output in test.
      return exitcode, output
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
        logger.info("WARNING: stdout read timed out")
      end

      if exitcode == 0
        logger.info("(#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
      else
        logger.info("ERROR: (#{exitcode})\n------\n#{cleanpwd(output)}\n------)")
      end
      return exitcode, output
    end

    def cleanpwd(arg)
      arg.gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]').gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i,'\\1[HIDDEN]')
    end

  end
end
