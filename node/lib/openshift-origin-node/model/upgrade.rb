require 'rubygems'
require 'etc'
require 'fileutils'
require 'socket'
require 'parseconfig'
require 'pp'

require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/upgrade_progress'
require 'openshift-origin-node/utils/upgrade_itinerary'
require 'openshift-origin-node/utils/hourglass'
require 'openshift-origin-common'
require 'net/http'
require 'uri'
require 'json'

module OpenShift
  module Runtime
    class V2UpgradeCartridgeModel < V2CartridgeModel
      def gear_status
        output = ''
        problem = false

        each_cartridge do |cartridge|
          cart_status = do_control('status', cartridge)

          cart_status_msg = "[OK]"
          if cart_status !~ /running|enabled|Tail of JBoss|status output from the mock cartridge/i
            problem = true
            cart_status_msg = "[PROBLEM]"
          end

          output << "Cart status for #{cartridge.name} #{cart_status_msg}: #{cart_status}\n"
        end

        return [problem, output]
      end
    end
  end
end

module OpenShift::Runtime::Utils
  class UpgradeApplicationState < ApplicationState
    def initialize(container, state_file = '.state')
      @container = container
      @uuid = container.uuid

      config      = OpenShift::Config.new
      @state_file = File.join(config.get("GEAR_BASE_DIR"), uuid, "app-root", "runtime", state_file)
    end
  end
end

