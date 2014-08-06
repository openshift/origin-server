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
require 'openshift-origin-node/utils/selinux_context'
require 'openshift-origin-node/utils/node_logger'
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
          @@cgroup_root_cache = nil
          @@cgroup_mounts_cache = nil
          @@cgroup_paths_cache = nil

          def initialize(uuid)
            raise ArgumentError, "Invalid uuid" if uuid.to_s == ""

            @uuid = uuid

            @cgroup_root = self.class.cgroup_root
            @cgroup_path = "#{@cgroup_root}/#{@uuid}"
            @config      = OpenShift::Config.new
            @wrap_around_uid = (@config.get("WRAPAROUND_UID") || 65536).to_i
          end

          def self.cgroup_root
            if not @@cgroup_root_cache
              @@cgroup_root_cache = (OpenShift::Config.new.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
            end
            @@cgroup_root_cache
          end

          def self.subsystems
            if not @@subsystems_cache
              @@subsystems_cache = (OpenShift::Config.new.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS).strip.split(',').freeze
            end
            @@subsystems_cache
          end

          def subsystems
            self.class.subsystems
          end

          def self.cgroup_mounts
            if not @@cgroup_mounts_cache
              @@cgroup_mounts_cache = {}
              File.open("/proc/mounts") do |mounts|
                mounts.each do |mntpt|
                  fs_spec, fs_file, fs_vtype, fs_mntops, fs_freq, fs_passno = mntpt.split
                  fs_mntops = fs_mntops.split(',')
                  if fs_vtype == "cgroup"
                    subsystems.each do |subsys|
                      @@cgroup_mounts_cache[subsys]=fs_file if fs_mntops.include?(subsys)
                    end
                  end
                end
              end
              @@cgroup_mounts_cache.freeze
            end
            @@cgroup_mounts_cache
          end

          def self.cgroup_paths
            if not @@cgroup_paths_cache
              @@cgroup_paths_cache = {}
              cgroup_mounts.each do |subsys, mntpt|
                p = File.join(mntpt, cgroup_root)
                Dir.mkdir(p, 0755) unless File.exist?(p)
                @@cgroup_paths_cache[subsys]=p
              end
              @@cgroup_paths_cache.freeze
            end
            @@cgroup_paths_cache
          end

          def cgroup_paths
            Hash[ *(self.class.cgroup_paths.map { |subsys, path| [ subsys, File.join(path, @uuid) ] }.flatten ) ]
          end

          # Public: List the available parameters for the implementation
          #         and their default values.
          #
          # Note: This will only list parameters that have a specific
          #       controller associated with them and will not list
          #       general cgroups parameters.
          def self.parameters
            if not @@parameters_cache
              @@parameters_cache = {}
              cgroup_paths.each do |subsys, path|
                Dir.entries(path).select { |p|
                  p.start_with?("#{subsys}.")
                }.sort { |a,b|
                  a.count('.') <=> b.count('.')   # "memory.foo" must be set before "memory.memsw.foo"
                }.each do |p|
                  begin
                    @@parameters_cache[p]=parse_cgparam(File.read(File.join(path, p)))
                  rescue
                  end
                end
              end
              @@parameters_cache.freeze
            end
            @@parameters_cache
          end

          def parameters
            self.class.parameters
          end

          def uid
            @uid_cache ||= Etc.getpwnam(@uuid).uid
          end

          # TODO: These could potentially be replaced by cgsnapshot if we can determine if its fast enough
          # (str, err, rc = ::OpenShift::Runtime::Utils::oo_spawn('cgsnapshot 2> /dev/null')
          # keys = %w(cpu.cfs_period_us cpu.cfs_quota_us cpuacct.usage)
          # Hash[str.scan(/^group\sopenshift\/(.*?)\s(.*?)^}/m).map{|mg| [mg[0], Hash[mg[1].scan(/\s*(#{keys.join('|')})\s*=\s*"(.*)";/).map{|k,v| [k,v.to_i]}]] }]
          def self.usage
            # Retrieve cgroup counters: cpu.stat, cpuacct.usage, cpu.cfs_quota_us
            expression     = '/cgroup/*/openshift/*/cpu*'
            cmd            = %Q(set -e -o pipefail; grep -H ^ #{expression} |sed 's|^/cgroup/[^/]*/openshift/||')
            (out, err, rc) = ::OpenShift::Runtime::Utils::oo_spawn(cmd, :quiet => true)
            if 1 < rc
              (count, _, _) = ::OpenShift::Runtime::Utils::oo_spawn(%Q(ls #{expression} |wc -l), :quiet => true)
              unless count.chomp == '0'
                NodeLogger.logger.error %Q(Failed to read cgroups counters from #{expression}: #{err} (#{rc}))
              end
            end
            parse_usage(out, Time.now.to_f)
          end

          def self.parse_usage(info, ts)
            info.lines.to_a.inject(Hash.new{|h,k| h[k] = { 'ts' => ts }} ) do |h,line|
              (uuid, key, val) = line.split(/\W/).values_at(0,-2,-1)
              h[uuid][key] = val.to_i
              h
            end
          end

          # Public: Create a cgroup namespace for the gear
          def create(defaults={})
            newcfg = Hash["perm", {}, *(subsystems.map { |s| [s,{}] }.flatten)]
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

            # Parameter order matters and its implicitly defined in
            # parameters
            parameters.each_key do |k|
              v = defaults[k]
              if v
                subsys = k.split('.')[0]
                if subsystems.include?(subsys)
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
            keys = [*args].flatten.flatten
            vals = {}

            # Parameter order matters and is implicitly defined in the
            # parameters variable.
            parameters.select { |k,v| keys.include?(k) }.each do |param, defval|
              path = cgroup_paths[param.split('.')[0]]
              raise RuntimeError, "User does not exist in cgroups: #{@uuid}" unless (path and File.exist?(path))
              begin
                val = File.read(File.join(path, param))
                vals[param] = parse_cgparam(val)
              rescue Errno::ENOENT
                raise KeyError, "Cgroups parameter not found: #{param}"
              end
            end
            vals
          end

          def store(*args)
            vals = Hash[*args]

            # Parameter order matters and is implicitly defined in the
            # parameters variable.
            parameters.map { |k, v| [k, vals[k]] }.select { |ent| ent[1] }.each do |param, val|
              path = cgroup_paths[param.split('.')[0]]
              raise RuntimeError, "User does not exist in cgroups: #{@uuid}" unless (path and File.exist?(path))
              begin
                File.open(File.join(path, param), File::WRONLY | File::SYNC) do |t|
                  t.syswrite("#{val}\n")
                end
              rescue Errno::ENOENT
                raise KeyError, "Cgroups controller or parameter not found for: #{param}"
              rescue Errno::EINVAL, Errno::EIO
                raise KeyError, "Cgroups parameter cannot be set to value: #{param} = #{val}"
              end
            end
            vals
          end

          # Public: Distribute this user's processes into their cgroup
          def classify_processes
            errors = {}

            threads = []
            threads_foreach do |tid, pid, name, puid, pgid|
              if puid == uid
                threads << tid
              end
            end

            cgroup_paths.each do |subsys, path|
              begin
                File.open(File.join(path, "tasks"), File::WRONLY | File::SYNC) do |t|
                  threads.each do |pid|
                    begin
                      t.syswrite "#{pid}\n"
                    rescue Errno::ESRCH       # The thread went away or is a zombie
                    rescue Errno::ENOMEM => e # Cannot allocate memory (cgroup is full)
                      errors[pid]="The cgroup is full"
                      NodeLogger.logger.error("Error classifying #{@uuid} #{pid}: The cgroup is full")
                    rescue => e
                      errors[pid]=e.message
                      NodeLogger.logger.error("Error classifying #{@uuid} #{pid}: #{e.message}")
                    end
                  end
                end
              rescue Errno::ENOENT
              end
            end
            errors
          end

          # Public: List processes in a cgroup regardless of what UID owns them
          def processes
            pids = []
            cgroup_paths.each do |subsys, path|
              begin
                pids << File.read(File.join(path, "tasks")).split.map { |pid| pid.to_i }
              rescue Errno::ENOENT
              end
            end
            pids.flatten.uniq
          end


          protected

          # Compute the network class id
          # Major = 1
          # Minor = UID
          # Caveat: 0 <= Minor
          def net_cls
            major = 1
            if (uid < 1)
              raise RuntimeError, "Cannot assign network class id for: #{uid}"
            end
            (major << 16) + (uid % @wrap_around_uid)
          end


          # Private: Parse the contents of a cgroups entry
          def self.parse_cgparam(val)
            pval = val.split(/\n/).map { |v| [*v.split] }
            if pval.flatten.length == 1
              pval.flatten.first
            elsif pval.flatten.first.length == 1
              pval.flatten
            else
              Hash[*(pval.map { |l| [l.shift, l.join(' ')] }.flatten)]
            end
          end

          def parse_cgparam(*args)
            self.class.parse_cgparam(*args)
          end

          # Private: Call the low level cgroups creation
          def cgcreate
            cgroup_paths.each do |subsys, path|
              Dir.mkdir(path, 0755) unless File.exist?(path)
              File.chown(uid, uid, File.join(path, "tasks"))
            end
          end

          # Private: List of threads on the system
          def threads_foreach
            processes_foreach do |pid, name, uid, gid|
              begin
                Dir.foreach("/proc/#{pid}/task") do |tid|
                  if not tid.start_with?('.')
                    yield(tid, pid, name, uid, gid)
                  end
                end
              rescue
              end
            end
          end

          # Private: List of processes on the system
          def processes_foreach
            Dir.foreach('/proc') do |procent|
              begin
                pid = procent.to_i
                uid = 0
                gid = 0
                name = ""

                File.open(File.join('/proc', procent, "status")) do |f|
                  f.each do |l|
                    token, values = l.split(':')
                    case token
                    when 'Name'
                      name = values.strip
                    when 'Uid'
                      uid = values.strip.split[0].to_i
                    when 'Gid'
                      gid = values.strip.split[0].to_i
                    end
                  end
                end
                yield(pid, name, uid, gid)
              rescue
              end
            end
          end

          # Private: Call the low level cgroups deletion
          def cgdelete
            force_stop = false
            cgroup_paths.each do |subsys, path|
              while File.exist?(path)
                begin
                  Dir.rmdir(path)
                rescue Errno::EBUSY
                  File.open(File.join(path, "..", "tasks"), File::WRONLY | File::SYNC) do |t|
                    File.read(File.join(path, "tasks")).split.each do |pid|
                      begin
                        t.syswrite("#{pid}\n")
                      rescue Errno::ESRCH => e
                        $stderr.puts "ERROR: #{e.message} zombie or non-existing pid #{pid}"
                        force_stop = true
                        break
                      end
                    end
                  end
                  retry unless force_stop
                end
              end
            end
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
                f_out.puts("#{@uuid}\t#{subsystems.join(',')}\t#{@cgroup_path}")
              end
            end
            processes_foreach { |pid, name| Process.kill("USR2", pid) if name == "cgrulesengd" }
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
            SelinuxContext.instance.chcon(filename)

            r
          end
        end
      end
    end
  end
end
