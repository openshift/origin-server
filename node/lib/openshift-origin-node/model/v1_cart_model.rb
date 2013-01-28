require 'rubygems'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  class V1CartridgeModel
    include OpenShift::Utils::ShellExec

    def initialize(config, user, logger = nil)
      @config = config
      @user = user
      @logger = logger ||= Logger.new(STDOUT)
    end

    def get_manifest(cart)
      manifest_path = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'info', 'manifest.yml')
      YAML.load_file(manifest_path)
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
          @logger.debug("Executing cart tidy script #{tidy_script} in gear #{@uuid} as user #{@user.uid}:#{@user.gid}")
          run_as(@user.uid, @user.gid, tidy_script, gear_dir, false, 0, cart_tidy_timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          @logger.warn("Cartridge tidy operation failed on gear #{@uuid} for cart #{gear_dir}: #{e.message} (rc=#{e.rc})")
        end
      end
    end

    def add_cart(cart)
      # TODO: type to raise?
      raise 'add_cart is not implemented for V1 cartridge model'
    end

    def remove_cart(cart)
      raise 'remove_cart is not implements for V1 cartridge model'
    end
  end
end