module OpenShift
  module Runtime
    class Upgrader
      PREUPGRADE_STATE = '.preupgrade_state'

      @@gear_extension_present = false
      gear_extension_path = OpenShift::Config.new.get('GEAR_UPGRADE_EXTENSION')
      if gear_extension_path && File.exists?("#{gear_extension_path}.rb")
        @@gear_extension_present = require gear_extension_path
        raise "#{gear_extension_path} exists and failed to load" unless @@gear_extension_present
      end

      attr_reader :uuid, :application_uuid, :secret_token, :namespace, :version, :hostname, 
                  :ignore_cartridge_version, :gear_home, :gear_env, :progress, :container, 
                  :gear_extension, :config, :hourglass

      def initialize(uuid, application_uuid, secret_token, namespace, version, hostname, ignore_cartridge_version, hourglass = nil)
        @uuid = uuid
        @application_uuid = application_uuid
        @secret_token = secret_token
        @namespace = namespace
        @version = version
        @hostname = hostname
        @ignore_cartridge_version = ignore_cartridge_version
        @config = OpenShift::Config.new
        @hourglass = hourglass || OpenShift::Runtime::Utils::Hourglass.new(235)

        gear_base_dir = @config.get('GEAR_BASE_DIR')
        @gear_home = PathUtils.join(gear_base_dir, uuid)
        @gear_env = Utils::Environ.for_gear(gear_home)
        @progress = Utils::UpgradeProgress.new(gear_base_dir, gear_home, uuid)
        @container = ApplicationContainer.from_uuid(uuid, @hourglass)
        @gear_extension = nil
      end

      def reload_gear_env
        @gear_env = Utils::Environ.for_gear(@gear_home)
      end

      #
      # This method implements the version-to-version upgrade for cartridges.
      #
      # Note: The upgrade method must be reentrant, meaning it should be able to
      # be called multiple times on the same gears.  Each time having failed
      # at any point and continue to pick up where it left off or make
      # harmless changes the 2-n times around.
      #
      def execute
        result = {
          gear_uuid: @uuid,
          hostname: @hostname,
          steps: [],
          upgrade_complete: false,
          errors: [],
          warnings: [],
          itinerary: {},
          times: {},
          log: nil
        }

        if !File.directory?(gear_home) || File.symlink?(gear_home)
          result[:errors] << "Application not found to upgrade: #{gear_home}"
          return result
        end

        gear_env = OpenShift::Runtime::Utils::Environ.for_gear(gear_home)
        unless gear_env.key?('OPENSHIFT_GEAR_NAME') && gear_env.key?('OPENSHIFT_APP_NAME')
          result[:warnings] << "Missing OPENSHIFT_GEAR_NAME and OPENSHIFT_APP_NAME variables"
          result[:upgrade_complete] = true
          return result
        end

        begin
          load_gear_extension
        rescue => e
          result[:errors] << e.message
          return result
        end

        begin
          initialize_metadata_store
        rescue => e
          result[:errors] << "Error initializing metadata store: #{e.message}"
          return result
        end

        begin
          start_time = timestamp
          result[:times][:start_time] = start_time
          restart_time = 0

          progress.log "Beginning #{version} upgrade for #{uuid}"

          inspect_gear_state
          gear_pre_upgrade

          itinerary = compute_itinerary
          result[:itinerary] = itinerary.entries

          restart_time = upgrade_cartridges(itinerary)
          result[:times][:restart] = restart_time

          gear_post_upgrade

          if itinerary.has_incompatible_upgrade?
            validate_gear

            if progress.complete? 'validate_gear'
              cleanup
            end
          else
            cleanup
          end

          result[:upgrade_complete] = true
        rescue OpenShift::Runtime::Utils::ShellExecutionException => e
          progress.log "Caught an exception during upgrade: #{e.message}"
          result[:errors] << {
            :rc => e.rc,
            :stdout => e.stdout,
            :stderr => e.stderr,
            :message => e.message,
            :backtrace => e.backtrace.join("\n")
          }
        rescue Exception => e
          progress.log "Caught an exception during upgrade: #{e.message}"
          result[:errors] << {
            :message => e.message,
            :backtrace => e.backtrace.join("\n")
          }
        ensure
          total_time = timestamp - start_time
          progress.log "Total upgrade time on node (ms): #{total_time}"
          result[:times][:upgrade_on_node_measured_from_node] = total_time
        end

        result[:steps] = progress.steps
        result[:log] = progress.buffer

        result
      end

      def load_gear_extension
        return unless @@gear_extension_present

        begin
          if !OpenShift::GearUpgradeExtension.respond_to?(:version)
            raise "Gear upgrade extension must respond to version"
          end

          extension_version = OpenShift::GearUpgradeExtension.version

          if version != extension_version
            progress.log "Version mismatch between supplied release version (#{version}) and extension version (#{extension_version})"
            return  
          end
        rescue NameError => e
          raise "Unable to resolve OpenShift::GearUpgradeExtension: #{e.message}"
        end

        begin
          @gear_extension = OpenShift::GearUpgradeExtension.new(self)
        rescue Exception => e
          raise "Unable to instantiate gear upgrade extension: #{e.message}\n#{e.backtrace}"
        end
      end

      #
      # Initialize the metadata store for this gear, if it does not exist.
      #
      def initialize_metadata_store
        runtime_dir = File.join(gear_home, %w(app-root runtime))

        if !File.exists?(runtime_dir)
          log "Creating runtime directory #{runtime_dir} for #{gear_home} because it does not exist"
          FileUtils.mkpath(runtime_dir)
          FileUtils.chmod_R(0o750, runtime_dir)
          PathUtils.oo_chown_R(uuid, uuid, runtime_dir)
          mcs_label = OpenShift::Runtime::Utils::SELinux::get_mcs_label(uuid)
          OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(mcs_label, runtime_dir)
        end
      end

      #
      # Execute the gear extension's 'pre_upgrade' method, if defined.
      #
      def gear_pre_upgrade
        if !gear_extension.nil? && gear_extension.respond_to?(:pre_upgrade)
          progress.step 'pre_upgrade' do
            gear_extension.pre_upgrade(progress)
          end
        end
      end

      #
      # Execute the gear extension's 'post_upgrade' method, if defined.
      #
      def gear_post_upgrade
        if !gear_extension.nil? && gear_extension.respond_to?(:post_upgrade)
          progress.step 'post_upgrade' do
            gear_extension.post_upgrade(progress) 
          end
        end
      end

      #
      # Map IDENT info from old manifest values to new manifest values
      #
      def gear_map_ident(ident)
        if !gear_extension.nil? && gear_extension.respond_to?(:map_ident)
          gear_extension.map_ident(progress, ident)
        else
          OpenShift::Runtime::Manifest.parse_ident(ident)
        end
      end

      #
      # Compute the upgrade itinerary for the gear
      #
      def compute_itinerary
        progress.step "compute_itinerary" do |context, errors|
          itinerary            = OpenShift::Runtime::UpgradeItinerary.new(gear_home)
          state                = OpenShift::Runtime::Utils::ApplicationState.new(container)
          cartridge_model      = OpenShift::Runtime::V2UpgradeCartridgeModel.new(config, container, state, hourglass)
          cartridge_repository = OpenShift::Runtime::CartridgeRepository.instance

          cartridge_model.each_cartridge do |manifest|
            cartridge_path = File.join(gear_home, manifest.directory)

            if !File.directory?(cartridge_path)
              progress.log "Skipping upgrade for #{manifest.name}: cartridge manifest does not match gear layout: #{cartridge_path} is not a directory"
              next
            end

            ident_path                               = Dir.glob(File.join(cartridge_path, 'env', 'OPENSHIFT_*_IDENT')).first
            ident                                    = IO.read(ident_path)
            vendor, name, version, cartridge_version = gear_map_ident(ident)

            unless vendor == 'redhat'
              progress.log "No upgrade available for cartridge #{ident}, #{vendor} not supported."
              next
            end

            next_manifest = cartridge_repository.select(name, version)
            unless next_manifest
              progress.log "No upgrade available for cartridge #{ident}, cartridge not found in repository."
              next
            end

            unless next_manifest.versions.include?(version)
              progress.log "No upgrade available for cartridge #{ident}, version #{version} not in #{next_manifest.versions}"
              next
            end

            if next_manifest.cartridge_version == cartridge_version
              if ignore_cartridge_version
                progress.log "Refreshing cartridge #{ident}, ignoring cartridge version."
              else
                progress.log "No upgrade required for cartridge #{ident}, already at latest version #{cartridge_version}."
                next
              end
            end

            upgrade_type = UpgradeType::INCOMPATIBLE

            if next_manifest.compatible_versions.include?(cartridge_version)
              upgrade_type = UpgradeType::COMPATIBLE
            end

            progress.log "Creating itinerary entry for #{upgrade_type.downcase} upgrade of #{ident}"
            itinerary.create_entry("#{name}-#{version}", upgrade_type)
          end

          itinerary.persist
        end

        UpgradeItinerary.for_gear(gear_home)
      end

      #
      # If the gear extension defines an upgrade method for the gear, run it.
      #
      def pre_cartridge_upgrade(itinerary)
        if !gear_extension.nil? && gear_extension.respond_to(:upgrade_gear)
          progress.step 'pre_cartridge_upgrade' do
            gear_extension.pre_cartridge_upgrade(progress, itinerary)
          end
        end
      end

      def post_cartridge_upgrade(itinerary)
        if !gear_extension.nil? && gear_extension.respond_to(:upgrade_gear)
          progress.step 'post_cartridge_upgrade' do
            gear_extension.post_cartridge_upgrade(progress, itinerary)
          end
        end
      end

      #
      # Gear-level upgrade script:
      #
      # 1. For each cartridge in the upgrade itinerary:
      #   1. Upgrade the cartridge to the new version
      #   2. Rebuild the cartridge ident, if applicable
      #
      def upgrade_cartridges(itinerary)
        progress.log "Migrating gear at #{gear_home}"

        state                = OpenShift::Runtime::Utils::ApplicationState.new(container)
        cartridge_model      = OpenShift::Runtime::V2UpgradeCartridgeModel.new(config, container, state, hourglass)
        cartridge_repository = OpenShift::Runtime::CartridgeRepository.instance
        restart_required     = false
        restart_time         = 0

        reset_quota, reset_block_quota, reset_inode_quota = relax_quota

        begin
          if itinerary.has_incompatible_upgrade?
            stop_gear
          end

          pre_cartridge_upgrade(itinerary)

          OpenShift::Runtime::Utils::Cgroups.new(uuid).boost do
          Dir.chdir(container.container_dir) do
            itinerary.each_cartridge do |cartridge_name, upgrade_type|
              manifest = cartridge_model.get_cartridge(cartridge_name)
              cartridge_path = File.join(gear_home, manifest.directory)

              if !File.directory?(cartridge_path)
                progress.log "Skipping upgrade for #{manifest.name}: cartridge manifest does not match gear layout: #{cartridge_path} is not a directory"
                next
              end

              ident_path                               = Dir.glob(File.join(cartridge_path, 'env', 'OPENSHIFT_*_IDENT')).first
              ident                                    = IO.read(ident_path)
              vendor, name, version, cartridge_version = gear_map_ident(ident)
              next_manifest                            = cartridge_repository.select(name, version)

              progress.step "#{name}_upgrade_cart" do |context, errors|
                context[:cartridge] = name.downcase

                if upgrade_type == UpgradeType::COMPATIBLE
                  progress.log "Compatible upgrade of cartridge #{ident}"
                  context[:compatible] = true
                  compatible_upgrade(cartridge_model, cartridge_version, next_manifest, cartridge_path)
                else
                  progress.log "Incompatible upgrade of cartridge #{ident}"
                  context[:compatible] = false
                  incompatible_upgrade(cartridge_model, cartridge_version, next_manifest, version, cartridge_path)
                end
              end

              progress.step "#{name}_rebuild_ident" do |context, errors|
                context[:cartridge] = name.downcase
                next_ident = OpenShift::Runtime::Manifest.build_ident(next_manifest.cartridge_vendor,
                                                                      next_manifest.name,
                                                                      next_manifest.version,
                                                                      next_manifest.cartridge_version)
                IO.write(ident_path, next_ident, 0, mode: 'w', perms: 0666)
              end
            end
          end
          end

          post_cartridge_upgrade(itinerary)

          if itinerary.has_incompatible_upgrade?
            restart_start_time = timestamp
            start_gear
            restart_time = timestamp - restart_start_time
            progress.log "Gear restart time (ms): #{restart_time}"
          end
        ensure
          if reset_quota
            begin
              progress.log "Resetting quota blocks: #{reset_block_quota}  inodes: #{reset_inode_quota}"
              OpenShift::Runtime::Node.set_quota(uuid, reset_block_quota, reset_inode_quota)
            rescue NodeCommandException => e
              progress.log e.message
            end
          end
        end

        restart_time
      end

      def timestamp
        (Time.new.to_f * 1000).to_i
      end

      #
      # Double the block and/or inode quotas if the gear user's current usage is over 50 percent
      # of the hard quota.
      #
      # Returns an array whose elements are a boolean indicating whether the quota will need to be
      # reset, and the block and inode quotas to reset to.
      #
      def relax_quota
        quota             = OpenShift::Runtime::Node.get_quota(uuid)
        reset_block_quota = false
        reset_inode_quota = false
        new_block_quota   = quota[:blocks_limit]
        new_inode_quota   = quota[:inodes_limit]

        if ((quota[:blocks_used] * 2) > quota[:blocks_limit])
          reset_block_quota = true
          new_block_quota   = quota[:blocks_limit] * 2
        end

        if ((quota[:inodes_used] * 2) > quota[:inodes_limit])
          reset_inode_quota = true
          new_inode_quota   = quota[:inodes_limit] * 2
        end

        if reset_block_quota || reset_inode_quota
          progress.log "Relaxing quota to blocks=#{new_block_quota}, inodes=#{new_inode_quota}"
          OpenShift::Runtime::Node.set_quota(uuid, new_block_quota, new_inode_quota)
        end

        return [reset_block_quota | reset_inode_quota, quota[:blocks_limit], quota[:inodes_limit]]
      end

      #
      # Upgrade a cartridge from a compatible prior version:
      #
      #  1. Overlay the cartridge directory for the new version on the existing
      #     instance directory,
      #  2. Remove the ERB templates for the new version
      #  3. With gear unlocked, secure the cartridge instance dir
      #
      def compatible_upgrade(cart_model, current_version, next_manifest, target)
        OpenShift::Runtime::CartridgeRepository.overlay_cartridge(next_manifest, target)

        FileUtils.rm_f container.processed_templates(next_manifest)
        FileUtils.rm_f Dir.glob(PathUtils.join(target, 'env', '*.erb'))
        progress.log "Removed ERB templates for #{next_manifest.name}"

        cart_model.unlock_gear(next_manifest) do |m|
          cart_model.secure_cartridge(next_manifest.short_name, container.uid, container.gid, target)
          execute_cartridge_upgrade_script(target, current_version, next_manifest)
        end
      end

      #
      # Upgrade a cartridge from an incompatible prior version:
      #
      # 1. Remove files that are rewritten by setup
      # 2. Overlay the new version onto the instance dir
      # 3. With the gear unlocked:
      #   1. Secure the instance dir
      #   2. Run setup for the new version
      #   3. Process the ERB templates
      # 4. Connect the frontend
      #
      def incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
        container.setup_rewritten(next_manifest).each do |entry|
          FileUtils.rm entry if File.file? entry
          FileUtils.rm_r entry if File.directory? entry
        end

        OpenShift::Runtime::CartridgeRepository.overlay_cartridge(next_manifest, target)

        name = next_manifest.name

        cart_model.unlock_gear(next_manifest) do |m|
          cart_model.secure_cartridge(next_manifest.short_name, container.uid, container.gid, target)

          execute_cartridge_upgrade_script(target, current_version, next_manifest)

          progress.step "#{name}_setup" do |context, errors|
            setup_output = cart_model.cartridge_action(m, 'setup', version, true)
            progress.log "Executed setup for #{name}"
            context[:cartridge] = name.downcase
            context[:stdout] = setup_output
          end

          progress.step "#{name}_erb" do |context, errors|
            context[:cartridge] = name.downcase
            cart_model.process_erb_templates(m)
          end
        end

        progress.step "#{name}_create_endpoints" do |context, errors|
          context[:cartridge] = name.downcase
          cart_model.create_private_endpoints(next_manifest)
        end

        progress.step "#{name}_connect_frontend" do |context, errors|
          context[:cartridge] = name.downcase
          cart_model.connect_frontend(next_manifest)
        end
      end

      def execute_cartridge_upgrade_script(cartridge_path, current_version, next_manifest)
        name = next_manifest.short_name.downcase

        progress.step "upgrade_script_#{name}" do |context, errors|
          upgrade_script = PathUtils.join(cartridge_path, %w(bin upgrade))

          if !File.exists?(upgrade_script)
            progress.log "No upgrade script exists for #{name}; skipping"
            return
          end

          if !File.executable?(upgrade_script)
            progress.log "Upgrade script for #{name} is not executable; skipping"
            return
          end

          reload_gear_env

          upgrade_script_cmd = "#{upgrade_script} #{next_manifest.version} #{current_version} #{next_manifest.cartridge_version}"

          out, err, rc = Utils::oo_spawn(upgrade_script_cmd,
                                         env: gear_env,
                                         chdir: cartridge_path,
                                         uid: container.uid,
                                         gid: container.gid)

          progress.log "Ran upgrade script for #{name}"

          context[:cartridge] = name.downcase
          context[:rc] = rc
          context[:stdout] = out
          context[:stderr] = err

          if rc != 0
            errors << "Upgrade script for #{name} returned a non-zero exit code (#{rc})"
          end
        end
      end

      #
      # Inspect the pre-upgrade state of the gear and make a copy for use later
      # in the upgrade.
      #
      def inspect_gear_state
        progress.log "Inspecting gear at #{gear_home}"

        progress.step 'inspect_gear_state' do |context, errors|
          app_state = File.join(gear_home, 'app-root', 'runtime', '.state')
          save_state = File.join(gear_home, 'app-root', 'runtime', PREUPGRADE_STATE)

          if File.exists? app_state
            FileUtils.cp(app_state, save_state)
          else
            IO.write(save_state, 'stopped')
            mcs_label = OpenShift::Runtime::Utils::SELinux.get_mcs_label(uuid)
            PathUtils.oo_chown(container.uid, container.gid, save_state)
            OpenShift::Runtime::Utils::SELinux.set_mcs_label(mcs_label, save_state)
          end

          preupgrade_state = OpenShift::Runtime::Utils::UpgradeApplicationState.new(container, PREUPGRADE_STATE)
          progress.log "Pre-upgrade state: #{preupgrade_state.value}"
          context[:preupgrade_state] = preupgrade_state.value
        end
      end

      #
      # Stop the gear as the platform and kill gear user processes.
      #
      def stop_gear
        progress.log "Stopping gear on node '#{hostname}'"

        progress.step 'stop_gear' do |context, errors|
          begin
            container.stop_gear(user_initiated: false)
          rescue Exception => e
            msg = "Stop gear failed with an exception: #{e.message}"
            progress.log msg
            context[:warning] = msg
          ensure
            container.kill_procs
          end
        end
      end

      #
      # Start the gear as the platform.
      #
      def start_gear
        progress.log "Starting gear on node '#{hostname}'"

        progress.step 'start_gear' do |context, errors|
          begin
            output = container.start_gear(user_initiated: false)
            progress.log "Start gear output: #{output}"
            context[:output] = output
          rescue Exception => e
            msg = "Start gear failed with an exception: #{e.message}"
            progress.log msg
            context[:warning] = msg
          end
        end
      end

      #
      # Validate the gear after upgrade, if the preupgrade state was not 'stopped'
      # or 'idle'. The response code is logged but no action is taken; cartridges may
      # come up in the background and take longer than the time we give them to come
      # up even under success conditions.
      #
      def validate_gear
        progress.log "Validating gear post-upgrade"

        progress.step 'validate_gear' do |context, errors|
          preupgrade_state = OpenShift::Runtime::Utils::UpgradeApplicationState.new(container, PREUPGRADE_STATE)

          progress.log "Pre-upgrade state: #{preupgrade_state.value}"
          context[:preupgrade_state] = preupgrade_state.value

          if preupgrade_state.value != 'stopped' && preupgrade_state.value != 'idle'
            state  = OpenShift::Runtime::Utils::ApplicationState.new(container)
            cart_model = OpenShift::Runtime::V2UpgradeCartridgeModel.new(config, container, state, hourglass)

            # only validate via http query one of the primary gears (has a git repo)
            if cart_model.primary_cartridge && cart_model.has_repository?
              env = OpenShift::Runtime::Utils::Environ.for_gear(gear_home)

              dns = env['OPENSHIFT_GEAR_DNS']
              uri = URI.parse("http://#{dns}")

              num_tries = 1
              while true do
                http = Net::HTTP.new(uri.host, uri.port)
                http.read_timeout = hourglass.remaining
                http.open_timeout = hourglass.remaining
                http.ssl_timeout = hourglass.remaining
                http.continue_timeout = hourglass.remaining

                request = Net::HTTP::Get.new(uri.request_uri)

                begin
                  response = http.request(request)
                rescue Timeout::Error => e
                  timeout = true
                end

                # Give the app a chance to start fully
                if ((timeout || response.code == '503') && num_tries < 5)
                  sleep num_tries
                else
                  break
                end
                num_tries += 1
              end

              progress.log "Post-upgrade response code: #{response.code}"
              context[:postupgrade_response_code] = response.code
            end

            problem, status = cart_model.gear_status

            if problem
              progress.log "Problem detected with gear status.  Post-upgrade status: #{status}"
              context[:postupgrade_status] = status
            end
          end
        end
      end

      #
      # Cleanup the upgrade metadata on the gear if the validation step has been
      # run successfully.
      #
      def cleanup
        progress.log 'Cleaning up after upgrade'
        FileUtils.rm_f(File.join(gear_home, 'app-root', 'runtime', PREUPGRADE_STATE))
        progress.done
        ::OpenShift::Runtime::UpgradeItinerary.remove_from(gear_home)
      end
    end
  end
end
