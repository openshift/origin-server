#--
# Copyright 2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require 'rubygems'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/selinux'
require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-node/model/frontend_httpd.rb'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-common'
require 'fcntl'
require 'active_model'

module OpenShift
  class UserCreationException < Exception
  end

  class UserDeletionException < Exception
  end

  # == Unix User
  #
  # Represents a user account on the system.
  class UnixUser
    include OpenShift::Utils::ShellExec
    include ActiveModel::Observing
    include NodeLogger

    attr_reader :uuid, :uid, :gid, :gecos, :homedir, :application_uuid,
        :container_uuid, :app_name, :namespace, :quota_blocks, :quota_files,
        :container_name
    attr_accessor :debug

    DEFAULT_SKEL_DIR = File.join(OpenShift::Config::CONF_DIR,"skel")

    @@MODIFY_SSH_KEY_MUTEX = Mutex.new

    def initialize(application_uuid, container_uuid, user_uid=nil,
        app_name=nil, container_name=nil, namespace=nil, quota_blocks=nil, quota_files=nil, debug=false)
      @config = OpenShift::Config.new
      @cartridge_format = Utils::Sdk.node_default_model(@config)

      @container_uuid = container_uuid
      @application_uuid = application_uuid
      @uuid = container_uuid
      @app_name = app_name
      @container_name = container_name
      @namespace = namespace
      @quota_blocks = quota_blocks
      @quota_files = quota_files
      @debug = debug

      begin
        user_info = Etc.getpwnam(@uuid)
        @uid = user_info.uid
        @gid = user_info.gid
        @gecos = user_info.gecos
        @homedir = "#{user_info.dir}/"
      rescue ArgumentError => e
        @uid = user_uid
        @gid = user_uid
        @gecos = nil
        @homedir = nil
      end
    end

    def name
      @uuid
    end

    # Public: Create an empty gear.
    #
    # Examples
    #
    #   create
    #   # => nil
    #   # a user
    #   # Setup permissions
    #
    # Returns nil on Success or raises on Failure
    def create
      skel_dir = @config.get("GEAR_SKEL_DIR") || DEFAULT_SKEL_DIR
      shell    = @config.get("GEAR_SHELL")     || "/bin/bash"
      gecos    = @config.get("GEAR_GECOS")     || "OO application container"
      notify_observers(:before_unix_user_create)
      basedir = @config.get("GEAR_BASE_DIR")
      supplementary_groups = @config.get("GEAR_SUPL_GRPS")

      # lock to prevent race condition between create and delete of gear
      uuid_lock_file = "/var/lock/oo-create.#{@uuid}"
      File.open(uuid_lock_file, File::RDWR|File::CREAT, 0o0600) do | uuid_lock |
        uuid_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
        uuid_lock.flock(File::LOCK_EX)

        # Lock to prevent race condition on obtaining a UNIX user uid.
        # When running without districts, there is a simple search on the
        #   passwd file for the next available uid.
        File.open("/var/lock/oo-create", File::RDWR|File::CREAT, 0o0600) do | uid_lock |
          uid_lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          uid_lock.flock(File::LOCK_EX)

          unless @uid
            @uid = @gid = next_uid
          end

          unless @homedir
            @homedir = File.join(basedir,@uuid)
          end

          cmd = %{useradd -u #{@uid} \
                  -d #{@homedir} \
                  -s #{shell} \
                  -c '#{gecos}' \
                  -m \
                  -k #{skel_dir} \
                  #{@uuid}}
          if supplementary_groups != ""
            cmd << %{ -G "#{supplementary_groups}"}
          end
          out,err,rc = shellCmd(cmd)
          raise UserCreationException.new(
                  "ERROR: unable to create user account(#{rc}): #{cmd.squeeze(" ")} stdout: #{out} stderr: #{err}"
                  ) unless rc == 0

          PathUtils.oo_chown("root", @uuid, @homedir)
          FileUtils.chmod 0o0750, @homedir

          if @config.get("CREATE_APP_SYMLINKS").to_i == 1
            unobfuscated = File.join(File.dirname(@homedir),"#{@container_name}-#{namespace}")
            if not File.exists? unobfuscated
              FileUtils.ln_s File.basename(@homedir), unobfuscated, :force=>true
            end
          end
        end
        notify_observers(:after_unix_user_create)
        initialize_homedir(basedir, @homedir, @config.get("CARTRIDGE_BASE_PATH"))
        initialize_openshift_port_proxy

        uuid_lock.flock(File::LOCK_UN)
        File.unlink(uuid_lock_file)
      end
    end

    # Public: Destroys a gear stopping all processes and removing all files
    #
    # The order of the calls and gyrations done in this code is to prevent
    #   pam_namespace from locking polyinstantiated directories during
    #   their deletion. If you see "broken" gears, i.e. ~uuid/.tmp and
    #    ~/uuid/.sandbox after #destroy has been called, this method is broken.
    # See Bug 853582 for history.
    #
    # Examples
    #
    #   destroy
    #   # => nil
    #
    # Returns nil on Success or raises on Failure
    def destroy
      if @uid.nil? or (@homedir.nil? or !File.directory?(@homedir.to_s))
        # gear seems to have been destroyed already... suppress any error
        # TODO : remove remaining stuff if it exists, e.g. .httpd/#{uuid}* etc
        return nil
      end
      raise UserDeletionException.new(
            "ERROR: unable to destroy user account #{@uuid}"
            ) if @uuid.nil?

      # Don't try to delete a gear that is being scaled-up|created|deleted
      uuid_lock_file = "/var/lock/oo-create.#{@uuid}"
      File.open(uuid_lock_file, File::RDWR|File::CREAT, 0o0600) do | lock |
        lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
        lock.flock(File::LOCK_EX)

        # These calls and their order is designed to release pam_namespace's
        #   locks on .tmp and .sandbox. Change then at your peril.
        #
        # 1. Kill off the easy processes
        # 2. Lock down the user from creating new processes (cgroups freeze, nprocs 0)
        # 3. Attempt to move any processes that didn't die into state 'D' (re: cgroups freeze)
        self.class.kill_procs(@uid)
        notify_observers(:before_unix_user_destroy)
        self.class.kill_procs(@uid)

        purge_sysvipc(uuid)
        initialize_openshift_port_proxy

        if @config.get("CREATE_APP_SYMLINKS").to_i == 1
          Dir.foreach(File.dirname(@homedir)) do |dent|
            unobfuscate = File.join(File.dirname(@homedir), dent)
            if (File.symlink?(unobfuscate)) &&
                (File.readlink(unobfuscate) == File.basename(@homedir))
              File.unlink(unobfuscate)
            end
          end
        end

        OpenShift::FrontendHttpServer.new(@container_uuid,@container_name,@namespace).destroy

        dirs = list_home_dir(@homedir)
        cmd = "userdel -f \"#{@uuid}\""
        out,err,rc = shellCmd(cmd)
        raise UserDeletionException.new(
              "ERROR: unable to destroy user account(#{rc}): #{cmd} stdout: #{out} stderr: #{err}"
              ) unless rc == 0

        # 1. Don't believe everything you read on the userdel man page...
        # 2. If there are any active processes left pam_namespace is not going
        #      to let polyinstantiated directories be deleted.
        FileUtils.rm_rf(@homedir)
        if File.exists?(@homedir)
          # Ops likes the verbose verbage
          logger.warn %Q{
1st attempt to remove \'#{@homedir}\' from filesystem failed.
Dir(before)   #{@uuid}/#{@uid} => #{dirs}
Dir(after)    #{@uuid}/#{@uid} => #{list_home_dir(@homedir)}
          }
        end

        # release resources (cgroups thaw), this causes Zombies to get killed
        notify_observers(:after_unix_user_destroy)

        # try one last time...
        if File.exists?(@homedir)
          sleep(5)                    # don't fear the reaper
          FileUtils.rm_rf(@homedir)   # This is our last chance to nuke the polyinstantiated directories
          logger.warn("2nd attempt to remove \'#{@homedir}\' from filesystem failed.") if File.exists?(@homedir)
        end

        lock.flock(File::LOCK_UN)
        File.unlink(uuid_lock_file)
      end
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
        keys.delete_if{ |k, v| v.include?(key)}
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

      self.class.notify_observers(:after_replace_ssh_keys, self)
    end

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
      env_dir = File.join(@homedir, '.env/')
      key = "OPENSHIFT_#{key}" if prefix_cloud_name

      filename = File.join(env_dir, key)
      File.open(filename, File::WRONLY|File::TRUNC|File::CREAT) do |file|
        if :v1 == @cartridge_format
          file.write "export #{key}='#{value}'"
        else
          file.write value.to_s
        end
      end

      mcs_label = Utils::SELinux.get_mcs_label(uid)
      PathUtils.oo_chown(0, gid, filename)
      Utils::SELinux.set_mcs_label(mcs_label, filename)

      if block_given?
        blk.call(value)
      end
    end

    # Public: list directories (cartridges) in home directory
    # @param  [String] home directory
    # @return [String] comma separated list of directories
    def list_home_dir(home_dir)
      results = []
      if File.exists?(home_dir)
        Dir.foreach(home_dir) do |entry|
          #next if entry =~ /^\.{1,2}/   # Ignore ".", "..", or hidden files
          results << entry
        end
      end
      results.join(', ')
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
        env_dir = File.join(@homedir,path)
        if prefix_cloud_name
          key = "OPENSHIFT_#{key}"
        end
        env_file_path = File.join(env_dir, key)
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
      broker_auth_dir=File.join(@homedir,'.auth')
      FileUtils.mkdir_p broker_auth_dir
      File.open(File.join(broker_auth_dir, 'iv'),
            File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write iv
      end
      File.open(File.join(broker_auth_dir, 'token'),
            File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write token
      end

      PathUtils.oo_chown_R("root", @uuid,broker_auth_dir)
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
      broker_auth_dir=File.join(@homedir, '.auth')
      FileUtils.rm_rf broker_auth_dir
      File.exists?(broker_auth_dir) ? false : true
    end

    #private

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
    def initialize_homedir(basedir, homedir, cart_basedir)
      @homedir = homedir
      notify_observers(:before_initialize_homedir)
      homedir = homedir.end_with?('/') ? homedir : homedir + '/'

      # Required for polyinstantiated tmp dirs to work
      [".tmp", ".sandbox"].each do |poly_dir|
        full_poly_dir = File.join(homedir, poly_dir)
        FileUtils.mkdir_p full_poly_dir
        FileUtils.chmod(0o0000, full_poly_dir)
      end

      # Polydir runs before the marker is created so set up sandbox by hand
      sandbox_uuid_dir = File.join(homedir, ".sandbox", @uuid)
      FileUtils.mkdir_p sandbox_uuid_dir
      if @cartridge_format == :v1
        FileUtils.chmod(0o1755, sandbox_uuid_dir)
      else
        PathUtils.oo_chown(@uuid, nil, sandbox_uuid_dir)
      end

      env_dir = File.join(homedir, ".env")
      FileUtils.mkdir_p(env_dir)
      FileUtils.chmod(0o0750, env_dir)
      PathUtils.oo_chown(nil, @uuid, env_dir)

      ssh_dir = File.join(homedir, ".ssh")
      FileUtils.mkdir_p(ssh_dir)
      FileUtils.chmod(0o0750, ssh_dir)
      PathUtils.oo_chown(nil, @uuid, ssh_dir)

      geardir = File.join(homedir, @container_name, "/")
      gearappdir = File.join(homedir, "app-root", "/")

      add_env_var("APP_DNS",
                  "#{@app_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("APP_NAME", @app_name, true)
      add_env_var("APP_UUID", @application_uuid, true)

      data_dir = File.join(gearappdir, "data", "/")
      add_env_var("DATA_DIR", data_dir, true) {|v|
        FileUtils.mkdir_p(v, :verbose => @debug)
      }
      add_env_var("HISTFILE", File.join(data_dir, ".bash_history"))
      profile = File.join(data_dir, ".bash_profile")
      File.open(profile, File::WRONLY|File::TRUNC|File::CREAT, 0o0600) {|file|
        file.write %Q{
# Warning: Be careful with modifications to this file,
#          Your changes may cause your application to fail.
}
      }
      PathUtils.oo_chown(@uuid, @uuid, profile, :verbose => @debug)


      add_env_var("GEAR_DNS",
                  "#{@container_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("GEAR_NAME", @container_name, true)
      add_env_var("GEAR_UUID", @container_uuid, true)

      add_env_var("HOMEDIR", homedir, true)

      # Ensure HOME exists for git support
      add_env_var("HOME", homedir, false)

      add_env_var("PATH",
                  "#{cart_basedir}/abstract-httpd/info/bin/:#{cart_basedir}/abstract/info/bin/:/bin:/sbin:/usr/bin:/usr/sbin:/$PATH",
                  false)

      add_env_var("REPO_DIR", File.join(gearappdir, "runtime", "repo", "/"), true) {|v|
        FileUtils.mkdir_p(v, :verbose => @debug)
        FileUtils.cd gearappdir do |d|
          FileUtils.ln_s("runtime/repo", "repo", :verbose => @debug)
        end
        FileUtils.cd File.join(gearappdir, "runtime") do |d|
          FileUtils.ln_s("../data", "data", :verbose => @debug)
        end
      }

      add_env_var("TMP_DIR", "/tmp/", true)
      add_env_var("TMP_DIR", "/tmp/", false)
      add_env_var("TMPDIR", "/tmp/", false)
      add_env_var("TMP", "/tmp/", false)

      # Update all directory entries ~/app-root/*
      Dir[gearappdir + "/*"].entries.reject{|e| [".", ".."].include? e}.each {|e|
        FileUtils.chmod_R(0o0750, e, :verbose => @debug)
        PathUtils.oo_chown_R(@uuid, @uuid, e, :verbose => @debug)
      }
      PathUtils.oo_chown(nil, @uuid, gearappdir, :verbose => @debug)
      raise "Failed to instantiate gear: missing application directory (#{gearappdir})" unless File.exist?(gearappdir)

      state_file = File.join(gearappdir, "runtime", ".state")
      File.open(state_file, File::WRONLY|File::TRUNC|File::CREAT, 0o0660) {|file|
        file.write "new\n"
      }
      PathUtils.oo_chown(@uuid, @uuid, state_file, :verbose => @debug)

      OpenShift::FrontendHttpServer.new(@container_uuid,@container_name,@namespace).create

      # Fix SELinux context for cart dirs
      Utils::SELinux.clear_mcs_label_R(homedir)
      Utils::SELinux.set_mcs_label_R(Utils::SELinux.get_mcs_label(@uid), Dir.glob(File.join(homedir, '*')))

      notify_observers(:after_initialize_homedir)
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

    # Private: Initialize OpenShift Port Proxy for this gear
    #
    # The port proxy range is determined by configuration and must
    # produce identical results to the abstract cartridge provided
    # range.
    #
    # Examples:
    # initialize_openshift_port_proxy
    #    => true
    #    service openshift_port_proxy setproxy 35000 delete 35001 delete etc...
    #
    # Returns:
    #    true   - port proxy could be initialized properly
    #    false  - port proxy could not be initialized properly
    def initialize_openshift_port_proxy
      notify_observers(:before_initialize_openshift_port_proxy)

      proxy_server = FrontendProxyServer.new
      proxy_server.delete_all_for_uid(@uid, true)

      notify_observers(:after_initialize_openshift_port_proxy)
    end


    # Private: Kill all processes for a given gear
    #
    # Kill all processes owned by the uid or uuid.
    # No reason for graceful shutdown first, the directories and user are going
    #   to be removed from the system.
    #
    # Examples:
    # kill_gear_procs
    #    => true
    #    pkill -u id
    #
    # Raises exception on error.
    #
    def self.kill_procs(id)
      if id.nil? or id == ""
        raise ArgumentError, "Supplied ID must be a uid."
      end

      # Give it a good try to delete all processes.
      # This abuse is neccessary to release locks on polyinstantiated
      #    directories by pam_namespace.
      out = err = rc = nil
      10.times do |i|
        OpenShift::Utils::ShellExec.shellCmd(%{/usr/bin/pkill -9 -u #{id}})
        out,err,rc = OpenShift::Utils::ShellExec.shellCmd(%{/usr/bin/pgrep -u #{id}})
        break unless 0 == rc

        NodeLogger.logger.error "ERROR: attempt #{i}/10 there are running \"killed\" processes for #{id}(#{rc}): stdout: #{out} stderr: #{err}"
        sleep 0.5
      end

      # looks backwards but 0 implies processes still existed
      if 0 == rc
        out,err,rc = OpenShift::Utils::ShellExec.shellCmd("ps -u #{@uid} -o state,pid,ppid,cmd")
        NodeLogger.logger.error "ERROR: failed to kill all processes for #{id}(#{rc}): stdout: #{out} stderr: #{err}"
      end
    end

    # Private: Purge IPC entities for a given gear
    #
    # Enumerate and remove all IPC entities for a given user ID or
    # user name.
    #
    # Examples:
    # purge_sysvipc
    #    => true
    #    ipcs -c
    #    ipcrm -s id
    #    ipcrm -m id
    #
    # Raises exception on error.
    #
    def purge_sysvipc(id)
      if id.nil? or id == ""
        raise ArgumentError.new("Supplied ID must be a user name or uid.")
      end

      ['-m', '-q', '-s' ].each do |ipctype|
        out,err,rc=shellCmd(%{/usr/bin/ipcs -c #{ipctype} 2> /dev/null})
        out.lines do |ipcl|
          next unless ipcl=~/^\d/
          ipcent = ipcl.split
          if ipcent[2] == id
            # The ID may already be gone
            shellCmd(%{/usr/bin/ipcrm #{ipctype} #{ipcent[0]}})
          end
        end
      end
    end

    # private: Modify ssh authorized_keys file
    #
    # @yields [Hash] authorized keys with the comment field as the key which will save if modified.
    # @return [Hash] authorized keys with the comment field as the key
    def modify_ssh_keys
      authorized_keys_file = File.join(@homedir, ".ssh", "authorized_keys")
      keys = Hash.new

      @@MODIFY_SSH_KEY_MUTEX.synchronize do
        File.open("/var/lock/oo-modify-ssh-keys", File::RDWR|File::CREAT, 0o0600) do | lock |
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
            PathUtils.oo_chown_R('root', @uuid, authorized_keys_file)
            shellCmd("restorecon #{authorized_keys_file}")
          ensure
            lock.flock(File::LOCK_UN)
          end
        end
      end
      keys
    end

    # Generate the command entry for the ssh key to be written into the authorized keys file
    def get_ssh_key_cmd_entry(key, key_type, comment)
      key_type    = "ssh-rsa" if key_type.to_s.strip.length == 0
      cloud_name  = "OPENSHIFT"
      ssh_comment = "#{cloud_name}-#{@uuid}-#{comment}"
      shell       = @config.get("GEAR_SHELL") || "/bin/bash"
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

    # Deterministically constructs an IP address for the given UID based on the given
    # host identifier (LSB of the IP). The host identifier must be a value between 1-127
    # inclusive.
    #
    # The global user IP range begins at 0x7F000000.
    #
    # Returns an IP address string in dotted-quad notation.
    def self.get_ip_addr(uid, host_id)
      raise "Invalid host_id specified" unless host_id && host_id.is_a?(Integer)
      raise "Invalid UID specified" unless uid && uid.is_a?(Integer)

      if uid.to_i < 0 || uid.to_i > 262143
        raise "User uid #{@uid} is outside the working range 0-262143"
      end

      if host_id < 1 || host_id > 127
        raise "Supplied host identifier #{host_id} must be between 1 and 127"
      end

      # Generate an IP (32-bit unsigned) in the user's range
      ip = 0x7F000000 + (uid.to_i << 7)  + host_id

      # Return the IP in dotted-quad notation
      "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}"
    end

    # Deterministically constructs a network and netmask for the given UID
    #
    # The global user IP range begins at 0x7F000000.
    #
    # Returns an IP network and netmask in dotted-quad notation.
    def self.get_ip_network(uid)
      raise "Invalid UID specified" unless uid && uid.is_a?(Integer)

      if uid.to_i < 0 || uid.to_i > 262143
        raise "User uid #{@uid} is outside the working range 0-262143"
      end
      # Generate the network (32-bit unsigned) for the user's range
      ip = 0x7F000000 + (uid.to_i << 7)

      # Return the network/netmask in dotted-quad notation
      [ "#{ip >> 24}.#{ip >> 16 & 0xFF}.#{ip >> 8 & 0xFF}.#{ip & 0xFF}", "255.255.255.128" ]
    end

    #
    # Public: Return a UnixUser object loaded from the gear_uuid on the system
    #
    # Caveat: the quota information will not be populated.
    #
    def self.from_uuid(container_uuid)
      config = OpenShift::Config.new
      gecos = config.get("GEAR_GECOS") || "OO application container"
      pwent = Etc.getpwnam(container_uuid)
      if pwent.gecos != gecos
        raise ArgumentError, "Not an OpenShift gear: #{gear_uuid}"
      end
      env = Utils::Environ.for_gear(pwent.dir)
      UnixUser.new(env["OPENSHIFT_APP_UUID"], pwent.name, pwent.uid,
                   env["OPENSHIFT_APP_NAME"], env["OPENSHIFT_GEAR_NAME"],
                   env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,""))
    end

    #
    # Public: Return an enumerator which provides a UnixUser object for
    # every OpenShift user in the system.
    #
    # Caveat: the quota information will not be populated.
    #
    def self.all
      Enumerator.new do |yielder|
        config = OpenShift::Config.new
        gecos = config.get("GEAR_GECOS") || "OO application container"

        # Some duplication with from_uuid; it may be expensive to keep re-parsing passwd.
        # Etc is not reentrent.  Capture the password table in one shot.
        pwents = []
        Etc.passwd do |pwent|
          pwents << pwent.clone
        end

        pwents.each do |pwent|
          if pwent.gecos == gecos
            u = nil
            begin
              env = Utils::Environ.for_gear(pwent.dir)
              u = UnixUser.new(env["OPENSHIFT_APP_UUID"], pwent.name, pwent.uid,
                               env["OPENSHIFT_APP_NAME"], env["OPENSHIFT_GEAR_NAME"],
                               env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,""))
            rescue => e
              NodeLogger.logger.error("Failed to instantiate UnixUser for #{pwent.uid}: #{e}")
              NodeLogger.logger.error("Backtrace: #{e.backtrace}")
            else
              yielder.yield(u)
            end
          end
        end
      end
    end

  end
end
