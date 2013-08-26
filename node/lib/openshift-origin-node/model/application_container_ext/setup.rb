module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Setup
        # Private: Create and populate the users home dir.
        #
        # Examples
        #   initialize_homedir
        #   # => nil
        #   # Creates:
        #   # ~
        #   # ~/.tmp/
        #   # ~/.sandbox/$uuid
        #   # ~/.env/
        #   # APP_UUID, GEAR_UUID, APP_NAME, APP_DNS, HOMEDIR, DATA_DIR, \
        #   #   GEAR_DNS, GEAR_NAME, PATH, REPO_DIR, TMP_DIR, HISTFILE
        #   # ~/app-root
        #   # ~/app-root/data
        #   # ~/app-root/runtime/repo
        #   # ~/app-root/repo -> runtime/repo
        #   # ~/app-root/runtime/data -> ../data
        #
        # Returns nil on Success and raises on Failure.
        def initialize_homedir(basedir, homedir)
          notify_observers(:before_initialize_homedir)
          homedir = homedir.end_with?('/') ? homedir : homedir + '/'

          # Required for polyinstantiated tmp dirs to work
          [".tmp", ".sandbox"].each do |poly_dir|
            full_poly_dir = PathUtils.join(homedir, poly_dir)
            FileUtils.mkdir_p full_poly_dir
            FileUtils.chmod(0000, full_poly_dir)
          end

          # Polydir runs before the marker is created so set up sandbox by hand
          sandbox_uuid_dir = PathUtils.join(homedir, ".sandbox", @uuid)
          FileUtils.mkdir_p sandbox_uuid_dir
          set_rw_permission(sandbox_uuid_dir)

          env_dir = PathUtils.join(homedir, ".env")
          FileUtils.mkdir_p(env_dir)
          FileUtils.chmod(0750, env_dir)
          set_ro_permission(env_dir)

          user_env_dir = PathUtils.join(homedir, '.env', 'user_vars')
          FileUtils.mkdir_p(user_env_dir)
          FileUtils.chmod(0770, user_env_dir)
          set_ro_permission(user_env_dir)

          ssh_dir = PathUtils.join(homedir, ".ssh")
          FileUtils.mkdir_p(ssh_dir)
          FileUtils.chmod(0750, ssh_dir)
          set_ro_permission(ssh_dir)

          gem_home = PathUtils.join(homedir, ".gem")
          add_env_var "GEM_HOME", gem_home
          FileUtils.mkdir_p(gem_home)
          FileUtils.chmod(0750, gem_home)
          set_rw_permission(gem_home)

          geardir = PathUtils.join(homedir, @container_name) + "/"
          gearappdir = PathUtils.join(homedir, "app-root") + "/"

          add_env_var("APP_DNS",
                      "#{@application_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                      true)
          add_env_var("APP_NAME", @application_name, true)
          add_env_var("APP_UUID", @application_uuid, true)

          data_dir = PathUtils.join(gearappdir, "data") + "/"
          add_env_var("DATA_DIR", data_dir, true) {|v|
            FileUtils.mkdir_p(v, :verbose => @debug)
          }

          deployments_dir = PathUtils.join(homedir, "app-deployments") + "/"
          add_env_var("DEPLOYMENTS_DIR", deployments_dir, true) {|v|
            FileUtils.mkdir_p("#{v}/by-id", :verbose => @debug)
            set_rw_permission_R(deployments_dir)
          }

          # create initial deployment directory
          create_deployment_dir

          archives_dir = PathUtils.join(homedir, "app-archives") + "/"
          add_env_var("ARCHIVES_DIR", archives_dir, true) {|v|
            FileUtils.mkdir_p(v, :verbose => @debug)
            set_rw_permission(archives_dir)
          }

          add_env_var("HISTFILE", PathUtils.join(data_dir, ".bash_history"))
          profile = PathUtils.join(data_dir, ".bash_profile")
          File.open(profile, File::WRONLY|File::TRUNC|File::CREAT, 0600) {|file|
          file.write %Q{
# Warning: Be careful with modifications to this file,
#          Your changes may cause your application to fail.
}
          }
          set_rw_permission(profile)
          set_rw_permission_R(data_dir)

          add_env_var("GEAR_DNS",
                      "#{@container_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                      true)
          add_env_var("GEAR_NAME", @container_name, true)
          add_env_var("GEAR_UUID", @uuid, true)
          add_env_var("HOMEDIR", homedir, true)

          # Ensure HOME exists for git support
          add_env_var("HOME", homedir, false)

          FileUtils.mkdir_p(PathUtils.join(gearappdir, "runtime"), :verbose => @debug)

          add_env_var("DEPENDENCIES_DIR", PathUtils.join(gearappdir, "runtime", "dependencies") + "/", true)
          add_env_var("BUILD_DEPENDENCIES_DIR", PathUtils.join(gearappdir, "runtime", "build-dependencies") + "/", true)

          add_env_var("REPO_DIR", PathUtils.join(gearappdir, "runtime", "repo") + "/", true) do |v|
            # don't create the actual dir, since it's now a symlink
            #FileUtils.mkdir_p(v, :verbose => @debug)
            FileUtils.cd gearappdir do |d|
              FileUtils.ln_s("runtime/repo", "repo", :verbose => @debug)
              FileUtils.ln_s("runtime/dependencies", "dependencies", :verbose => @debug)
            end
            FileUtils.cd PathUtils.join(gearappdir, "runtime") do |d|
              FileUtils.ln_s("../data", "data", :verbose => @debug)
            end
          end

          add_env_var("TMP_DIR", "/tmp/", true)
          add_env_var("TMP_DIR", "/tmp/", false)
          add_env_var("TMPDIR", "/tmp/", false)
          add_env_var("TMP", "/tmp/", false)

          # Update all directory entries ~/app-root/*
          Dir[gearappdir + "/*"].entries.reject{|e| ['.', '..', 'repo', 'dependencies'].include?(File.basename(e))}.each {|e|
            FileUtils.chmod_R(0750, e, :verbose => @debug)
            set_rw_permission_R(e)
          }

          # Change symlink ownership
          PathUtils.oo_lchown(uid, gid, "#{gearappdir}/repo", "#{gearappdir}/dependencies")

          set_ro_permission(gearappdir)
          raise "Failed to instantiate gear: missing application directory (#{gearappdir})" unless File.exist?(gearappdir)

          state_file = PathUtils.join(gearappdir, "runtime", ".state")
          File.open(state_file, File::WRONLY|File::TRUNC|File::CREAT, 0660) {|file|
            file.write "new\n"
            set_rw_permission(state_file)
          }

          ::OpenShift::Runtime::FrontendHttpServer.new(self).create

          # Fix SELinux context for cart dirs
          set_rw_permission(profile)
          reset_permission_R(homedir)
        end

        ##
        # Generate an RSA ssh key
        def generate_ssh_key()
          ssh_dir        = PathUtils.join(@container_dir, '.openshift_ssh')
          known_hosts    = PathUtils.join(ssh_dir, 'known_hosts')
          ssh_config     = PathUtils.join(ssh_dir, 'config')
          ssh_key        = PathUtils.join(ssh_dir, 'id_rsa')
          ssh_public_key = ssh_key + '.pub'

          FileUtils.mkdir_p(ssh_dir)
          set_rw_permission(ssh_dir)

          run_in_container_context("/usr/bin/ssh-keygen -N '' -f #{ssh_key}",
                                   chdir:               @container_dir,
                                   timeout:             @hourglass.remaining,
                                   expected_exitstatus: 0)

          FileUtils.touch(known_hosts)
          FileUtils.touch(ssh_config)

          set_rw_permission_R(ssh_dir)

          FileUtils.chmod(0750, ssh_dir)
          FileUtils.chmod(0600, [ssh_key, ssh_public_key])
          FileUtils.chmod(0660, [known_hosts, ssh_config])

          add_env_var('APP_SSH_KEY', ssh_key, true)
          add_env_var('APP_SSH_PUBLIC_KEY', ssh_public_key, true)

          public_key_bytes = IO.read(ssh_public_key)
          public_key_bytes.sub!(/^ssh-rsa /, '')

          "APP_SSH_KEY_ADD: #{@uuid} #{public_key_bytes}\n"
        end

        # Private: Determine next available user id.  This is usually determined
        #           and provided by the broker but is auto determined if not
        #           provided.
        #
        # Examples:
        #   next_uid =>
        #   # => 504
        #
        # Returns Integer value for next available uid.
        def next_uid
          uids = IO.readlines("/etc/passwd").map{ |line| line.split(":")[2].to_i }
          gids = IO.readlines("/etc/group").map{ |line| line.split(":")[2].to_i }
          min_uid = (@config.get("GEAR_MIN_UID") || "500").to_i
          max_uid = (@config.get("GEAR_MAX_UID") || "1500").to_i

          (min_uid..max_uid).each do |i|
            if !uids.include?(i) and !gids.include?(i)
              return i
            end
          end
        end
      end
    end
  end
end
