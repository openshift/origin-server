module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Deployments
        # Returns all the date/time based deployment directories (full paths), sorted in ascending order
        def all_deployments
          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')
          Dir[deployments_dir + "/*"].entries.reject {|e| ['.', '..'].include?(e) or File.basename(e) == 'by-id'}.sort
        end

        # Returns the most recent date/time based deployment directory name
        def latest_deployment_datetime
          latest = all_deployments.reverse[0]
          File.basename(latest)
        end

        def move_dependencies(deployment_datetime)
          # move the dependencies from the previous deployment to the one we're about to build
          out, err, rc = run_in_container_context("set -x; shopt -s dotglob; /bin/mv app-root/runtime/dependencies/* app-deployments/#{deployment_datetime}/dependencies",
                                                  chdir: @container_dir)
          # rc may be nonzero if the current dependencies dir is empty
        end

        def copy_dependencies(deployment_datetime)
          # FileUtils.cp_r balks when using preserve:true when trying to update the metadata
          # for a symlink that points to a file that hasn't yet been copied over - resorting
          # to shelling out to "cp -a" instead
          out, err, rc = run_in_container_context("/bin/cp -a app-root/runtime/dependencies/. app-deployments/#{deployment_datetime}/dependencies",
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
        # 2013-07-19_09-37-03
        #
        # returns the name of the newly created directory (just the date and time, not the full path)
        def create_deployment_dir(options={})
          deployment_datetime = Time.now.strftime("%Y-%m-%d_%H-%M-%S.%L")
          full_path = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          FileUtils.mkdir_p(full_path)
          FileUtils.mkdir_p(PathUtils.join(full_path, "repo"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "dependencies"))
          FileUtils.mkdir_p(PathUtils.join(full_path, "build-dependencies"))
          FileUtils.chmod_R(0o0750, full_path, :verbose => @debug)
          set_rw_permission_R(full_path)

          unless options[:force_clean_build] or current_deployment_datetime.nil?
            gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
            to_keep = (gear_env['OPENSHIFT_KEEP_DEPLOYMENTS'] || 1).to_i

            if to_keep == 1
              move_dependencies(deployment_datetime)

              # delete any previous deployments
              clean_up_deployments_before(current_deployment_datetime)
            else
              copy_dependencies(deployment_datetime)
            end
          end

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

        def read_deployment_metadata(deployment_datetime, filename)
          file = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime, 'metadata', filename)
          File.exist?(file) ? IO.read(file) : nil
        end

        def write_deployment_metadata(deployment_datetime, filename, data)
          metadata_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime, 'metadata')
          FileUtils.mkdir_p(metadata_dir)
          File.open(PathUtils.join(metadata_dir, filename), File::WRONLY|File::TRUNC|File::CREAT, 0640) { |file|
            file.write "#{data}\n"
          }
        end

        def get_deployment_datetime_for_deployment_id(deployment_id)
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

        def delete_deployment(deployment_datetime)
          deployments_dir = PathUtils.join(@container_dir, 'app-deployments')
          deployment_id = read_deployment_metadata(deployment_datetime, 'id')
          FileUtils.rm_f(PathUtils.join(deployments_dir, 'by-id', deployment_id.chomp)) if deployment_id
          FileUtils.rm_rf(PathUtils.join(deployments_dir, deployment_datetime))
        end

        # Prunes deployment directories prior to +deployment_datetime+
        # - where the deployment state != DEPLOYED
        # - where the # of total deployments > OPENSHIFT_KEEP_DEPLOYMENTS
        def clean_up_deployments_before(deployment_datetime)
          gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
          to_keep = (gear_env['OPENSHIFT_KEEP_DEPLOYMENTS'] || 1).to_i
          deleted = 0

          # remove all deployments prior to the specified one that were never deployed
          all_deployments.each do |d|
            # skip the specified one
            next if d.end_with?(deployment_datetime)

            deployment_state = read_deployment_metadata(deployment_datetime, 'state') || ''
            delete_deployment(File.basename(d)) unless deployment_state.chomp == 'DEPLOYED'
          end
          #

          # remove so we stay under to_keep
          all = all_deployments
          count = all.count

          all.each do |d|
            # stop if the remaining # of deployments is <= to_keep
            break if count <= to_keep

            # stop if we've reached the specified one
            break if d.end_with?(deployment_datetime)

            # remove the old one
            delete_deployment(File.basename(d))

            # update remaining # of deployments
            count -= 1
          end
        end

        def archive
          deployment_datetime = current_deployment_datetime
          deployment_dir = PathUtils.join(@container_dir, 'app-deployments', deployment_datetime)
          command = "tar zcf - --exclude metadata ."
          out, err, rc = run_in_container_context(command,
                                                  chdir: deployment_dir,
                                                  expected_exitstatus: 0)
          out
        end

        def list_deployments
          current = current_deployment_datetime

          all_deployments.reverse.map do |d|
            deployment_datetime = File.basename(d)
            deployment_id = (read_deployment_metadata(deployment_datetime, 'id') || '').chomp
            deployment_state = (read_deployment_metadata(deployment_datetime, 'state') || 'NOT DEPLOYED').chomp
            active_text = " - ACTIVE" if deployment_datetime == current
            "#{deployment_datetime} - #{deployment_id} - #{deployment_state}#{active_text}"
          end.join("\n")
        end
      end
    end
  end
end
