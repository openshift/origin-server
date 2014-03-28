#
# Manage Kerberos5 k5login entries for a gear
#
require 'set'
require 'fcntl'
require 'etc'

#
# The k5login file 
#
# k5login man page
# k5login URL
#
# The k5login file contains a principal string on each line.  When an auth/
# access request is received and contains a principal which cannot be derived
# from the local username, this file is checked to determine if the principal
# will be granted access.
# 
# OpenShift wants to allow multiple openshift users to submit a principal to
# a gear.  The principal is only removed when all owner IDs have been removed
# from the principal.
#
# This class models that multiple ownership by inserting comment lines before
# the principal line.  These comment lines have the form /^# id: <id string>$/
# As the file is read these lines are accumulated and then when a non-comment
# line is encountered, the collected ID strings are attached to the principal
# string.
#
# Each time a new principal/id pair is added, if the principal is present, the
# id is added to the ownership set.
#
# When a principal/id pair is removed, the id is first removed and then 
# the principal removed only if the number of remaining ids is 0
#
# Example
#
# # id: longidstring1
# # id: longidstring2
# testuser1@EXAMPLE.COM
#
# # id: idstring1
# testuser2@EXAMPLE.COM
# 
# ... 
#
# Since "comment" lines form invalid principal strings no real user will ever
# try to authenticate with them and if they do access will be denied.
# Well formated lines will match as normal
#
# The list of principals and their sets of associated IDs are represented as
# a hash of Sets.  Each hash key is a Kerberos principal string.  The hash
# value is a Set of strings corresponding to the associated ID strings.
#
# The K5login.clone and K5login.compare functions provide a deep copy and
# deep comparison so that the k5login file is only written if changes are made.
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
        #   k.add_principal('user1@EXAMPLE.COM', id=nil)
        #   k.del_principal('user2@EXAMPLE.COM', id=nil)
        #
        #   allowed = k.principals
        #
        #   k.principals = { 'user3@EXAMPLE.COM' => [<idlist], 
        #                    'user4@EXAMPLE.COM' => [<idlist]
        #                  }
        class K5login

          attr_reader :container, :username, :config_file, :filename
          attr_accessor :owner, :group, :mode
          attr_accessor :lockfile

          @@mutex = Mutex.new
          @@default_owner = 0
          @@default_group = 0
          @@default_mode = 0644

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
          def initialize(container, config_file=nil, filename=nil)
            @container = container
            @username = container.uuid
            @config_file = config_file ? File.expand_path(config_file) : '/etc/krb5.conf'
            @filename = filename ? File.expand_path(filename) : k5login_file

            # override for testing
            user = Etc.getpwnam('root')
            @owner = user.uid # root
            begin
              @group = Etc.getpwnam(@username).gid
            rescue ArgumentError => e
              @group = @@default_group
            end
            @mode = @@default_mode

            @lockfile = "/var/lock/oo-k5login.#{@username}"
          end

          # Public: Determine the location of the user's k5login file
          #
          # It resides in the user's home directory unless otherwise specified
          # in the system /etc/krb5.conf
          #
          # Returns: String - The absolute path to the k5login file
          #
          def k5login_file(config_file=nil)

            config_file ||= @config_file
            if File.exists? config_file

              krb5_config = ParseConfig.new config_file
              if (libdefaults = krb5_config['libdefaults']) and (k5login_directory = libdefaults['k5login_directory'])
                return k5login_directory + "/" + @username
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
          def add_principal(principal, id=nil)
            modify do |_principals|
              if _principals.member? principal
                # add an id to the existing principal (dup safe for sets)
                _principals[principal] << id if not id == nil
              else 
                # add the principal # id set is empty if id is nil
                _principals.merge!({principal => Set.new(id ? [id] : [])})
              end
            end
          end

          # Public: delete a single principal from the current set
          # 
          # principal: String - a Kerberos principal
          # key_name: String - an identifier to manage duplicate principals
          #                    from different users
          #                    currently discarded pending additional work
          def remove_principal(principal, id=nil)
            modify do |_principals|
              _principals.select! do |p, idset|
                # keep non-match or matches with non-empty id sets
                p != principal or idset.delete(id).length > 0
              end
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
                _principals[p['key']] = Set.new if not _principals[p['key']]
                _principals[p['key']] << p['comment'] if p['comment'] and p['comment'].strip.length > 0
              end
            end

          end


          private

          # return a deep copy of a principal hash
          def self.clone(phash)
            nhash = phash.clone
            nhash.each_key {|k| nhash[k] = nhash[k].clone }
          end

          # deep compare of two principal hashes
          #
          # check that the array of keys is the same and then that
          # the contents of all sets is identical
          #
          def self.compare(h0, h1)
            h0.keys === h1.keys && h0.map {|k, v| h1[k] === v}.reduce(:&)
          end

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

            _principals = {}
            @@mutex.synchronize do

              # prevent external race conditions/collisions
              lockfile_flags = File::RDWR|File::CREAT|File::TRUNC
              lockfile_mode = 0600

              File.open(@lockfile, lockfile_flags, lockfile_mode) do | lock |
                lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
                lock.flock(File::LOCK_EX)

                begin
                  flags =  File::RDWR|File::CREAT
                  mode = 0640

                  changed = false
                  File.open(@filename, flags, mode) do | file |

                    id_set = Set.new

                    #
                    # Create the list of principals and a set of ids for each
                    #
                    file.readlines.each do |line|
                      line.strip!

                      # skip empty lines
                      next if line.length == 0

                      # build up principal "ids" who have placed this principal
                      m = line.match /#\s*id\s*:\s*(.*)$/
                      if m
                        id_set << (m[1] == '' ? nil : m[1])
                        next
                      end

                      # principals are non-comment non-empty lines
                      id_set << nil if not line.start_with?('#') and
                        id_set.length == 0

                      # add the principal to the hash
                      _principals[line] = id_set
                      # and reset for the next iteration
                      id_set = Set.new

                    end

                    if block_given?
                      old_principals = K5login.clone(_principals)

                      yield _principals

                      if not K5login.compare(old_principals, _principals)
                        file.seek(0, IO::SEEK_SET)
                        # write all of the ids and then the principal string
                        _principals.each {|principal, id_list|
                          id_list.each {|id|
                            file.write "# id: #{id}\n"
                          }
                          file.write principal + "\n\n"
                        }
                        # remove the extra newline
                        file.truncate(file.tell - 1) if file.tell > 0
                        changed = true
                      end
                    end
                  end
                  if changed
                    # set ownership
                    File.chown @owner, @group, @filename 

                    # set permissions
                    File.chmod @mode, @filename if @mode

                    # set SELinux labels
                    cmd = "restorecon  #{@filename}"
                    ::OpenShift::Runtime::Utils::oo_spawn(cmd)
                  end
                ensure
                  lock.flock(File::LOCK_UN)
                  lock.close
                  File.delete lockfile
                end
              end
            end

            @principals = _principals
            File.delete @filename if @principals.length == 0
            @principals
          end


        end

      end
    end
  end
end
