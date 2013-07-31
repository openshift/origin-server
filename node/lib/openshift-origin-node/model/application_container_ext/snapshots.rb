module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Snapshots
        def write_snapshot_archive(exclusions)
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          exclusions = exclusions.map { |x| "--exclude=./$OPENSHIFT_GEAR_UUID/#{x}" }.join(' ')

          tar_cmd = %Q{
/bin/tar --ignore-failed-read -czf - \
--exclude=./$OPENSHIFT_GEAR_UUID/.tmp \
--exclude=./$OPENSHIFT_GEAR_UUID/.ssh \
--exclude=./$OPENSHIFT_GEAR_UUID/.sandbox \
--exclude=./$OPENSHIFT_GEAR_UUID/*/conf.d/openshift.conf \
--exclude=./$OPENSHIFT_GEAR_UUID/*/run/httpd.pid \
--exclude=./$OPENSHIFT_GEAR_UUID/haproxy-\*/run/stats \
--exclude=./$OPENSHIFT_GEAR_UUID/app-root/runtime/.state \
--exclude=./$OPENSHIFT_DATA_DIR/.bash_history \
          #{exclusions} ./$OPENSHIFT_GEAR_UUID
}

          $stderr.puts 'Creating and sending tar.gz'

          run_in_container_context(tar_cmd,
                                   env: gear_env,
                                   out: $stdout,
                                   err: $stderr,
                                   chdir: @config.get('GEAR_BASE_DIR'),
                                   timeout: @hourglass.remaining,
                                   expected_exitstatus: 0)
        end

        ##
        # Creates a snapshot of a gear.
        #
        # Writes an archive (in tar.gz format) to the calling process' STDOUT.
        # The operations invoked by this method write user-facing output to the
        # client on STDERR.
        def snapshot
          stop_gear

          scalable_snapshot = !!@cartridge_model.web_proxy

          if scalable_snapshot
            begin
              handle_scalable_snapshot
            rescue => e
              $stderr.puts "We were unable to snapshot this application due to communication issues with the OpenShift broker.  Please try again later."
              $stderr.puts "#{e.message}"
              $stderr.puts "#{e.backtrace}"
              return false
            end
          end

          @cartridge_model.each_cartridge do |cartridge|
            @cartridge_model.do_control('pre-snapshot',
                                        cartridge,
                                        err: $stderr,
                                        pre_action_hooks_enabled: false,
                                        post_action_hooks_enabled: false,
                                        prefix_action_hooks:      false,)
          end

          exclusions = []

          @cartridge_model.each_cartridge do |cartridge|
            exclusions |= snapshot_exclusions(cartridge)
          end

          write_snapshot_archive(exclusions)

          @cartridge_model.each_cartridge do |cartridge|
            @cartridge_model.do_control('post-snapshot',
                                        cartridge,
                                        err: $stderr,
                                        pre_action_hooks_enabled: false,
                                        post_action_hooks_enabled: false)
          end

          start_gear
        end

        def handle_scalable_snapshot
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          gear_groups = get_gear_groups(gear_env)

          get_secondary_gear_groups(gear_groups).each do |type, group|
            $stderr.puts "Saving snapshot for secondary #{type} gear"

            ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
            run_in_container_context("#{::OpenShift::Runtime::ApplicationContainer::GEAR_TO_GEAR_SSH} #{ssh_coords} 'snapshot' > #{type}.tar.gz",
                                     env: gear_env,
                                     chdir: gear_env['OPENSHIFT_DATA_DIR'],
                                     err: $stderr,
                                     timeout: @hourglass.remaining,
                                     expected_exitstatus: 0)
          end
        end

        ##
        # Restores a gear from an archive read from STDIN.
        #
        # The operation invoked by this method write output to the client on STDERR.
        def restore(restore_git_repo)
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)

          scalable_restore = !!@cartridge_model.web_proxy
          gear_groups = nil

          if scalable_restore
            gear_groups = get_gear_groups(gear_env)
          end

          if restore_git_repo
            pre_receive(err: $stderr, out: $stdout)
          else
            stop_gear
          end

          @cartridge_model.each_cartridge do |cartridge|
            @cartridge_model.do_control('pre-restore',
                                        cartridge,
                                        pre_action_hooks_enabled: false,
                                        post_action_hooks_enabled: false,
                                        err: $stderr,
                                        out: $stdout)
          end

          prepare_for_restore(restore_git_repo, gear_env)

          transforms = []
          @cartridge_model.each_cartridge do |cartridge|
            transforms |= restore_transforms(cartridge)
          end

          extract_restore_archive(transforms, restore_git_repo, gear_env)

          if scalable_restore
            handle_scalable_restore(gear_groups, gear_env)
          end

          @cartridge_model.each_cartridge do |cartridge|
            @cartridge_model.do_control('post-restore',
                                        cartridge,
                                        pre_action_hooks_enabled: false,
                                        post_action_hooks_enabled: false,
                                        err: $stderr,
                                        out: $stdout)
          end

          if restore_git_repo
            post_receive(err: $stderr, out: $stdout)
          else
            start_gear
          end
        end

        def prepare_for_restore(restore_git_repo, gear_env)
          if restore_git_repo
            app_name = gear_env['OPENSHIFT_APP_NAME']
            $stderr.puts "Removing old git repo: ~/git/#{app_name}.git/"
            FileUtils.rm_rf(Dir.glob(PathUtils.join(@container_dir, 'git', "#{app_name}.git", '[^h]*', '*')))
          end

          $stderr.puts "Removing old data dir: ~/app-root/data/*"
          FileUtils.rm_rf(Dir.glob(PathUtils.join(@container_dir, 'app-root', 'data', '*')))
          FileUtils.rm_rf(Dir.glob(PathUtils.join(@container_dir, 'app-root', 'data', '.[^.]*')))
          FileUtils.safe_unlink(PathUtils.join(@container_dir, 'app-root', 'runtime', 'data'))
        end

        def extract_restore_archive(transforms, restore_git_repo, gear_env)
          includes = %w(./*/app-root/data)
          excludes = %w(./*/app-root/runtime/data)
          transforms << 's|${OPENSHIFT_GEAR_NAME}/data|app-root/data|'
          transforms << 's|git/.*\.git|git/${OPENSHIFT_GEAR_NAME}.git|'

          # TODO: use all installed cartridges, not just ones in current instance directory
          @cartridge_model.each_cartridge do |cartridge|
            excludes << "./*/#{cartridge.directory}/data"
          end

          if restore_git_repo
            excludes << './*/git/*.git/hooks'
            includes << './*/git'
            $stderr.puts "Restoring ~/git/#{name}.git and ~/app-root/data"
          else
            $stderr.puts "Restoring ~/app-root/data"
          end

          includes = includes.join(' ')
          excludes = excludes.map { |x| "--exclude=\"#{x}\"" }.join(' ')
          transforms = transforms.map { |x| "--transform=\"#{x}\"" }.join(' ')

          tar_cmd = %Q{/bin/tar --strip=2 --overwrite -xmz #{includes} #{transforms} #{excludes} 1>&2}

          run_in_container_context(tar_cmd,
                                   env: gear_env,
                                   out: $stdout,
                                   err: $stderr,
                                   in: $stdin,
                                   chdir: @container_dir,
                                   timeout: @hourglass.remaining,
                                   expected_exitstatus: 0)

            FileUtils.cd PathUtils.join(@container_dir, 'app-root', 'runtime') do
            FileUtils.ln_s('../data', 'data')
          end
        end

        def handle_scalable_restore(gear_groups, gear_env)
          secondary_groups = get_secondary_gear_groups(gear_groups)

          secondary_groups.each do |type, group|
            if !File.exists?(PathUtils.join(container_dir, %W(app-root data #{type}.tar.gz)))
              $stderr.puts "Unable to restore #{type} because it appears there is no snapshot for that type"
              next
            end

            $stderr.puts "Restoring snapshot for #{type} gear"

            ssh_coords = group['gears'][0]['ssh_url'].sub(/^ssh:\/\//, '')
            run_in_container_context("cat #{type}.tar.gz | #{::OpenShift::Runtime::ApplicationContainer::GEAR_TO_GEAR_SSH} #{ssh_coords} 'restore'",
                                      env: gear_env,
                                      chdir: gear_env['OPENSHIFT_DATA_DIR'],
                                      err: $stderr,
                                      timeout: @hourglass.remaining,
                                      expected_exitstatus: 0)
          end
        end
      end
    end
  end
end
