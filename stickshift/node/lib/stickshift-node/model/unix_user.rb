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
require 'stickshift-node/config'
require 'stickshift-node/utils/shell_exec'
require 'stickshift-common'
require 'syslog'
require 'fcntl'

module StickShift
  class UserCreationException < Exception
  end

  class UserDeletionException < Exception
  end
  
  # == Unix User
  #
  # Represents a user account on the system.
  class UnixUser < Model
    include StickShift::Utils::ShellExec
    attr_reader :uuid, :uid, :gid, :gecos, :homedir, :application_uuid,
        :container_uuid, :app_name, :namespace, :quota_blocks, :quota_files
    attr_accessor :debug

    DEFAULT_SKEL_DIR = File.join(StickShift::Config::CONF_DIR,"skel")

    def initialize(application_uuid, container_uuid, user_uid=nil,
        app_name=nil, container_name=nil, namespace=nil, quota_blocks=nil, quota_files=nil, debug=false)
      @config = StickShift::Config.instance
      
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
      gecos    = @config.get("GEAR_GECOS")     || "SS application container"
      notify_observers(:before_unix_user_create)
      basedir = @config.get("GEAR_BASE_DIR")
      
      File.open("/var/lock/ss-create", File::RDWR|File::CREAT, 0o0600) do | lock |
        lock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) 
        lock.flock(File::LOCK_EX)
        
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
        out,err,rc = shellCmd(cmd)
        raise UserCreationException.new(
                "ERROR: unable to create user account #{@uuid}, #{cmd}"
                ) unless rc == 0
        
        FileUtils.chown("root", @uuid, @homedir)
        FileUtils.chmod 0o0750, @homedir
      end
      notify_observers(:after_unix_user_create)
      initialize_homedir(basedir, @homedir, @config.get("CARTRIDGE_BASE_PATH"))
    end
    
    # Public: Destroys a gear stopping all processes and removing all files
    #
    # Examples
    #
    #   destroy
    #   # => nil
    #
    # Returns nil on Success or raises on Failure
    def destroy
      raise UserDeletionException.new(
            "ERROR: unable to destroy user account #{@uuid}"
            ) if @uid.nil? || @homedir.nil? || @uuid.nil?
      notify_observers(:before_unix_user_destroy)
      
      cmd = %{/bin/ps -U '#{@uuid}' -o pid | \
              /bin/grep -v PID | \
              xargs kill -9 2> /dev/null}
      (1..10).each do |i|
        out,err,rc = shellCmd(cmd)
        break unless rc == 0
      end
      
      FileUtils.rm_rf(@homedir)

      basedir = @config.get("GEAR_BASE_DIR")
      path = File.join(basedir, ".httpd.d", "#{uuid}_*")
      FileUtils.rm_rf(Dir.glob(path))

      out,err,rc = shellCmd("userdel \"#{@uuid}\"")
      raise UserDeletionException.new(
            "ERROR: unable to destroy user account: #{@uuid}   stdout: #{out}   stderr:#{err}") unless rc == 0
      notify_observers(:after_unix_user_destroy)
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
      self.class.notify_observers(:before_add_ssh_key, self, key)
      ssh_dir = File.join(@homedir, ".ssh")
      cloud_name = @config.get("CLOUD_NAME") || "SS"
      authorized_keys_file = File.join(ssh_dir,"authorized_keys")
      shell    = @config.get("GEAR_SHELL")     || "/bin/bash"
      key_type = "ssh-rsa" if key_type.to_s.strip.length == 0
      comment  = "" unless comment
      
      cmd_entry = "command=\"#{shell}\",no-X11-forwarding #{key_type} #{key} #{cloud_name}-#{@uuid}#{comment}\n"
      FileUtils.mkdir_p ssh_dir
      FileUtils.chmod(0o0750,ssh_dir)
      File.open(authorized_keys_file,
        File::WRONLY|File::APPEND|File::CREAT, 0o0440) do | file |
        file.write(cmd_entry)
      end
      FileUtils.chmod 0o0440, authorized_keys_file
      FileUtils.chown_R("root",@uuid,ssh_dir)
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
      ssh_dir = File.join(@homedir, '.ssh')
      authorized_keys_file = File.join(ssh_dir,'authorized_keys')
      
      FileUtils.mkdir_p ssh_dir
      FileUtils.chmod(0o0750,ssh_dir)
      keys = []
      File.open(authorized_keys_file, File::RDONLY|File::CREAT, 0o0440) do
            | file |
        keys = file.readlines
      end
      
      if comment
        keys.delete_if{ |k| k.include?(key) && k.include?(comment)}
      else
        keys.delete_if{ |k| k.include?(key)}
      end
      keys.map!{ |k| k.strip }
      
      File.open(authorized_keys_file, File::WRONLY|File::TRUNC|File::CREAT,
                0o0440) do |file|
        file.write(keys.join("\n"))
        file.write("\n")
      end
      
      FileUtils.chmod 0o0440, authorized_keys_file
      FileUtils.chown('root', @uuid, ssh_dir)
      self.class.notify_observers(:after_remove_ssh_key, self, key)
    end

    # Public: Add an environment variable to a given gear.
    #
    # key - The String value of target environment variable.
    # value - The String value to place inside the environment variable.
    # prefix_cloud_name - The String value to append in front of key.
    #
    # Examples
    #
    #  add_env_var('OPENSHIFT_DB_TYPE',
    #               'mysql-5.3')
    #  # => 36
    #
    # Returns the Integer value for how many bytes got written or raises on 
    # failure.
    def add_env_var(key, value, prefix_cloud_name = false, &blk)
      env_dir = File.join(@homedir,'.env/')
      if prefix_cloud_name
        key = (@config.get('CLOUD_NAME') || 'SS') + "_#{key}"
      end
      File.open(File.join(env_dir, key),
            File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write "export #{key}='#{value}'"
      end

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
    #   remove_env_var('OPENSHIFT_DB_TYPE')
    #   # => nil
    #
    # Returns an nil on success and false on failure.
    def remove_env_var(key, prefix_cloud_name=false)
      env_dir = File.join(@homedir,".env")
      if prefix_cloud_name
        key = (@config.get("CLOUD_NAME") || "SS") + "_#{key}"
      end
      env_file_path = File.join(env_dir, key)
      FileUtils.rm_f env_file_path
      File.exists?(env_file_path) ? false : true
    end
    
    # Public: Add broker authorization keys so gear can communicate with 
    #         broker.
    #
    # iv - A String value for the IV file.
    # token - A String value for the token file.
    #
    # Examples
    #   add_broker_auth('ivvalue', 'tokenvalue')
    #   # => ["/var/lib/stickshift/UUID/.auth/iv",
    #         "/var/lib/stickshift/UUID/.auth/token"]
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
      
      FileUtils.chown_R("root", @uuid,broker_auth_dir)
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

    def run_as(&block)
      old_gid = Process::GID.eid
      old_uid = Process::UID.eid
      fork{
        Process::GID.change_privilege(@gid.to_i)
        Process::UID.change_privilege(@uid.to_i)      
        yield block          
      }
      Process.wait  
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
    #   # ~/.env/
    #   # APP_UUID, GEAR_UUID, APP_NAME, APP_DNS, HOMEDIR, DATA_DIR, GEAR_DIR, \
    #   #   GEAR_DNS, GEAR_NAME, GEAR_CTL_SCRIPT, PATH, REPO_DIR, TMP_DIR
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
      
      tmp_dir = File.join(homedir, ".tmp")
      # Required for polyinstantiated tmp dirs to work
      FileUtils.mkdir_p tmp_dir
      FileUtils.chmod(0o0000, tmp_dir)
            
      env_dir = File.join(homedir, ".env")
      FileUtils.mkdir_p(env_dir)
      FileUtils.chmod(0o0750, env_dir)
      FileUtils.chown(nil, @uuid, env_dir)

      geardir = File.join(homedir, @container_name, "/")
      gearappdir = File.join(homedir, "app-root", "/")

      add_env_var("APP_DNS",
                  "#{@app_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("APP_NAME", @app_name, true)
      add_env_var("APP_UUID", @application_uuid, true)

      add_env_var("DATA_DIR", File.join(gearappdir, "data", "/"), true) {|v|
        FileUtils.mkdir_p(v, :verbose => @debug)
      }

      add_env_var("GEAR_DIR", geardir, true)
      add_env_var("GEAR_DNS",
                  "#{@container_name}-#{@namespace}.#{@config.get("CLOUD_DOMAIN")}",
                  true)
      add_env_var("GEAR_NAME", @container_name, true)
      add_env_var("GEAR_UUID", @container_uuid, true)

      add_env_var("HOMEDIR", homedir, true)

      add_env_var("PATH",
                  "#{cart_basedir}abstract-httpd/info/bin/:#{cart_basedir}abstract/info/bin/:$PATH",
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

      # Update all directory entries ~/app-root/*
      Dir[gearappdir + "/*"].entries.reject{|e| [".", ".."].include? e}.each {|e|
        FileUtils.chmod_R(0o0750, e, :verbose => @debug)
        FileUtils.chown_R(@uuid, @uuid, e, :verbose => @debug)
      }
      FileUtils.chown(nil, @uuid, gearappdir, :verbose => @debug)
      raise "Failed to instantiate gear: missing application directory (#{gearappdir})" unless File.exist?(gearappdir)

      state_file = File.join(gearappdir, "runtime", ".state")
      File.open(state_file, File::WRONLY|File::TRUNC|File::CREAT, 0o0660) {|file|
        file.write "new\n"
      }
      FileUtils.chown(@uuid, @uuid, state_file, :verbose => @debug)

      token = "#{@uuid}_#{@namespace}_#{@container_name}"
      path = File.join(basedir, ".httpd.d", token)

      # path can only exist as a turd from failed app destroy
      FileUtils.rm_rf(path) if File.exist?(path)
      FileUtils.mkdir_p(path)

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
  end
end
