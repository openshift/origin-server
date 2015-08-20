require 'openshift-origin-node/utils/threads'
require 'openshift-origin-node/model/application_container_ext/ssh_authorized_keys'
require 'openshift-origin-node/model/application_container_ext/kerberos'

module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Environment

        include Kerberos
        include SecureShell

        USER_VARIABLE_MAX_COUNT      = 50
        USER_VARIABLE_NAME_MAX_SIZE  = 128
        USER_VARIABLE_VALUE_MAX_SIZE = 512
        RESERVED_VARIABLE_NAMES      = %w(OPENSHIFT_PRIMARY_CARTRIDGE_DIR OPENSHIFT_NAMESPACE PATH IFS USER SHELL HOSTNAME LOGNAME)
        ALLOWED_OVERRIDES            = %w(OPENSHIFT_SECRET_TOKEN)

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
        # Returns an true on success and false on failure.
        def remove_env_var(key, prefix_cloud_name=false)
          key = "OPENSHIFT_#{key}" if prefix_cloud_name

          env_file_path = PathUtils.join(@container_dir, '.env', key)
          FileUtils.rm_f env_file_path
          !File.exists?(env_file_path)
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
          FileUtils.chmod(0750, broker_auth_dir)
          FileUtils.chmod(0640, Dir.glob("#{broker_auth_dir}/*"))
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
        #
        # Four functions for managing gear access through SSH
        # add/remove a single key value
        # replace all keys
        # validate the form of a set of keys in an array
        #
        # Keys can be SSH Authorized Keys or Kerberos 5 principal strings.
        #

        # Public: Add user access by SSH to a gear
        #
        # Examples
        # container.add_ssh_key("alongstring", "ssh-rsa", "a users key", "testuser")
        #
        # container.add_ssh_key("testuser@EXAMPLE.COM", "krb5-principal", "testuser")
        #
        # Returns: nil
        #
        def add_ssh_key(key_string, key_type=nil, comment=nil, login=nil)
          if key_type == "krb5-principal"
            # create a K5login object and add it

            self.class.notify_observers(:before_add_krb5_principal,
                                        self, key_string)
            K5login.new(self).add_principal(key_string, comment)
            self.class.notify_observers(:after_add_krb5_principal,
                                        self, key_string)

          else
            # create an SshAuthorizedKeys file object and add to it.
            self.class.notify_observers(:before_add_ssh_key, self, key_string)
            AuthorizedKeysFile.new(self).add_key(key_string, key_type, comment, login)
            self.class.notify_observers(:after_add_ssh_key, self, key_string)
          end
        end


        # Public: Add several SSH keys to a gear
        #
        # Examples
        #   container.add_ssh_keys([{:content => "alongstring", :type => "ssh-rsa", :comment => "a users key"}, {:content => "testuser@EXAMPLE.COM", :type => "krb5-principal"}])
        #
        # Returns: nil
        #
        def add_ssh_keys(keys)
          ssh_authorized_keys = []
          keys.each do |key|
            #TODO batch add these type of keys
            if key["type"] == "krb5-principal"
              # create a K5login object and add it
              self.class.notify_observers(:before_add_krb5_principal,
                                        self, key["content"])
              K5login.new(self).add_principal( key["content"], key["comment"])
              self.class.notify_observers(:after_add_krb5_principal,
                                        self, key["content"])
            else
              ssh_authorized_keys.push(key)
            end
          end
          # create an SshAuthorizedKeys file object and add to it.
          self.class.notify_observers(:before_add_ssh_key, self, ssh_authorized_keys)
          AuthorizedKeysFile.new(self).add_keys(ssh_authorized_keys)
          self.class.notify_observers(:after_add_ssh_key, self, ssh_authorized_keys)
        end

        # Public: remove user access by SSH to a gear
        #
        # Examples
        #   container.remove_ssh_key("alongstring", "ssh-rsa", "a users key")
        #
        #   container.remove_ssh_key("testuser@EXAMPLE.COM", "krb5-principal")
        #
        # Returns: nil
        #
        def remove_ssh_key(key_string, key_type=nil, comment=nil)
          if key_type == "krb5-principal"
            # create a K5login object and add it

            self.class.notify_observers(:before_remove_krb5_principal,
                                        self, key_string)
            K5login.new(self).remove_principal(key_string, comment)
            self.class.notify_observers(:after_remove_krb5_principal,
                                        self, key_string)

          else
            # create an SshAuthorizedKeys file object and add to it.
            self.class.notify_observers(:before_remove_ssh_key,
                                        self,
                                        key_string)
            AuthorizedKeysFile.new(self).remove_key(key_string, key_type, comment)
            self.class.notify_observers(:after_remove_ssh_key, self, key_string)
          end
        end

        # Public: remove user access by removing SSH keys from a gear
        #
        # Examples
        #   container.remove_keys[{:content => "alongstring", :type => "ssh-rsa", :comment => "a users key"}, {:content => "testuser@EXAMPLE.COM", :type => "krb5-principal"}])
        #
        # Returns: nil
        #
        def remove_ssh_keys(keys)
          ssh_authorized_keys = []
          keys.each do |key|
            if key["type"] == "krb5-principal"
              self.class.notify_observers(:before_remove_krb5_principal,
                                          self, key["content"])
              K5login.new(self).remove_principal(key["content"], key["comment"])
              self.class.notify_observers(:after_remove_krb5_principal, self, key["content"])
            else
              ssh_authorized_keys.push(key)
            end
          end
          self.class.notify_observers(:before_remove_ssh_key, self, ssh_authorized_keys)
          AuthorizedKeysFile.new(self).remove_keys(ssh_authorized_keys)
          self.class.notify_observers(:after_remove_ssh_key, self, ssh_authorized_keys)
        end

        # Public: replace all user access by SSH to a gear
        #
        # Examples:
        #
        # Replace all of the existing keys with one SSH and one Kerberos key
        #
        # a = [{'key' => 'ansshkeystring',
        #       'type' => 'ssh-rsa',
        #       'comment' => "app-user-name" },
        #      {'key' => 'testuser@EXAMPLE.COM',
        #       'type' => 'krb5-principal',
        #       'comment' => 'app-user-name2"}
        #     ]
        #
        # container.replace_ssh_keys(a)
        #
        # Returns: nil
        def replace_ssh_keys(ssh_keys)

          raise Exception.new('The provided ssh keys do not have the required attributes') unless validate_ssh_keys(ssh_keys)

          # sort the keys into
          authorized_keys = ssh_keys.select {|k| k['type'] != 'krb5-principal'}
          krb5_principals = ssh_keys.select {|k| k['type'] == 'krb5-principal'}

          self.class.notify_observers(:before_replace_ssh_keys, self)
          # If an empty ssh_keys list is passed, this will intentionally replace the ssh keys with an empty list
          # The broker should pass all keys available for the application to this method
          AuthorizedKeysFile.new(self).replace_keys(authorized_keys)
          K5login.new(self).replace_principals(krb5_principals)
          self.class.notify_observers(:after_replace_ssh_keys, self)

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


        # Add user environment variable(s)
        def user_var_add(variables, gears = [])
          directory = PathUtils.join(@container_dir, '.env', 'user_vars')
          FileUtils.mkpath(directory) unless File.directory?(directory)

          if (Dir.entries(directory).size - 2 + variables.size) > USER_VARIABLE_MAX_COUNT
            variables.each_pair do |name,value|
              path = PathUtils.join(directory, name)
              return 255, "CLIENT_ERROR: User Variables maximum of #{USER_VARIABLE_MAX_COUNT} exceeded\n" if !File.exists?(path)
            end
          end

          variables.each_pair do |name, value|
            path = PathUtils.join(@container_dir, '.env', name)

            if !ALLOWED_OVERRIDES.include?(name) && (File.exists?(path) ||
                name =~ /\AOPENSHIFT_.*_IDENT\Z/ ||
                RESERVED_VARIABLE_NAMES.include?(name))
              return 255, "CLIENT_ERROR: #{name} cannot be overridden"
            end

            if name.to_s.length > USER_VARIABLE_NAME_MAX_SIZE
              return 255, "CLIENT_ERROR: Name '#{name}' exceeds maximum size of #{USER_VARIABLE_NAME_MAX_SIZE}b\n"
            end
            if value.to_s.length > USER_VARIABLE_VALUE_MAX_SIZE
              return 255, "CLIENT_ERROR: '#{name}' value exceeds maximum size of #{USER_VARIABLE_VALUE_MAX_SIZE}b\n"
            end
            if value.to_s.include? "\\000"
              return 255, "CLIENT_ERROR: '#{name}' value cannot contain nullsb\n"
            end
          end

          variables.each_pair do |name, value|
            path = PathUtils.join(directory, name)
            File.open(path, 'w', 0440) do |f|
              f.write(value)
            end
            set_ro_permission(path)
          end

          return user_var_push(gears, true) unless gears.empty?
          return 0, ''
        end

        # Remove user environment variable(s)
        def user_var_remove(variables, gears = [])
          directory = PathUtils.join(@container_dir, '.env', 'user_vars')
          output = ''
          variables.each do |name|
            path = PathUtils.join(directory, name)
            if File.exists?(path)
              FileUtils.rm_f(path)
            else
              output << "CLIENT_MESSAGE: User environment variable not found: #{name}\n"
            end
          end

          exit_code = 0
          unless gears.empty?
            exit_code, push_output = user_var_push(gears)
            output = push_output + output if push_output
          end
          return exit_code, output
        end

        # update user environment variable(s) on other gears
        def user_var_push(gears, env_add=false)
          output, gear_dns, threads = '', '', {}
          target  = PathUtils.join('.env', 'user_vars').freeze
          source  = PathUtils.join(@container_dir, target).freeze
          return 0, '' unless File.directory?(source)
          return 0, '' if env_add and (Dir.entries(source) - %w{. ..}).empty?

          begin
            gears.each do |gear|
              logger.debug("Updating #{gear} from #{source}")
              threads[gear] = OpenShift::Runtime::Threads.new_thread(gear) do |fqdn|
                gear_dns = fqdn
                retries  = 2
                begin
                  command = "/usr/bin/rsync -rp0S --delete -e '/usr/bin/oo-ssh' #{source}/ #{fqdn}:#{target}"
                  env = OpenShift::Runtime::Utils::Environ.for_gear(@container_dir)
                  ::OpenShift::Runtime::Utils::oo_spawn(command, expected_exitstatus: 0, uid: @uid, env: env)
                rescue Exception => e
                  NodeLogger.logger.debug { "Push #{retries} #{source} exception #{e.message}" }
                  Thread.current[:exception] = e
                  retries                    -= 1
                  sleep(0.5)
                  retry if 0 < retries
                end
              end
            end
          rescue Exception => e
            logger.error("Failed to update #{gear_dns} from #{@container_dir}/#{source}. #{e.message}")
            return 1, "CLIENT_ERROR: #{e.message}"
          ensure
            loop do
              threads.each_pair do |id, thread|
                case thread.status
                  when false
                    thread.join
                    if thread[:exception]
                      output << "CLIENT_ERROR: Sync for #{id} user variables failed.\n"
                      if thread[:exception].is_a?(::OpenShift::Runtime::Utils::ShellExecutionException)
                        logger.error("Sync for #{id} user variables failed.")
                        logger.error(thread[:exception].stderr)
                      else
                        logger.error("Sync for #{id} user variables failed #{thread[:exception].message}")
                      end
                    end
                    threads.delete(id)
                  when nil
                    threads.delete(id)
                end
              end
              sleep(0.5)
              break if threads.empty?
            end
          end

          return output.empty? ? 0 : 1, output
        end

        # Retrieve user environment variable(s)
        def user_var_list(variables = [])
          directory = PathUtils.join(@container_dir, '.env', 'user_vars')
          return {} unless File.directory?(directory)

          env = ::OpenShift::Runtime::Utils::Environ::load(directory)
          return env if !variables || variables.empty?

          variables.each_with_object({}) do |name, memo|
            memo[name] = env[name]
          end
        end

      end
    end
  end
end
