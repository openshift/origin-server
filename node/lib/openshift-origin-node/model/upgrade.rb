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
require 'openshift-origin-common'
require 'net/http'
require 'uri'

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
        require gear_extension_path
        @@gear_extension_present = true
      end

      attr_reader :uuid, :namespace, :version, :hostname, :ignore_cartridge_version, :gear_home, :gear_env, :progress, :container, :gear_extension, :config

      def initialize(uuid, namespace, version, hostname, ignore_cartridge_version)
        @uuid = uuid
        @namespace = namespace
        @version = version
        @hostname = hostname
        @ignore_cartridge_version = ignore_cartridge_version
        @config = OpenShift::Config.new

        gear_base_dir = @config.get('GEAR_BASE_DIR')
        @gear_home = PathUtils.join(gear_base_dir, uuid)
        @gear_env = Utils::Environ.for_gear(gear_home)
        @progress = Utils::UpgradeProgress.new(gear_home)
        @container = ApplicationContainer.from_uuid(uuid)
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
        start_time = timestamp
        
        unless File.directory?(gear_home) && !File.symlink?(gear_home)
          return "Application not found to upgrade: #{gear_home}\n", 127
        end

        gear_env = OpenShift::Runtime::Utils::Environ.for_gear(gear_home)
        unless gear_env.key?('OPENSHIFT_GEAR_NAME') && gear_env.key?('OPENSHIFT_APP_NAME')
          return "***acceptable_error_env_vars_not_found={\"gear_uuid\":\"#{uuid}\"}***\n", 0
        end

        exitcode = 0
        progress.init_store

        if @@gear_extension_present
          begin
            if !OpenShift::GearUpgradeExtension.respond_to?(:version)
              return "Gear upgrade extension must respond to version", 127
            end

            extension_version = OpenShift::GearUpgradeExtension.version

            if version != extension_version
              return "Version mismatch between supplied release version (#{version}) and extension version (#{extension_version}", 127
            end
          rescue NameError => e
            return "Unable to resolve OpenShift::GearUpgradeExtension: #{e.message}", 127
          end

          begin
            @gear_extension = OpenShift::GearUpgradeExtension.new(uuid, gear_home)
          rescue Exception => e
            progress.log "Caught an exception during upgrade: #{e.message}"
            progress.log e.backtrace.join("\n")
            return "Unable to instantiate gear upgrade extension.  Progress report: #{progress.report}", 127
          end
        end

        begin
          progress.log "Beginning #{version} upgrade for #{uuid}"

          inspect_gear_state
          gear_pre_upgrade
          upgrade_cartridges
          gear_post_upgrade

          if progress.has_instruction?('validate_gear')
            validate_gear

            if progress.complete? 'validate_gear'
              cleanup
            end
          else
            cleanup
          end

          total_time = timestamp - start_time
          progress.log "***time_upgrade_on_node_measured_from_node=#{total_time}***"
        rescue OpenShift::Runtime::Utils::ShellExecutionException => e
          progress.log %Q(#{e.message} stdout => \n #{e.stdout} stderr => \n #{e.stderr})
          exitcode = 1
        rescue Exception => e
          progress.log "Caught an exception during upgrade: #{e.message}"
          progress.log e.backtrace.join("\n")
          exitcode = 1
        end

        [progress.report, exitcode]
      end

      #
      # Execute the gear extension's 'pre_upgrade' method, if defined.
      #
      def gear_pre_upgrade
        if !gear_extension.nil? && gear_extension.respond_to?(:pre_upgrade) && progress.incomplete?('pre_upgrade')
          gear_extension.pre_upgrade(progress)
          progress.mark_complete('pre_upgrade')
        end
      end

      #
      # Execute the gear extension's 'post_upgrade' method, if defined.
      #
      def gear_post_upgrade
        if !gear_extension.nil? && gear_extension.respond_to?(:post_upgrade) && progress.incomplete?('post_upgrade') 
          gear_extension.post_upgrade(progress) 
          progress.mark_complete('post_upgrade')
        end
      end

      #
      # Gear-level upgrade script:
      #
      # 1. For each cartridge:
      #   1. Upgrade the cartridge to the new version
      #   2. Rebuild the cartridge ident, if applicable
      # 2. If a cartridge is undergoing an incompatible upgrade, set an instruction to validate
      #    the gear.
      #
      def upgrade_cartridges
        progress.log "Migrating gear at #{gear_home}"

        state                = OpenShift::Runtime::Utils::ApplicationState.new(container)
        cartridge_model      = OpenShift::Runtime::V2UpgradeCartridgeModel.new(config, container, state, OpenShift::Runtime::Utils::Hourglass.new(235))
        cartridge_repository = OpenShift::Runtime::CartridgeRepository.instance
        restart_required     = false

        reset_quota, reset_block_quota, reset_inode_quota = relax_quota

        begin
          Dir.chdir(container.container_dir) do
            cartridge_model.each_cartridge do |manifest|
              cartridge_path = File.join(gear_home, manifest.directory)

              if !File.directory?(cartridge_path)
                progress.log "Skipping upgrade for #{manifest.name}: cartridge manifest does not match gear layout: #{cartridge_path} is not a directory"
                next
              end

              ident_path                               = Dir.glob(File.join(cartridge_path, 'env', 'OPENSHIFT_*_IDENT')).first
              ident                                    = IO.read(ident_path)
              vendor, name, version, cartridge_version = OpenShift::Runtime::Manifest.parse_ident(ident)

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

              if progress.incomplete? "#{name}_upgrade"
                if next_manifest.compatible_versions.include?(cartridge_version)
                  progress.log "Compatible upgrade of cartridge #{ident}"
                  compatible_upgrade(cartridge_model, cartridge_version, next_manifest, cartridge_path)
                else
                  progress.set_instruction('validate_gear')
                  stop_gear unless progress.has_instruction?('restart_gear')
                  progress.set_instruction('restart_gear')

                  progress.log "Incompatible upgrade of cartridge #{ident}"
                  incompatible_upgrade(cartridge_model, cartridge_version, next_manifest, version, cartridge_path)
                end

                progress.mark_complete("#{name}_upgrade")
              end

              if progress.incomplete? "#{name}_rebuild_ident"
                next_ident = OpenShift::Runtime::Manifest.build_ident(manifest.cartridge_vendor,
                                                                      manifest.name,
                                                                      manifest.version,
                                                                      next_manifest.cartridge_version)
                IO.write(ident_path, next_ident, 0, mode: 'w', perms: 0666)
                progress.mark_complete("#{manifest.name}_update_ident")
              end
            end
          end

          if progress.has_instruction?('restart_gear')
            restart_start_time = timestamp
            start_gear
            restart_time = timestamp - restart_start_time
            progress.log "***time_restart=#{restart_time}***"
          end
        ensure
          if reset_quota
            progress.log "Resetting quota blocks: #{reset_block_quota}  inodes: #{reset_inode_quota}"
            OpenShift::Runtime::Node.set_quota(uuid, reset_block_quota, reset_inode_quota)
          end
        end
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
        filesystem, quota, quota_soft, quota_hard, inodes, inodes_soft, inodes_hard = OpenShift::Runtime::Node.get_quota(uuid)
        reset_block_quota = false
        reset_inode_quota = false
        new_block_quota = quota_hard.to_i
        new_inode_quota = inodes_hard.to_i

        if ((quota.to_i * 2) > quota_hard.to_i)
          reset_block_quota = true
          new_block_quota = quota_hard.to_i * 2
        end

        if ((inodes.to_i * 2) > inodes_hard.to_i)
          reset_inode_quota = true
          new_inode_quota = inodes_hard.to_i * 2
        end

        if reset_block_quota || reset_inode_quota
          progress.log "Relaxing quota to blocks=#{new_block_quota}, inodes=#{new_inode_quota}"
          OpenShift::Runtime::Node.set_quota(uuid, new_block_quota, new_inode_quota)
        end

        return [ reset_block_quota | reset_inode_quota, quota_hard.to_i, inodes_hard.to_i ]
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

        # No ERB's are rendered for fast upgrades
        FileUtils.rm_f container.processed_templates(next_manifest)
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

          if progress.incomplete? "#{name}_setup"
            progress.log cart_model.cartridge_action(m, 'setup', version, true)
            progress.mark_complete("#{name}_setup")
          end

          if progress.incomplete? "#{name}_erb"
            cart_model.process_erb_templates(m)
            progress.mark_complete("#{name}_erb")
          end

          execute_cartridge_upgrade_script(target, current_version, next_manifest)
        end

        if progress.incomplete? "#{name}_connect_frontend"
          cart_model.connect_frontend(next_manifest)
          progress.mark_complete("#{name}_connect_frontend")
        end
      end

      def execute_cartridge_upgrade_script(cartridge_path, current_version, next_manifest)
        name = next_manifest.short_name

        if !progress.has_instruction?("upgrade_script_#{name}")
          upgrade_script = PathUtils.join(cartridge_path, %w(bin upgrade))

          if !File.exists?(upgrade_script)
            progress.log "No upgrade script exists for #{name}; skipping"
            return
          end

          if !File.executable?(upgrade_script)
            progress.log "Upgrade script for #{name} is not executable; skipping"
            return
          end

          progress.set_instruction("upgrade_script_#{name}")
        end

        return if !progress.has_instruction?("upgrade_script_#{name}")

        reload_gear_env

        if progress.incomplete?("upgrade_script_#{name}")
          upgrade_script_cmd = "#{upgrade_script} #{next_manifest.version} #{current_version} #{next_manifest.cartridge_version}"

          out, err, rc = Utils::oo_spawn(upgrade_script_cmd,
                                         env: gear_env,
                                         chdir: cartridge_path,
                                         uid: container.uid,
                                         gid: container.gid)

          progress.log "Ran upgrade script for #{name}:\nout:#{out}\nerr:#{err}\nrc:#{rc}"

          return if rc != 0

          progress.mark_complete("upgrade_script_#{name}")
        end
      end

      #
      # Inspect the pre-upgrade state of the gear and make a copy for use later
      # in the upgrade.
      #
      def inspect_gear_state
        progress.log "Inspecting gear at #{gear_home}"

        if progress.incomplete? 'inspect_gear_state'
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
          progress.mark_complete('inspect_gear_state')
        end
      end

      #
      # Stop the gear as the platform and kill gear user processes.
      #
      def stop_gear
        progress.log "Stopping gear with uuid '#{uuid}' on node '#{hostname}'"

        if progress.incomplete? 'stop_gear'
          begin
            container.stop_gear(user_initiated: false)
          rescue Exception => e
            progress.log "Stop gear failed with an exception: #{e.message}"
          ensure
            container.kill_procs
          end

          progress.mark_complete('stop_gear')
        end
      end

      #
      # Start the gear as the platform.
      #
      def start_gear
        progress.log "Starting gear with uuid '#{uuid}' on node '#{hostname}'"

        if progress.incomplete? 'start_gear'
          container = OpenShift::Runtime::ApplicationContainer.from_uuid(uuid)

          begin
            output = container.start_gear(user_initiated: false)
            progress.log "Start gear output: #{output}"
          rescue Exception => e
            progress.log "Start gear failed with an exception: #{e.message}"
            #raise
          end

          progress.mark_complete('start_gear')
        end
      end

      #
      # Validate the gear after upgrade, if the preupgrade state was not 'stopped'
      # or 'idle'. The response code is logged but no action is taken; cartridges may
      # come up in the background and take longer than the time we give them to come
      # up even under success conditions.
      #
      def validate_gear
        progress.log "Validating gear #{uuid} post-upgrade"

        if progress.incomplete? 'validate_gear'
          preupgrade_state = OpenShift::Runtime::Utils::UpgradeApplicationState.new(container, PREUPGRADE_STATE)

          progress.log "Pre-upgrade state: #{preupgrade_state.value}"

          if preupgrade_state.value != 'stopped' && preupgrade_state.value != 'idle'
            state  = OpenShift::Runtime::Utils::ApplicationState.new(container)
            cart_model = OpenShift::Runtime::V2UpgradeCartridgeModel.new(config, container, state, OpenShift::Runtime::Utils::Hourglass.new(235))

            # only validate via http query on the head gear
            if cart_model.primary_cartridge && (container.uuid == container.application_uuid)
              env = OpenShift::Runtime::Utils::Environ.for_gear(gear_home)

              dns = env['OPENSHIFT_GEAR_DNS']
              uri = URI.parse("http://#{dns}")

              num_tries = 1
              while true do
                http = Net::HTTP.new(uri.host, uri.port)
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
            end

            problem, status = cart_model.gear_status

            if problem
              progress.log "Problem detected with gear status.  Post-upgrade status:\n#{status}"
            end
          end

          progress.mark_complete('validate_gear')
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
      end
    end
  end
end
