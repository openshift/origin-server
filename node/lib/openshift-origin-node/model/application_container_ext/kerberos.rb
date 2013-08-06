#
# Manage Kerberos5 k5login entries for a gear
#
module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Kerberos

        # Public: manage kerberos principals allowed access to an account
        #
        # This class will use the system /etc/krb5.conf file and the
        # [libdefaults] k5login_directory value to determine where to place
        # the k5login file.  If the krb5.conf file does not exist or the
        # k5login_directory is not defined, then the file will be placed in
        # $HOME/.k5login for each account.
        #
        # SEE ALSO
        #   man krb5.conf
        #   man k5login
        #
        # Examples
        #   k = K5login.new(username)
        #
        #   k.add_principal('user1@EXAMPLE.COM')
        #   k.del_principal('user2@EXAMPLE.COM')
        #
        #   allowed = k.principals
        #
        #   k.principals = ['user3@EXAMPLE.COM', 'user4@EXAMPLE.COM']
        class K5login

          attr_reader :username, :config_file, :filename

          @@mutex = Mutex.new

          # Public: Create a new K5login manager
          #
          # username -    [String] the username to manage
          # config_file - [String] optional kerberos configuration file
          # filename -    [String] optional k5login file to manage
          #
          # Examples
          #
          #   Normal use: 
          #     k = K5login.new(username)
          #
          #   Testing with a k5login_directory from a test configuration
          #     testk = K5login.new('testuser', '/tmp/krb5.conf')
          #
          #   Testing with an explicit k5login filename
          #     testk = K5login.new('testuser2', nil, '/tmp/test_k5login')
          #
          def initialize(container, config_file='/etc/krb5.conf', filename=nil)
            @container = container
            @username = container.uuid
            @config_file = File.expand_path config_file
            @filename = k5login_file
          end
          
          # Public: Determine the location of the user's k5login file
          #
          # It resides in the user's home directory unless otherwise specified
          # in the system /etc/krb5.conf
          #
          # Returns: String - The absolute path to the k5login file
          #
          def k5login_file
            
            if File.exists? @config_file

              krb5_config = ParseConfig.new @config_file

              if krb5_config['k5login_directory']
                return krb5_config['k5login_directory'] + "/" + @username
              end

            end

            @container.container_dir + "/.k5login"
          end

          # Public: retrieve and return the current contents of the k5login file
          #
          # @return [Array] the list of allowed Kerberos principals
          #
          # Examples
          #   k = K5login.new(username)
          #   p = k.principals
          #
          def principals
            modify
          end

          # Public: add a single principal to the current set
          #
          # principal: String - a Kerberos principal
          # key_name: String - an identifier to manage duplicate principals
          #                    from different users
          #                    currently discarded pending additional work
          def add_principal(principal, key_name=nil)
            modify do |_principals|
              if not _principals.member? principal
                _principals << principal 
              end
            end
          end
          
          # Public: delete a single principal from the current set
          # 
          # principal: String - a Kerberos principal
          # key_name: String - an identifier to manage duplicate principals
          #                    from different users
          #                    currently discarded pending additional work
          def remove_principal(principal, key_name=nil)
            modify do |_principals|
              _principals.select! {|p| not p == principal }
            end
          end

          # Public: replace all principals
          # 
          # new_principals: Array of Hashes:
          #    {'key' => String,  a kerberos principal
          #     'type' => String == 'krb5-principal',
          #     'comment' => String - an identifier to manage duplicate
          #                           principals from different users
          #                           currently discarded pending more work
          def replace_principals(new_principals)
            modify do | _principals |
              # remove all entries
              _principals.delete_if {|p| true }
              
              # add all of the new entries
              new_principals.each do |p|
                _principals << p['key']
              end
            end

          end


          private
          # Private: retrieve and update the contents of the k5login file
          #
          # @yields [Array] the current list of allowed user principals
          # @return [Array] the final list of allowed user principals
          #
          # This method performs both synchronization (via a mutex) and file
          # locking to avoid race conditions and collisions.  It requires the
          # priviledges necessary to read and write files owned by arbitrary
          # users as well as to establish system wide shared locks.
          # 
          def modify
            _principals = []
            @@mutex.synchronize do

              # prevent external race conditions/collisions
              lockfile = "/var/lock/oo-k5login.#{@username}"
              lockfile_flags = File::RDWR|File::CREAT|File::TRUNC
              lockfile_mode = 0600

              File.open(lockfile, lockfile_flags, lockfile_mode) do | lock |
                lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
                lock.flock(File::LOCK_EX)
                
                begin
                  flags =  File::RDWR|File::CREAT
                  mode = 0640

                  File.open(@filename, flags, mode) do | file |
                    _principals += file.readlines.map {|line| line.chomp }

                    if block_given?
                      old_principals = _principals.clone

                      yield _principals
                      
                      if old_principals != _principals
                        file.seek(0, IO::SEEK_SET)
                        file.write(_principals.join("\n")+"\n")
                        file.truncate(file.tell)
                      end
                    end
                  end
                  # set permissions
                  # set SELinux labels
                  cmd = "restorecon  #{@filename}"
                  ::OpenShift::Runtime::Utils::oo_spawn(cmd)

                ensure
                  lock.flock(File::LOCK_UN)
                  lock.close
                  File.delete lockfile
                end
              end
            end
            
            @principals = _principals
            File.delete @filename if @principals == []            
            @principals
          end


        end

      end
    end
  end
end
