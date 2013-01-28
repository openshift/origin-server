require 'rubygems'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  class V2CartridgeModel
    def initialize(config, user, logger = nil)
      @config = config
      @user = user
      @logger = logger ||= Logger.new(STDOUT)
      @timeout = 30
    end

    def get_manifest(cart)
      manifest_path = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'metadata', 'manifest.yml')
      YAML.load_file(manifest_path)
    end

    def destroy
      Dir.entries(@user.homedir).each do |gear_subdir|
        teardown_hook = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'bin', 'teardown')

        next unless File.exists?(teardown_hook)

        begin
          # Execute the hook in the context of the gear user
          @logger.debug("Executing cart teardown hook #{teardown_hook} in gear #{@uuid} as user #{@user.uid}:#{@user.gid}")
          run_as(@user.uid, @user.gid, teardown_hook, gear_dir, false, 0, timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          @logger.warn("Cartridge tidy operation failed on gear #{@uuid} for cart #{gear_dir}: #{e.message} (rc=#{e.rc})")
        end
      end

      @user.destroy
    end

    def tidy
      # TODO: introduce better implementation using Cartridge model class
      Dir.entries(@user.homedir).each do |gear_subdir|
        tidy_script = File.join(@config.get('CARTRIDGE_BASE_PATH'), cart, 'bin', 'control') + ' tidy'
          
        next unless File.exists?(tidy_script)

        begin
          # Execute the hook in the context of the gear user
          @logger.debug("Executing cart tidy script #{tidy_script} in gear #{@uuid} as user #{@user.uid}:#{@user.gid}")
          run_as(@user.uid, @user.gid, tidy_script, gear_dir, false, 0, timeout)
        rescue OpenShift::Utils::ShellExecutionException => e
          @logger.warn("Cartridge tidy operation failed on gear #{@uuid} for cart #{gear_dir}: #{e.message} (rc=#{e.rc})")
        end
      end
    end

    def add_cart(cart)

    end

    def remove_cart(cart)

    # Run code block against each cartridge in gear
    #
    # @param  [block]  Code block to process cartridge
    # @yields [String] cartridge directory for each cartridge in gear
    def process_cartridges
      Dir[File.join(@user.homedir, "*-*")].each do |cart_dir|
        next if "app-root" == cart_dir ||
            (not File.directory? cart_dir)
        yield cart_dir
      end
    end
  end
end