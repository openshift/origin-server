require 'fcntl'
require 'shellwords'

module OpenShift
  module Runtime
    module ApplicationContainerExt
      module SecureShell

        # Manage a user (gear/container) SSH authorized_keys file and entries
        class AuthorizedKeysFile


          attr_reader :container, :username, :filename
          attr_accessor :owner, :group, :mode
          attr_accessor :lockfile

          @@mutex = Mutex.new
          @@default_owner = 0
          @@default_group = 0
          @@default_mode = 0440

          def initialize(container, filename=nil)
            @container = container
            @username = container.uuid
            @filename = filename ||
              @container.container_dir + "/.ssh/authorized_keys"

            # override for testing
            user = Etc.getpwnam('root')
            @owner = user.uid # root
            begin
              @group = Etc.getpwnam(@username).gid
            rescue ArgumentError => e
              @group = @@default_group
            end
            @mode = @@default_mode

            @lockfile = "/var/lock/oo-modify-ssh-keys.#{@username}"
          end

          def authorized_keys
            modify
          end

          #
          # Bodies from environment.rb globals
          #
          # Public: Append an SSH key to a users authorized_keys file
          #
          # key_string - The String value of the ssh key.
          # key_type - The String value of the key type ssh-(rsa|dss)).
          # comment - The String value of the comment to append to the key.
          #
          # Examples
          #
          #   add_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
          #               'ssh-rsa',
          #               'example@example.com')
          #   # => nil
          #
          # Returns nil on Success or raises on Failure
          def add_key(key_string, key_type=nil, comment=nil, login=nil )
            #@container.logger.info "Adding new key #{key_string} #{key_type} #{comment} #{login}"
            comment = "" unless comment

            modify do |keys|
              keys[key_id(comment)] = key_entry(key_string, key_type, comment, login)
            end

          end

          #
          # Bodies from environment.rb globals
          #
          # Public: Append SSH keys to a users authorized_keys file
          #
          # keys - An Array of keys
          #
          # Examples
          #
          #   add_keys([{"content"=>'AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
          #               "type" => 'ssh-rsa',
          #               "comment" => 'example@example.com'}])
          #   # => nil
          #
          # Returns nil on Success or raises on Failure
          def add_keys(new_keys)
            #@container.logger.info "Adding these new keys #{new_keys}"
            modify do |keys|
              new_keys.each do |k|
                comment = k["comment"] || ""
                keys[key_id(comment)] = key_entry(k["content"], k["type"], comment, k["login"])
              end
            end
          end

          # Public: Remove an SSH key from a users authorized_keys file
          #
          # key_string - The String value of the ssh key.
          # key_type - The String value of the key type ssh-(rsa|dss)).
          # comment - The String value of the comment to append to the key.
          #
          # Examples
          #
          #   remove_ssh_key('AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
          #                  'ssh-rsa',
          #                  'example@example.com')
          #   # => nil
          #
          # Returns nil on Success or raises on Failure
          #
          def remove_key(key_string, key_type=nil, comment=nil, login=nil)
            modify do |keys|
              if comment
                keys.delete_if{ |k, v| v.end_with?(key_id(comment)) }
              else
                keys.delete_if{ |k,v| v.include?(key_string) }
              end
            end
          end

          # Public: Remove SSH keys from a users authorized_keys file
          #
          # keys - An Array of keys
          #
          # Examples
          #
          #   remove_keys([{"content"=>'AAAAB3NzaC1yc2EAAAADAQABAAABAQDE0DfenPIHn5Bq/...',
          #               "type" => 'ssh-rsa',
          #               "comment" => 'example@example.com'}])
          #   # => nil
          #
          # Returns nil on Success or raises on Failure
          #
          def remove_keys(old_keys)
            modify do |keys|
              old_keys.each do |key|
                if key["comment"]
                  keys.delete_if{ |k, v| v.end_with?(key_id(key["comment"])) }
                else
                  keys.delete_if{ |k,v| v.include?(key["content"]) }
                end
              end
            end
          end

          # Public: Replace all of the SSH authorized_keys file entries
          #
          # new_keys - an Array of Hashes, each containing
          #    key => String,
          #    type => String
          #    comment => String
          #
          # Examples:
          #   k = [
          #       {'key' => 'AAA...',
          #        'type' => 'ssh-rsa',
          #        'comment' => 'String'
          #       },
          #       {'key' => 'bar...',
          #        'type' => 'ssh-rsa',
          #        'comment' => 'more'
          #       },
          #       {'key' => 'AAA...',
          #        'type' => 'ssh-rsa',
          #        'comment' => 'String'},
          #       ]
          #   replace_keys(k)
          #
          # Returns: nil on Success
          #
          def replace_keys(new_keys)

            modify do |keys|
              # remove all keys
              keys.delete_if{ |k, v| true }

              # add the new keys in
              new_keys.each do |key|
                id = key_id(key['comment'])
                entry = key_entry(key['key'], key['type'], key['comment'], key['login'])
                keys[id] = entry
              end
            end
          end

          private

          # validate the ssh keys to check for the required attributes
          #
          # ssh_keys must be an array
          # ssh_keys[n] must be a hash
          # ssh_keys[n]['key'] must be a non-empty string
          # ssh_keys[n]['type'] must be a non-empty string
          # ssh_keys[n]['comment'] must be nil or a non-empty string
          #
          def validate_keys(ssh_keys)
            return false unless ssh_keys.is_a? Array
            ssh_keys.each do |entry|
              return false if entry.nil?
              return false if not
                (entry['key'].is_a? String and entry['key'].length > 0)
              return false if not
                (entry['type'].is_a? String and entry['type'].length > 0)
              return false if not
                (entry['comment'].nil? or
                (entry['comment'].is_a? String and entry['comment'].length > 0))
            end
            true
          end

          # This version does exactly the same as the previous one but uses
          # only lazy-evaluation boolean logic and map-reduce to collect
          # the value for each entry
          def clever_validate_keys(ssh_keys)
            ssh_keys.is_a? Array and
            # check each entry
            ssh_keys.map { |entry|
              not entry.nil? and
              entry['key'].is_a? String and entry['key'].length > 0 and
              entry['type'].is_a? String and entry['type'].length > 0 and
              (entry['comment'].nil? or
               (entry['comment'].is_a? String and entry['comment'].length > 0))
            # any false results invalidates the whole set
            }.reduce(:&)
          end

          # This value is used both as a lookup id for add/remove operations
          # and as the actual comment field of the authorized key line
          def key_id(comment)
            "OPENSHIFT-#{@container.uuid}-#{comment}"
          end

          # Create a single SSH Authorized keys entry
          def key_entry(key_string, key_type, comment, login)
            shell     = @container.container_plugin.gear_shell || "/bin/bash"
            prefix    = login ? "OPENSHIFT_LOGIN=#{Shellwords.escape login} " : ""
            command   = "command=\"#{prefix}#{shell}\",no-X11-forwarding"
            [command, key_type, key_string, key_id(comment)].join(' ')
          end

          # private: Modify ssh authorized_keys file
          #
          # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
          # @return [Hash] authorized keys with the comment field as the key
          # private: Modify ssh authorized_keys file
          #
          # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
          # @return [Hash] authorized keys with the comment field as the key
          def modify
            authorized_keys_file = @filename
            keys                 = Hash.new

            @@mutex.synchronize do
              PathUtils.flock(@lockfile) do
                File.open(authorized_keys_file, File::RDWR|File::CREAT, @mode) do |file|
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
                  file.close
                end
                PathUtils.oo_chown(0, @container.gid, authorized_keys_file)
                @container.chcon(authorized_keys_file,
                                      ::OpenShift::Runtime::Utils::SelinuxContext.instance.get_mcs_label(@container.uid))
              end
            end
            keys
          end # modify()

        end # AuthorizedKeysFile

      end # SecureShell
    end # ApplicationContainerExt
  end # RunTime
end # OpenShift
