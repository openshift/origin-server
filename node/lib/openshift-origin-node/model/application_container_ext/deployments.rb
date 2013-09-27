require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'

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

        # Returns all the deployment directories
        def all_deployments
          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')

          Dir[deployments_dir + "/*"].entries.reject { |e| File.basename(e) == 'by-id' }
        end

        # Returns all the date/time based deployment directories (full paths),
        # sorted by most recent activation date/time in ascending order
        # (i.e. oldest activation first)
        def all_deployments_by_activation(dirs = nil)
          deployments = dirs || all_deployments
          deployments.sort_by do |d|
            latest_activation = deployment_metadata_for(File.basename(d)).activations.last

            # treat a deployment dir without any activations as the latest
            # TODO may want to revisit this later, but it allows prune to work by considering
            # dirs with no activations as newer than any other dir, so we can delete a dir
            # that actually has at least 1 activation
            latest_activation || Float::MAX
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

        def record_deployment_activation(deployment_datetime)
          deployment_metadata = deployment_metadata_for(deployment_datetime)
          deployment_metadata.activations << Time.now.to_f
          deployment_metadata.save
        end

        def move_dependencies(deployment_datetime)
          # move the dependencies from the previous deployment to the one we're about to build
          out, err, rc = run_in_container_context("set -x; shopt -s dotglob; /bin/mv app-root/runtime/dependencies/* app-deployments/#{deployment_datetime}/dependencies",
                                                  chdir: @container_dir)
          # rc may be nonzero if the current dependencies dir is empty

          out, err, rc = run_in_container_context("set -x; shopt -s dotglob; /bin/mv app-root/runtime/build-dependencies/* app-deployments/#{deployment_datetime}/build-dependencies",
                                                  chdir: @container_dir)
        end

        def copy_dependencies(deployment_datetime)
          # FileUtils.cp_r balks when using preserve:true when trying to update the metadata
          # for a symlink that points to a file that hasn't yet been copied over - resorting
          # to shelling out to "cp -a" instead
          out, err, rc = run_in_container_context("/bin/cp -a app-root/runtime/dependencies/. app-deployments/#{deployment_datetime}/dependencies",
                                                  chdir: @container_dir,
                                                  expected_exitstatus: 0)

          out, err, rc = run_in_container_context("/bin/cp -a app-root/runtime/build-dependencies/. app-deployments/#{deployment_datetime}/build-dependencies",
                                                  chdir: @container_dir,
                                                  expected_exitstatus: 0)

        end

        def current_deployment_datetime
          repo_link = PathUtils.join(@container_dir, 'app-root', 'runtime', 'repo')

          return nil unless File.exist?(repo_link)

          # will be something like ../../app-deployments/2013-07-29_12-13-14/repo
          link = File.readlink(repo_link)

          # dirname gets ../../app-deployments/2013-07-29_12-13-14
          # basename of the dirname therefore yields the datetime
          File.basename(File.dirname(link))
        end

        # Creates a deployment directory in app-root/deployments with a name like
        # 2013-07-19_09-37-03.431
        #
        # returns the name of the newly created directory (just the date and time, not the full path)
        def create_deployment_dir(options={})
          deployment_datetime = Time.now.strftime(DEPLOYMENT_DATETIME_FORMAT)
          full_path = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          FileUtils.mkdir_p(full_path)
          FileUtils.mkdir_p(PathUtils.join(full_path, "repo"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "dependencies"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "build-dependencies"))
          FileUtils.chmod_R(0o0750, full_path, :verbose => @debug)
          set_rw_permission_R(full_path)

          current = current_deployment_datetime
          unless options[:force_clean_build] or current.nil?
            gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
            to_keep = deployments_to_keep(gear_env)

            if to_keep == 1
              # move deps from the current deployment to this new one
              # current deployment will be deleted by prune_deployments below
              move_dependencies(deployment_datetime)
            else
              # calling prune here to delete the oldest to save on disk space
              prune_deployments

              copy_dependencies(deployment_datetime)
            end
          end

          # need to call this regardless of force_clean_build above so we always stay <= deployments_to_keep
          prune_deployments

          deployment_datetime
        end

        def calculate_deployment_id(deployment_datetime)
          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)

          # TODO use a better algorithm
          out, err, rc = run_in_container_context("tar c . | tar xO | sha1sum | cut -f 1 -d ' '",
                                                  chdir: deployment_dir,
                                                  expected_exitstatus: 0)

          deployment_id = out[0..7]
        end

        def link_deployment_id(deployment_datetime, deployment_id)
          FileUtils.cd(PathUtils.join(@container_dir, 'app-deployments', 'by-id')) do
            FileUtils.ln_s(PathUtils.join('..', deployment_datetime), deployment_id)
          end
        end

        def unlink_deployment_id(deployment_id)
          FileUtils.unlink(PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id))
        end


        def get_deployment_datetime_for_deployment_id(deployment_id)
          return nil unless deployment_exists?(deployment_id)

          # read the symlink - will be something like ../2013-07-24_16-41-55
          deployment_dir_link = File.readlink(PathUtils.join(@container_dir, 'app-deployments', 'by-id', deployment_id))
          # return just the date/time portion
          File.basename(deployment_dir_link)
        end

        def update_repo_symlink(deployment_datetime)
          runtime = PathUtils.join(@container_dir, 'app-root', 'runtime')
          FileUtils.cd(runtime) do |d|
            FileUtils.rm_f('repo')
            FileUtils.ln_s("../../app-deployments/#{deployment_datetime}/repo", 'repo')
            PathUtils.oo_lchown(uid, gid, "repo")
          end
        end

        def update_dependencies_symlink(deployment_datetime)
          runtime = PathUtils.join(@container_dir, 'app-root', 'runtime')
          FileUtils.cd(runtime) do |d|
            FileUtils.rm_f('dependencies')
            FileUtils.ln_s("../../app-deployments/#{deployment_datetime}/dependencies", 'dependencies')
            PathUtils.oo_lchown(uid, gid, "dependencies")
          end
        end

        def update_build_dependencies_symlink(deployment_datetime)
          runtime = PathUtils.join(@container_dir, 'app-root', 'runtime')
          FileUtils.cd(runtime) do |d|
            FileUtils.rm_f('build-dependencies')
            FileUtils.ln_s("../../app-deployments/#{deployment_datetime}/build-dependencies", 'build-dependencies')
            PathUtils.oo_lchown(uid, gid, "build-dependencies")
          end
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
          command = "tar zcf - --exclude metadata ."
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
              :git_sha1 => deployment_metadata.git_sha1,
              :force_clean_build => deployment_metadata.force_clean_build,
              :hot_deploy => deployment_metadata.hot_deploy,
              :created_at => Time.parse(deployment_datetime).to_f
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

        def determine_extract_command(filename)
          if filename =~ /\.tar\.gz$/i or filename =~ /\.tar$/i
            "/bin/tar xf #{filename}"
          elsif filename =~ /\.zip$/i
            "/usr/bin/unzip -q #{filename}"
          else
            raise "Unable to determine file type for '#{filename}' - unable to deploy"
          end
        end

        def extract_deployment_archive(env, file, destination)
          raise "Specified file '#{file}' does not exist." unless File.exist?(file)

          extract_command = determine_extract_command(file)

          # explode file
          out, err, rc = run_in_container_context(extract_command,
                                                  env: env,
                                                  chdir: destination,
                                                  expected_exitstatus: 0)
        end
      end
    end
  end
end
