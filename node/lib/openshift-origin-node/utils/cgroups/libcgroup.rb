#--
# Copyright 2013 Red Hat, Inc.
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

require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/selinux'
require 'fileutils'
require 'etc'

$OPENSHIFT_RUNTIME_UTILS_CGROUPS_LIBCGROUP_MUTEX = Mutex.new

module OpenShift
  module Runtime
    module Utils
      class Cgroups

        class Libcgroup

          @@DEFAULT_CGROUP_ROOT='/openshift'
          @@DEFAULT_CGROUP_SUBSYSTEMS='cpu,cpuacct,memory,net_cls,freezer'

          @@MUTEX = $OPENSHIFT_RUNTIME_UTILS_CGROUPS_LIBCGROUP_MUTEX

          @@LOCKFILE = '/var/lock/oo-cgroups'

          @@CGCONFIG = "/etc/cgconfig.conf"
          @@CGRULES = "/etc/cgrules.conf"

          @@subsystems_cache = nil
          @@parameters_cache = nil

          attr_reader :subsystems, :parameters

          def initialize(uuid)
            raise ArgumentError, "Invalid uuid" if uuid.to_s == ""

            @uuid = uuid

            @config = OpenShift::Config.new
            @cgroup_root = self.class.cgroup_root
            @cgroup_path = "#{@cgroup_root}/#{@uuid}"

            if not @@subsystems_cache
              @@subsystems_cache = (@config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS).strip.split(',').freeze
            end
            @subsystems = @@subsystems_cache

            if not @@parameters_cache
              subsys = @subsystems.map { |subsys| "-g #{subsys}" }.join(' ')
              out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -n #{subsys} #{@cgroup_root}", :chdir=>"/")
              if rc != 0
                raise RuntimeError, "Could not determine Cgroup parameters"
              end
              @@parameters_cache = parse_cgget(out).freeze
            end
            @parameters = @@parameters_cache

          end

          def self.cgroup_root
            OpenShift::Config.new.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT
          end

          def self.cgroup_mount
            cmd = "cat /proc/mounts | grep cgroup | awk '{print $2}'"
            ::OpenShift::Runtime::Utils::oo_spawn(cmd).first.strip
          end

          def self.cgroup_path
            File.join(cgroup_mount, cgroup_root)
          end

          # Public: Create a cgroup namespace for the gear
          def create(defaults={})
            uid = Etc.getpwnam(@uuid).uid  

            newcfg = Hash["perm", {}, *@subsystems.map { |s| [s,{}] }.flatten]
            to_store = Hash.new

            newcfg["perm"] = {
              "task" => {   # These must be numeric to avoid confusion in libcgroup.
                "uid" => uid,
                "gid" => uid,
              },
              "admin" => {  # These must be "root", as "0" confuses libcgroup.
                "uid" => "root",
                "gid" => "root",
              }
            }

            newcfg["net_cls"]["net_cls.classid"] = net_cls
            to_store["net_cls.classid"] = newcfg["net_cls"]["net_cls.classid"]

            defaults.each do |k,v|
              if @parameters.include?(k)
                subsys = k.split('.')[0]
                if @subsystems.include?(subsys)
                  newcfg[subsys][k]=v
                  to_store[k]=v
                end
              end
            end

            with_cgroups_lock do
              cgcreate
              update_cgconfig(newcfg)
              update_cgrules(true)
            end

            store(to_store)
            classify_processes
          end

          # Public: Delete a cgroup namespace for the gear
          def delete
            with_cgroups_lock do
              update_cgconfig(nil)
              update_cgrules(false)
              cgdelete
            end
          end


          # Public: Return true if a cgroup exists for this uuid
          def exists?
            begin
              fetch
            rescue ArgumentError
              return false
            end
            true
          end

          # Public: Fetch parameters for a specific uuid, or a hash
          # of key=>value for all parametetrs for the gear.
          def fetch(*args)
            keys = [*args].flatten
            key = keys.flatten.map{|x| "-r #{x}" }.join(' ')
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -n #{key} #{@cgroup_path}", :chdir=>"/")
            case rc
            when 0
              parse_cgget(out)
            when 82
              raise RuntimeError, "User does not exist in cgroups: #{@uuid}"
            when 96
              raise KeyError, "Cgroups parameter not found: #{key}"
            else
              raise RuntimeError, "Cgroups error: #{err}"
            end
          end

          def store(*args)
            vals = Hash[*args]
            oldvals = {}
            cur = {}
            rc = 0

            # Parameter ordermatters.  Keep retrying as long as some
            # sets are successful, the proper order will eventually
            # work its way through.
            while oldvals != vals
              oldvals = vals.clone
              vals.each do |key,value|
                out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgset -r #{key}=#{value} #{@cgroup_path}", :chdir=>"/")
                if rc == 0
                  cur[key]=value
                  vals.delete(key)
                end
              end
            end

            case rc
            when 0
            when 95
              raise RuntimeError, "User or parameter does not exist in cgroups: #{@uuid} #{key}"
            when 96
              raise KeyError, "Cgroups parameter cannot be set to value: #{key} = #{value}"
            when 84
              raise KeyError, "Cgroups controller not found for: #{key}"
            else
              raise RuntimeError, "Cgroups error: #{err}"
            end
            cur
          end

          # Public: Distribute this user's processes into their cgroup
          def classify_processes
            uid = Etc.getpwnam(@uuid).uid

            pids=[]
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ps -u #{uid} -o pid,cgroup --no-headers", :chdir=>"/")
            out.each_line do |proc|
              pid, cgroup = proc.strip.split
              cg_path = cgroup.split(':')[1]
              if cg_path != "#{@cgroup_path}"
                pids << pid
              end
            end

            subsys = @subsystems.join(',')
            while not pids.empty?
              pidout = pids.shift(25).join(' ')
              out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgclassify -g #{subsys}:#{@cgroup_path} #{pidout}", :chdir=>"/")
            end

          end

          # Public: List processes in a cgroup regardless of what UID owns them
          def processes
            pids = []

            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ps -o pid,cgroup --no-headers", :chdir=>"/")
            out.each_line do |proc|
              pid, cgroup = proc.strip.split
              if cgroup.end_with?(":#{@cgroup_path}")
                pids << pid.to_i
              end
            end
            pids
          end


          protected

          # Compute the network class id
          # Major = 1
          # Minor = UID
          # Caveat: 0 <= Minor <= 0xFFFF (65535)
          def net_cls
            uid = Etc.getpwnam(@uuid).uid

            major = 1
            if (uid.to_i < 1) or (uid.to_i > 0xFFFF)
              raise RuntimeError, "Cannot assign network class id for: #{uid}"
            end
            (major << 16) + uid.to_i
          end

          # Private: Parse the output of cgget
          def parse_cgget(str)
            h = {}
            str.lines.each do |line|
              parts = line.split(/:/)
              if parts.length > 1
                @key = parts.first.strip
                h[@key] = parts.last.strip
              else
                unless (v = h[@key]).is_a?(Hash)
                  h[@key] = Hash[[v.split]]
                end
                (k,v) = line.split
                h[@key][k] = v
              end
            end
            h
          end


          # Private: Call the low level cgroups creation
          def cgcreate
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgcreate -t #{@uuid}:#{@uuid} -g #{@subsystems.join(',')}:#{@cgroup_path}", :chdir=>"/")
            case rc
            when 0
              return nil
            else
              raise RuntimeError, "Cgroups error: #{err}"
            end
          end

          # Private: Call the low level cgroups deletion
          def cgdelete
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgdelete #{@subsystems.join(',')}:#{@cgroup_path}", :chdir=>"/")
            nil
          end

          # Private: Update the cgrules.conf file.  This removes the
          # requested uuid and re-adds it at the end if a new path
          # is provided.
          def update_cgrules(recreate=true)
            overwrite_with_safe_swap(@@CGRULES) do |f_in, f_out|
              f_in.each do |l|
                if not l=~/^#{@uuid}\s/
                  f_out.puts(l)
                end
              end
              if recreate
                f_out.puts("#{@uuid}\t#{@subsystems.join(',')}\t#{@cgroup_path}")
              end
            end
            ::OpenShift::Runtime::Utils::oo_spawn("pkill -USR2 cgrulesengd", :chdir=>"/")
          end

          # Private: Update the cgconfig.conf file.  This removes
          # the requested path and re-adds it at the end if a new
          # configuration is provided.
          def update_cgconfig(newconfig=nil)
            overwrite_with_safe_swap(@@CGCONFIG) do |f_in, f_out|
              f_in.each do |l|
                if not l=~/^group #{@cgroup_path}\s/
                  f_out.puts(l)
                end
              end
              if newconfig
                f_out.write("group #{@cgroup_path} ")
                f_out.write(gen_cgconfig(newconfig))
                f_out.write("\n")
              end
            end
          end

          # Private: Generate configuration stanzas for
          # cgconfig.conf from a hash.
          def gen_cgconfig(data)
            rbuf = ""
            if data.respond_to? :each_pair
              rbuf << "{"
              data.each_pair do |k,v|
                rbuf << " #{k} "
                rbuf << gen_cgconfig(v)
              end
              rbuf << "}"
            else
              rbuf << "= #{data}; "
            end
            rbuf
          end

          # Private: Serialize for editing the cgroups config files
          def with_cgroups_lock
            r = nil
            @@MUTEX.synchronize do
              File.open(@@LOCKFILE, File::RDWR|File::CREAT|File::TRUNC|File::SYNC, 0o0600) do |lockfile|
                lockfile.sync=true
                lockfile.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
                lockfile.flock(File::LOCK_EX)
                lockfile.write("#{Process::pid}\n")
                begin
                  if block_given?
                    r = yield
                  end
                ensure
                  lockfile.flock(File::LOCK_UN)
                end
              end
            end
            r
          end


          # Private: Open and safely swap the file if it changed
          def overwrite_with_safe_swap(filename)
            r=nil

            begin
              f_in=File.open(filename, File::RDONLY)
            rescue Errno::ENOENT
              f_in=File.open('/dev/null', File::RDONLY)
            end

            begin
              File.open(filename+"-", File::RDWR|File::CREAT|File::TRUNC, 0o0644) do |f_out|
                if block_given?
                  r=yield(f_in, f_out)
                end
                f_out.fsync()
              end
            ensure
              f_in.close
            end

            FileUtils.mv(filename+"-", filename, :force => true)
            SELinux::chcon(filename)

            r
          end


        end
      end
    end
  end
end
