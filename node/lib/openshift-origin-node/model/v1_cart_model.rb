require 'rubygems'
require 'open4'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/sanitize'

module OpenShift
  class V1CartridgeModel
    include OpenShift::Utils::ShellExec
    include NodeLogger

    def initialize(config, user)
      @config = config
      @user = user
    end

    def get_cartridge(cart_name)
      begin
        manifest_path = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart_name, 'info', 'manifest.yml')
        return OpenShift::Runtime::Manifest.new(manifest_path)
      rescue => e
        logger.error(e.backtrace)
        raise "Failed to load cart manifest from #{manifest_path} for cart #{cart_name} in gear #{@user.uuid}: #{e.message}"
      end
    end

    def stop_lock(cartridge_name=nil)
      if cartridge_name.nil?
        # Return a cartridge in the gear; the primary if there is one.
        each_cartridge do |cartridge|
          cartridge_name = cartridge.name
          break if cartridge.deployable?
        end
      end
      if cartridge_name.nil?
        raise "Partial gear with no cartridges: #{@user.uuid}"
      end
      File.join(@user.homedir, cartridge_name, 'run', 'stop_lock')
    end

    def stop_lock?(cartridge_name=nil)
      File.exists?(stop_lock(cartridge_name))
    end

    ##
    # Writes the +stop_lock+ file and changes its ownership to the gear user.
    def create_stop_lock
      unless stop_lock?
        mcs_label = Utils::SELinux.get_mcs_label(@user.uid)
        File.new(stop_lock, File::CREAT|File::TRUNC|File::WRONLY, 0644).close()
        PathUtils.oo_chown(@user.uid, @user.gid, stop_lock)
        Utils::SELinux.set_mcs_label(mcs_label, stop_lock)
      end
    end

    ##
    # Yields a +Cartridge+ instance for each cartridge in the gear.
    def each_cartridge
      Dir[PathUtils.join(@user.homedir, "*")].each do |cart_dir|
        next if cart_dir.end_with?('app-root')
        next if cart_dir.end_with?('git')
        next if not File.directory? cart_dir

        cartridge = get_cartridge(File.basename(cart_dir))
        yield cartridge
      end
    end

    ##
    # Returns the +Cartridge+ in the gear whose +primary+ flag is set to true,
    #
    # Raises an exception if no such cartridge is present.
    def primary_cartridge
      cart = nil
      each_cartridge do |cartridge|
        cart = cartridge
        break if cartridge.deployable?
      end

      if cart.nil?
        raise "No primary cartridge found on gear #{@user.uuid}"
      end

      cart
    end

    def stop_gear(options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      stop_cartridge(primary_cartridge.name, options)
    end

    def start_gear(options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      start_cartridge('start', primary_cartridge.name, options)
    end

    def start_cartridge(type, cartridge, options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      if not options[:user_initiated] and stop_lock?(cartridge)
        return "Not starting cartridge #{cartridge} because the application was explicitly stopped by the user"
      end

      do_control(type, cartridge)
    end

    def stop_cartridge(cartridge, options={})
      options[:user_initiated] = true if not options.has_key?(:user_initiated)

      if not options[:user_initiated] and stop_lock?(cartridge)
        return "Not stopping cartridge #{cartridge} because the application was explicitly stopped by the user"
      end

      buffer = do_control('stop', cartridge)

      if not options[:user_initiated] and stop_lock?(cartridge)
        File.unlink(stop_lock(cartridge))
      end

      buffer
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

    def configure(cart_name, template_git_url, manifest)
      raise "Downloaded cartridges are not supported" if manifest

      do_control('configure', cart_name, "#{@user.container_name} #{@user.namespace} #{@user.container_uuid} #{template_git_url}")
    end
    
    def resolve_application_dependencies(cart_name)    
      do_control('resolve-application-dependencies', 'abstract', "#{@user.container_name} #{@user.namespace} #{@user.container_uuid}")
    end

    def deconfigure(cart_name)
      do_control('deconfigure', cart_name)
    end

    def unsubscribe(cart_name, pub_cart_name)
    end

    def deploy_httpd_proxy(cart_name)
      do_control('deploy-httpd-proxy', cart_name)
    end

    def deploy(cart_name)
      @cartridge_model.do_control("deploy", cart_name)
    end

    def remove_httpd_proxy(cart_name)
      do_control('remove-httpd-proxy', cart_name)
    end

    def restart_httpd_proxy(cart_name)
      do_control('restart-httpd-proxy', cart_name)
    end

    def connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      # pub_cart_name and connection_type unused in v1.
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
      output = ""
      begin
        Timeout::timeout(120) do
          while (line = stdout.gets)
            output << line
          end
        end
      rescue Timeout::Error
        logger.info("WARNING: stdout read timed out, killing #{pid} and its child processes")
        OpenShift::Utils::ShellExec.kill_process_tree(pid)
      end

      ignored, status = Process::waitpid2 pid
      exitcode = status.exitstatus

      if exitcode == 0
        logger.info("(#{exitcode})\n------\n#{Runtime::Utils.sanitize_credentials(output)}\n------)")
      else
        logger.info("ERROR: (#{exitcode})\n------\n#{Runtime::Utils.sanitize_credentials(output)}\n------)")
      end
      return exitcode, output
    end

    def snapshot
      raise NotImplementedError.new('V1 snapshot is not implemented via ApplicationContainer')
    end

    def lock_files(cartridge)
      raise NotImplementedError.new('V1 lock_files is not implemented via ApplicationContainer')
    end

    def snapshot_exclusions(cartridge)
      raise NotImplementedError.new('V1 snapshot_exclusions is not implemented via ApplicationContainer')
    end

    def setup_rewritten(cartridge)
      raise NotImplementedError.new('V1 setup_rewritten is not implemented via ApplicationContainer')
    end

    def restore_transforms(cartridge)
      raise NotImplementedError.new('V1 restore_transforms is not implemented via ApplicationContainer')
    end

    def process_templates(cartridge)
      raise NotImplementedError.new('V1 process_templates is not implemented via ApplicationContainer')
    end
  end
end
