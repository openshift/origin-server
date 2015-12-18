require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'
require 'securerandom'

module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Deployments
        DEPLOYMENT_DATETIME_FORMAT = "%Y-%m-%d_%H-%M-%S.%L"

        def deployment_metadata_for(deployment_datetime)
          ::OpenShift::Runtime::DeploymentMetadata.new(self, deployment_datetime)
        end

        # Returns the number of deployments to keep as configured in the given env
        def deployments_to_keep(env)
          (env['OPENSHIFT_KEEP_DEPLOYMENTS'] || 1).to_i
        end

        # Returns all the deployment directories, in no particular order
        def all_deployments
          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')

          Dir[deployments_dir + "/*"].entries.reject { |e| %w(by-id current).include?(File.basename(e)) }
        end

        # Returns all the date/time based deployment directories (full paths),
        # sorted by most recent activation date/time in ascending order
        # (i.e. oldest activation first)
        def all_deployments_by_activation(dirs = nil)
          deployments = dirs || all_deployments
          count = 0

          # need to call sort before sort_by so the dirs are sorted by name (creation datetime)
          # otherwise sorting by (Float::MAX - count) might be in the wrong order, which can
          # result in prune_deployments deleting the wrong dir!
          deployments.sort.sort_by do |d|
            latest_activation = deployment_metadata_for(File.basename(d)).activations.last

            # treat a deployment dir without any activations as the latest
            # TODO may want to revisit this later, but it allows prune to work by considering
            # dirs with no activations as newer than any other dir, so we can delete a dir
            # that actually has at least 1 activation
            count += 1
            latest_activation || (Float::MAX - count)
          end
        end

        # Returns the most recent date/time based deployment directory name
        def latest_deployment_datetime
          latest = all_deployments_by_activation[-1]
          File.basename(latest)
        end

        def deployment_exists?(deployment_id)
          File.exist?(PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id))
        end

        # Removes all files from app-root/runtime/<dirs>
        #
        # options for dirs to delete (all default to false):
        #  :dependencies
        #  :build_dependencies
        #  :repo
        def clean_runtime_dirs(options)
          dirs = []
          %w(dependencies build_dependencies repo).each do |dir|
            dirs << dir if options[dir.to_sym] == true
          end

          return if dirs.empty?

          dirs.map! { |dir| "app-root/runtime/#{dir.gsub(/_/, '-')}/*" }

          out, err, rc = run_in_container_context("shopt -s dotglob; rm -rf #{dirs.join(' ')}",
                                                    chdir: @container_dir,
                                                    expected_exitstatus: 0)
        end

        def current_deployment_datetime
          file = PathUtils.join(@container_dir, 'app-deployments', 'current')
          if File.exist?(file)
            File.readlink(file)
          else
            nil
          end
        end

        def check_deployments_integrity(options = {})
          buffer = ''
          FileUtils.mkdir_p(PathUtils.join(@container_dir, 'app-deployments', 'by-id'))

          deployments = all_deployments.map { | x | File.basename(x) }

          linked_deployments = Dir.glob(PathUtils.join(@container_dir, 'app-deployments', 'by-id', '*')).map do | link |
            File.basename(File.readlink(link))
          end

          unlinked_deployments = deployments - linked_deployments

          if !unlinked_deployments.empty?
            message = "Repairing links for #{unlinked_deployments.size} deployments"
            options[:out].puts message if options[:out]
            buffer << message
          end

          unlinked_deployments.each do | deployment_datetime |
            deployment_id = calculate_deployment_id(deployment_datetime)
            deployment_metadata = deployment_metadata_for(deployment_datetime)
            deployment_metadata.id = deployment_id
            deployment_metadata.save

            link_deployment_id(deployment_datetime, deployment_id)
          end

          set_rw_permission_R(PathUtils.join(@container_dir, 'app-deployments'))

          unless current_deployment_datetime
            all_deployments_by_activation.reverse.each do |deployment|
              deployment_datetime = File.basename(deployment)
              deployment_metadata = deployment_metadata_for(deployment_datetime)

              if deployment_metadata.activations.empty?
                next
              end

              message = "Repairing current deployment symlink: #{deployment_datetime}"
              options[:out].puts message if options[:out]
              buffer << message

              update_current_deployment_datetime_symlink(deployment_datetime)
              break
            end
          end

          buffer
        end

        def update_current_deployment_datetime_symlink(deployment_datetime)
          file = PathUtils.join(@container_dir, 'app-deployments', 'current')
          FileUtils.rm_f(file)
          FileUtils.ln_s(deployment_datetime, file)
          PathUtils.oo_lchown(uid, gid, file)
        end

        # Creates a deployment directory in app-root/deployments with a name like
        # 2013-07-19_09-37-03.431
        #
        # returns the name of the newly created directory (just the date and time, not the full path)
        def create_deployment_dir()
          deployment_datetime = Time.now.strftime(DEPLOYMENT_DATETIME_FORMAT)
          full_path = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          FileUtils.mkdir_p(full_path)
          FileUtils.mkdir_p(PathUtils.join(full_path, "repo"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "dependencies"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "build-dependencies"))
          FileUtils.chmod_R(0o0750, full_path, :verbose => @debug)
          set_rw_permission_R(full_path)

          prune_deployments

          deployment_datetime
        end

        def calculate_deployment_id(deployment_datetime)
          SecureRandom.hex(4)
        end

        def calculate_deployment_checksum(deployment_id)
          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id)

          command = "tar -c --exclude metadata.json . | tar -xO | sha1sum | cut -f 1 -d ' '"

          out, err, rc = run_in_container_context(command,
                                                  chdir: deployment_dir,
                                                  expected_exitstatus: 0)

          out.chomp
        end

        def link_deployment_id(deployment_datetime, deployment_id)
          target = PathUtils.join('..', deployment_datetime)
          link = PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id)
          FileUtils.ln_s(target, link)
          PathUtils.oo_lchown(uid, gid, link)
        end

        def unlink_deployment_id(deployment_id)
          FileUtils.rm_f(PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id))
        end


        def get_deployment_datetime_for_deployment_id(deployment_id)
          return nil unless deployment_exists?(deployment_id)

          # read the symlink - will be something like ../2013-07-24_16-41-55
          deployment_dir_link = File.readlink(PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id))
          # return just the date/time portion
          File.basename(deployment_dir_link)
        end

        def sync_files(from, to)
          out, err, rc = run_in_container_context("/usr/bin/rsync -avS --delete #{from}/ #{to}/",
                                                  expected_exitstatus: 0)
        end

        def sync_deployment_dir_to_runtime(deployment_datetime, name)
          from = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime, name)
          to = PathUtils.join(@container_dir, 'app-root', 'runtime', name)
          sync_files(from, to)
        end

        def sync_deployment_repo_dir_to_runtime(deployment_datetime)
          sync_deployment_dir_to_runtime(deployment_datetime, 'repo')
        end

        def sync_deployment_dependencies_dir_to_runtime(deployment_datetime)
          sync_deployment_dir_to_runtime(deployment_datetime, 'dependencies')
        end

        def sync_deployment_build_dependencies_dir_to_runtime(deployment_datetime)
          sync_deployment_dir_to_runtime(deployment_datetime, 'build-dependencies')
        end

        def sync_runtime_dir_to_deployment(deployment_datetime, name)
          from = PathUtils.join(@container_dir, 'app-root', 'runtime', name)
          to = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime, name)
          sync_files(from, to)
        end

        def sync_runtime_repo_dir_to_deployment(deployment_datetime)
          sync_runtime_dir_to_deployment(deployment_datetime, 'repo')
        end

        def sync_runtime_dependencies_dir_to_deployment(deployment_datetime)
          sync_runtime_dir_to_deployment(deployment_datetime, 'dependencies')
        end

        def sync_runtime_build_dependencies_dir_to_deployment(deployment_datetime)
          sync_runtime_dir_to_deployment(deployment_datetime, 'build-dependencies')
        end

        def delete_deployment(deployment_datetime)
          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')
          deployment_id = deployment_metadata_for(deployment_datetime).id
          FileUtils.rm_f(PathUtils.join(deployments_dir, 'by-id', deployment_id)) if deployment_id
          FileUtils.rm_rf(PathUtils.join(deployments_dir, deployment_datetime))
        end

        # Prunes deployment directories, using the following algorithm:
        #
        # - Only keep at most $OPENSHIFT_KEEP_DEPLOYMENTS directories in app-deployments
        #
        # - Remove the "oldest" directory sorted by latest activation time
        #
        # - Also remove any activation times earlier than the latest activation time of
        #   the deployment being deleted across all deployments
        def prune_deployments
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
          to_keep = deployments_to_keep(gear_env)
          deleted = 0

          deployments = all_deployments

          # short-circuit - don't do anything if we're under the limit
          count = deployments.count
          return if count <= to_keep

          # remove so we stay under to_keep
          all = all_deployments_by_activation(deployments)

          # this is the activation time of the most recent deployment to be deleted
          activation_cutoff = nil

          all.each do |d|
            # stop if the remaining # of deployments is <= to_keep
            break if count <= to_keep

            deployment_datetime = File.basename(d)

            activation_cutoff = deployment_metadata_for(deployment_datetime).activations.last

            delete_deployment(deployment_datetime)

            # update remaining # of deployments
            count -= 1
          end

          delete_activations_before(activation_cutoff) unless activation_cutoff.nil?
        end

        # Removes all activation entries from all deployment directories where
        # the activation time <= cutoff
        #
        # @param [Float] cutoff activation cutoff time
        def delete_activations_before(cutoff)
          all_deployments.each do |full_path|
            deployment_datetime = File.basename(full_path)

            # load the metadata
            deployment_metadata = deployment_metadata_for(deployment_datetime)

            # remove activations <= cutoff
            deployment_metadata.activations.delete_if { |a| a <= cutoff }

            # write metadata to disk
            deployment_metadata.save
          end
        end

        def archive(deployment_datetime = nil)
          deployment_datetime ||= current_deployment_datetime
          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          command = "tar zcf - --exclude metadata.json ."
          out, err, rc = run_in_container_context(command,
                                                  chdir: deployment_dir,
                                                  expected_exitstatus: 0,
                                                  out: $stdout,
                                                  err: $stderr)
          out
        end

        def calculate_deployments
          deployments = []
          all_deployments.each do |d|
            deployment_datetime = File.basename(d)
            deployment_metadata = deployment_metadata_for(deployment_datetime)
            deployments.push({
              :id => deployment_metadata.id,
              :ref => deployment_metadata.git_ref,
              :sha1 => deployment_metadata.git_sha1,
              :force_clean_build => deployment_metadata.force_clean_build,
              :hot_deploy => deployment_metadata.hot_deploy,
              :created_at => Time.strptime(deployment_datetime, DEPLOYMENT_DATETIME_FORMAT).to_f,
              :activations => deployment_metadata.activations
            })
          end
          deployments
        end

        def set_keep_deployments(keep_deployments)
          add_env_var('KEEP_DEPLOYMENTS', keep_deployments, true)
          #TODO Clean up any deployments over the limit
        end

        def set_deployment_branch(deployment_branch)
          add_env_var('DEPLOYMENT_BRANCH', deployment_branch, true)
        end

        def set_auto_deploy(auto_deploy)
          add_env_var('AUTO_DEPLOY', auto_deploy, true)
        end

        def set_deployment_type(deployment_type)
          add_env_var('DEPLOYMENT_TYPE', deployment_type, true)
        end

        def list_deployments
          current = current_deployment_datetime

          list = []
          list << "Activation time - Deployment ID - Git Ref - Git SHA1"
          list += all_deployments_by_activation.reverse.map do |d|
            deployment_datetime = File.basename(d)
            deployment_metadata = deployment_metadata_for(deployment_datetime)
            active_text = " - ACTIVE" if deployment_datetime == current
            latest_activation = deployment_metadata.activations.last
            activation_text = if latest_activation.nil?
              'NEVER'
            else
              Time.at(latest_activation)
            end
            "#{activation_text} - #{deployment_metadata.id} - #{deployment_metadata.git_ref} - #{deployment_metadata.git_sha1}#{active_text}"
          end
          list.join("\n")
        end

        def determine_extract_command(options)
          use_artifact_url  = !!options[:artifact_url]
          use_stdin         = !!options[:stdin]
          filename          = options[:file]

          if use_artifact_url
            "/usr/bin/curl #{options[:artifact_url]} | /bin/tar -xz"
          elsif use_stdin
            "/bin/tar -xz"
          elsif filename =~ /\.tar\.gz$/i or filename =~ /\.tar$/i
            "/bin/tar xf #{filename}"
          elsif filename =~ /\.zip$/i
            "/usr/bin/unzip -q #{filename}"
          else
            raise "Unable to determine file type for '#{filename}' - unable to deploy"
          end
        end

        def extract_deployment_archive(env, options = {})
          file        = options[:file]
          destination = options[:destination]

          if destination.nil?
            raise "Destination must be supplied"
          end

          if file && !File.exist?(file)
            raise "Specified file '#{file}' does not exist."
          end

          extract_command = determine_extract_command(options)

          # explode file
          out, err, rc = run_in_container_context(extract_command,
                                                  in: options[:stdin],
                                                  out: nil,
                                                  err: nil,
                                                  env: env,
                                                  chdir: destination)

          unless rc == 0
            raise OpenShift::Runtime::Utils::ShellExecutionException.new(
              "Unable to extract deployment archive using command: #{extract_command}", rc, out, err)
          end
        end

        ##
        # Returns the git ref to use when deploying. The ref will be whichever is not empty, in this order:
        #
        # +input+
        # $OPENSHIFT_DEPLOYMENT_BRANCH
        # 'master'
        def determine_deployment_ref(gear_env, input=nil)
          ref = input
          ref = gear_env['OPENSHIFT_DEPLOYMENT_BRANCH'] if ref.nil? or ref.empty?
          ref = 'master' if ref.nil? or ref.empty?
          ref
        end
      end
    end
  end
end
