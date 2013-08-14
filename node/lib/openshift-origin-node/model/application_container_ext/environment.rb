module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Environment
        # Public: Add an environment variable to a given gear.
        #
        # key - The String value of target environment variable.
        # value - The String value to place inside the environment variable.
        # prefix_cloud_name - The String value to append in front of key.
        #
        # Examples
        #
        #  add_env_var('mysql-5.3')
        #  # => 36
        #
        # Returns the Integer value for how many bytes got written or raises on
        # failure.
        def add_env_var(key, value, prefix_cloud_name = false, &blk)
          env_dir = PathUtils.join(@container_dir, '.env/')
          key = "OPENSHIFT_#{key}" if prefix_cloud_name

          filename = PathUtils.join(env_dir, key)
          File.open(filename, File::WRONLY|File::TRUNC|File::CREAT) do |file|
            file.write value.to_s
          end
          set_ro_permission(filename)

          if block_given?
            blk.call(value)
          end
        end

        # Public: Remove an environment variable from a given gear.
        #
        # key - String name of the environment variable to remove.
        # prefix_cloud_name - String prefix to append to key.
        #
        # Examples
        #
        #   remove_env_var('OPENSHIFT_MONGODB_DB_URL')
        #   # => nil
        #
        # Returns an nil on success and false on failure.
        def remove_env_var(key, prefix_cloud_name=false)
          status = false
          [".env", ".env/.uservars"].each do |path|
            env_dir = PathUtils.join(@container_dir,path)
            if prefix_cloud_name
              key = "OPENSHIFT_#{key}"
            end
            env_file_path = PathUtils.join(env_dir, key)
            FileUtils.rm_f env_file_path
            status = status ? true : (File.exists?(env_file_path) ? false : true)
          end
          status
        end

        # Public: Add broker authorization keys so gear can communicate with
        #         broker.
        #
        # iv - A String value for the IV file.
        # token - A String value for the token file.
        #
        # Examples
        #   add_broker_auth('ivvalue', 'tokenvalue')
        #   # => ["/var/lib/openshift/UUID/.auth/iv",
        #         "/var/lib/openshift/UUID/.auth/token"]
        #
        # Returns An Array of Strings for the newly created auth files
        def add_broker_auth(iv,token)
          broker_auth_dir=PathUtils.join(@container_dir,'.auth')
          FileUtils.mkdir_p broker_auth_dir
          File.open(PathUtils.join(broker_auth_dir, 'iv'),
                    File::WRONLY|File::TRUNC|File::CREAT) do |file|
            file.write iv
          end
          File.open(PathUtils.join(broker_auth_dir, 'token'),
                    File::WRONLY|File::TRUNC|File::CREAT) do |file|
            file.write token
          end

          set_rw_permission_R(broker_auth_dir)
          FileUtils.chmod(0o0750, broker_auth_dir)
          FileUtils.chmod(0o0640, Dir.glob("#{broker_auth_dir}/*"))
        end

        # Public: Remove broker authentication keys from gear.
        #
        # Examples
        #   remove_broker_auth
        #   # => nil
        #
        # Returns nil on Success and false on Failure
        def remove_broker_auth
          broker_auth_dir=PathUtils.join(@container_dir, '.auth')
          FileUtils.rm_rf broker_auth_dir
          File.exists?(broker_auth_dir) ? false : true
        end

        # Public: Append an SSH key to a users authorized_keys file
        #
        # key - The String value of the ssh key.
        # key_type - The String value of the key type ssh-(rsa|dss)).
        # comment - The String value of the comment to append to the key.
        #
        # Examples
        #
        #   add_ssh_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
        #               'ssh-rsa',
        #               'example@example.com')
        #   # => nil
        #
        # Returns nil on Success or raises on Failure
        def add_ssh_key(key, key_type=nil, comment=nil)
          comment = "" unless comment
          self.class.notify_observers(:before_add_ssh_key, self, key)

          ssh_comment, cmd_entry = get_ssh_key_cmd_entry(key, key_type, comment)

          modify_ssh_keys do |keys|
            keys[ssh_comment] = cmd_entry
          end

          self.class.notify_observers(:after_add_ssh_key, self, key)
        end

        # Public: Remove an SSH key from a users authorized_keys file.
        #
        # key - The String value of the ssh key.
        # comment - The String value of the comment associated with the key.
        #
        # Examples
        #
        #   remove_ssh_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
        #               'example@example.com')
        #   # => nil
        #
        # Returns nil on Success or raises on Failure
        def remove_ssh_key(key, comment=nil)
          self.class.notify_observers(:before_remove_ssh_key, self, key)

          modify_ssh_keys do |keys|
            if comment
              keys.delete_if{ |k, v| v.include?(comment) }
            else
              keys.delete_if{ |k,v| v.include?(key) }
            end
          end

          self.class.notify_observers(:after_remove_ssh_key, self, key)
        end

        # Public: Remove all existing SSH keys and add the new ones to a users authorized_keys file.
        #
        # ssh_keys - The Array of ssh keys.
        #
        # Examples
        #
        #   replace_ssh_keys([{'key' => AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...', 'type' => 'ssh-rsa', 'name' => 'key1'}])
        #   # => nil
        #
        # Returns nil on Success or raises on Failure
        def replace_ssh_keys(ssh_keys)
          raise Exception.new('The provided ssh keys do not have the required attributes') unless validate_ssh_keys(ssh_keys)

          self.class.notify_observers(:before_replace_ssh_keys, self)

          modify_ssh_keys do |keys|
            keys.delete_if{ |k, v| true }

            ssh_keys.each do |key|
              ssh_comment, cmd_entry = get_ssh_key_cmd_entry(key['key'], key['type'], key['comment'])
              keys[ssh_comment] = cmd_entry
            end
          end

          ssh_dir = PathUtils.join(@container_dir, ".ssh")
          cmd = "restorecon -R #{ssh_dir}"
          ::OpenShift::Runtime::Utils::oo_spawn(cmd)
        end

        # Generate the command entry for the ssh key to be written into the authorized keys file
        def get_ssh_key_cmd_entry(key, key_type, comment)
          key_type    = "ssh-rsa" if key_type.to_s.strip.length == 0
          cloud_name  = "OPENSHIFT"
          ssh_comment = "#{cloud_name}-#{@uuid}-#{comment}"
          shell       = @container_plugin.gear_shell || "/bin/bash"
          cmd_entry   = "command=\"#{shell}\",no-X11-forwarding #{key_type} #{key} #{ssh_comment}"

          [ssh_comment, cmd_entry]
        end

        # validate the ssh keys to check for the required attributes
        def validate_ssh_keys(ssh_keys)
          ssh_keys.each do |key|
            begin
              if key['key'].nil? or key['type'].nil? and key['comment'].nil?
                return false
              end
            rescue Exception => ex
              return false
            end
          end
          return true
        end

        # private: Modify ssh authorized_keys file
        #
        # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
        # @return [Hash] authorized keys with the comment field as the key
        # private: Modify ssh authorized_keys file
        #
        # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
        # @return [Hash] authorized keys with the comment field as the key
        def modify_ssh_keys
          authorized_keys_file = PathUtils.join(@container_dir, ".ssh", "authorized_keys")
          keys = Hash.new

          $OpenShift_ApplicationContainer_SSH_KEY_MUTEX.synchronize do
            File.open("/var/lock/oo-modify-ssh-keys.#{@uuid}", File::RDWR|File::CREAT|File::TRUNC, 0o0600) do | lock |
              lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
              lock.flock(File::LOCK_EX)
              begin
                File.open(authorized_keys_file, File::RDWR|File::CREAT, 0o0440) do |file|
                  file.each_line do |line|
                    begin
                      keys[line.split[-1].chomp] = line.chomp
                    rescue
                    end
                  end

                  if block_given?
                    old_keys = keys.clone

                    yield keys

                    if old_keys != keys
                      file.seek(0, IO::SEEK_SET)
                      file.write(keys.values.join("\n")+"\n")
                      file.truncate(file.tell)
                    end
                  end
              end
                set_ro_permission(authorized_keys_file)
                ::OpenShift::Runtime::Utils::oo_spawn("restorecon #{authorized_keys_file}")
              ensure
                lock.flock(File::LOCK_UN)
              end
            end
          end
          keys
        end
      end
    end
  end
end
