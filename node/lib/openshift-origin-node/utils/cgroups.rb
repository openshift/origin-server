require 'openshift-origin-node/utils/shell_exec'
require 'fileutils'
require 'etc'

$OPENSHIFT_RUNTIME_UTILS_CGROUPS_MUTEX = Mutex.new

module OpenShift
  module Runtime
    module Utils
      class Cgroups

        @@LOCKFILE='/var/lock/oo-cgroups'

        @@CGCONFIG="/etc/cgconfig.conf"
        @@CGRULES="/etc/cgrules.conf"

        @@DEFAULT_CGROUP_ROOT='/openshift'
        @@DEFAULT_CGROUP_SUBSYSTEMS="cpu,cpuacct,memory,net_cls,freezer"
        @@DEFAULT_CGROUP_CONTROLLER_VARS="cpu.cfs_period_us,cpu.cfs_quota_us,cpu.rt_period_us,cpu.rt_runtime_us,cpu.shares,memory.limit_in_bytes,memory.memsw.limit_in_bytes,memory.soft_limit_in_bytes,memory.swappiness"

        @@allowed_vars_cache = []

        class Attrs
          @@DEFAULT_CGROUP_ROOT='/openshift'
          @@RET_NO_USER = 82
          @@RET_NO_VARIABLE = 96
          @@RET_NO_CONTROLLER = 255

          def initialize(uuid)
            @uuid = uuid

            root = (OpenShift::Config.new.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
            @cgpath = "#{root}/#{uuid}"

            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -a #{@cgpath} >/dev/null")
            if rc != 0
              raise ArgumentError, "User does not exist in cgroups: #{@uuid}"
            end
          end

          def fetch(key)
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -n -v -r #{key} #{@cgpath}")
            case rc
            when 0
              return out.strip
            when @@RET_NO_USER
              raise RuntimeError, "User no longer exists in cgroups: #{@uuid}"
            when @@RET_NO_VARIABLE
              raise KeyError, "Cgroups parameter not found: #{key}"
            when @@RET_NO_CONTROLLER
              raise KeyError, "Cgroups controller not found for: #{key}"
            else
              raise RuntimeError, "Cgroups error: #{err}"
            end
          end

          def store(key, value)
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgset -r #{key}=#{value} #{@cgpath}")
            case rc
            when 0
              return value
            when @@RET_NO_USER
              raise RuntimeError, "User no longer exists in cgroups: #{@uuid}"
            when @@RET_NO_VARIABLE
              raise KeyError, "Cgroups parameter missing or cannot be set to value: #{key} = #{value}"
            when @@RET_NO_CONTROLLER
              raise KeyError, "Cgroups controller not found for: #{key}"
            else
              raise RuntimeError, "Cgroups error: #{err}"
            end
          end

          def [](key)
            fetch(key)
          end

          def []=(key, value)
            store(key, value)
          end

        end

        def self.with_no_cpu_limits(uuid)
          r = nil
          param = "cpu.cfs_quota_us"
          attrs = Attrs.new(uuid)
          full_cpu = attrs["cpu.cfs_period_us"]
          oldlimit = attrs[param]
          begin
            attrs[param]=full_cpu
            if block_given?
              r = yield
            end
          ensure
            attrs[param]=oldlimit
          end
          r
        end

        def self.enable(uuid, uid=nil)
          config = OpenShift::Config.new
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)
          controller_vars = ((config.get("OPENSHIFT_CGROUP_CONTROLLER_VARS") or @@DEFAULT_CGROUP_CONTROLLER_VARS)).split(',')

          path = "#{root}/#{uuid}"

          if @@allowed_vars_cache.empty?
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -a /")
            if rc == 0
              out.each_line do |l|
                if l =~ /^([a-zA-Z0-9\-\_\.]+):/
                  @@allowed_vars_cache << $~[1]
                end
              end
            end
          end

          controller_vars.delete_if { |var| not @@allowed_vars_cache.include?(var) }

          if uid.nil?
            uid = Etc.getpwnam(uuid).uid
          end

          newcfg = Hash.new {|h,k| h[k]={}}
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

          newcfg["net_cls"] = {
            "net_cls.classid" => net_cls(uid)
          }

          resource = OpenShift::Config.new('/etc/openshift/resource_limits.conf')
          controller_vars.each do |cv|
            subsys = cv.split('.')[0]
            var = cv.gsub('.','_')
            res = resource.get(var)
            if not res.nil?
              newcfg[subsys][cv]=res
            end
          end

          with_cgroups_lock do
            update_cgconfig(path, newcfg)
            update_cgrules(uuid, subsystems, path)
            cgcreate(uuid)
            reload_cgred
          end

          attrs = Attrs.new(uuid)
          newcfg.select { |k,v| k!="perm" }.map { |k,v| v.each {|cv,res| attrs[cv]=res }}

          classify_procs(uuid, uid)
        end

        def self.enable_all
          config = OpenShift::Config.new
          gecos = (config.get("GEAR_GECOS") or "OO guest")

          pwents=[]
          Etc.passwd do |pwent|
            if pwent.gecos == gecos
              pwents << pwent
            end
          end

          pwents.each do |pwent|
            enable(pwent.name, pwent.uid)
          end
        end

        def self.disable(uuid)
          config = OpenShift::Config.new
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          path = "#{root}/#{uuid}"

          with_cgroups_lock do
            update_cgconfig(path)
            update_cgrules(uuid)
            reload_cgred
          end
          cgdelete(uuid)
        end

        def self.disable_all
          config = OpenShift::Config.new
          gecos = (config.get("GEAR_GECOS") or "OO guest")

          pwents=[]
          Etc.passwd do |pwent|
            if pwent.gecos == gecos
              pwents << pwent
            end
          end

          pwents.each do |pwent|
            disable(pwent.name)
          end
        end

        def self.freeze(uuid)
          begin
            attrs = Attrs.new(uuid)
            attrs['freezer.state']='FROZEN'
          rescue ArgumentError
          end
        end

        def self.thaw(uuid)
          begin
            attrs = Attrs.new(uuid)
            attrs['freezer.state']='THAWED'
          rescue ArgumentError
          end
        end

        # Public: Kill processes in a cgroup leaving the cgroup frozen at the end.
        def self.freezer_burn(uuid, uid=nil)
          config = OpenShift::Config.new
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          path = "#{root}/#{uuid}"

          if not uid
            uid = Etc.getpwnam(uuid).uid
          end

          begin
            attrs = Attrs.new(uuid)
            attrs['freezer.state']='FROZEN'

            20.times do
              pids = []
              out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ps -u 0,#{uid} -o pid,cgroup --no-headers")
              out.each_line do |proc|
                pid, cgroup = proc.strip.split
                cg_path = cgroup.split(':')[1]
                if cg_path == "#{path}"
                  pids << pid.to_i
                end
              end

              if pids.empty?
                return
              else
                Process::Kill("KILL",*pids)
                attrs['freezer.state']='THAWED'
                sleep(0.05)
                attrs['freezer.state']='FROZEN'
              end

            end
          rescue ArgumentError
          end

          raise RuntimeError, "Cannot kill processes for cgroups for: #{uuid}"
        end

        # Public: Distribute this user's processes into their cgroup
        def self.classify_procs(uuid, uid=nil)
          config = OpenShift::Config.new
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          path = "#{root}/#{uuid}"

          if not uid
            uid = Etc.getpwnam(uuid).uid
          end

          pids=[]
          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ps -u #{uid} -o pid,cgroup --no-headers")
          out.each_line do |proc|
            pid, cgroup = proc.strip.split
            cg_path = cgroup.split(':')[1]
            if cg_path != "#{path}"
              pids << pid
            end
          end

          while not pids.empty?
            pidout = pids.shift(25).join(' ')
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgclassify -g #{subsystems}:#{path} #{pidout}")
          end
        end

        # Public: Distribute all processes into their appropriate cgroups
        #
        # Note: There could be thousands of users and thousands of
        #       processes.  This function is designed for minimal
        #       passes through each list at the cost of memory.
        #
        def self.classify_all_procs
          config = OpenShift::Config.new
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          gecos = (config.get("GEAR_GECOS") or "OO guest")

          users = {}
          Etc.passwd do |pwent|
            if pwent.gecos == gecos
              users[pwent.uid.to_s]="#{root}/#{pwent.name}"
            end
          end

          cgroups = Hash.new {|h,k| h[k]=[]}
          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ps -e -o uid,pid,cgroup --no-headers")
          out.each_line do |proc|
            uid, pid, cgroup = proc.strip.split
            cg_path = cgroup.split(':')[1]
            if (users[uid] != nil) and (users[uid] != cg_path)
              cgroups[users[uid]] << pid
            end
          end

          cgroups.each do |cg_path, pids|
            while not pids.empty?
              pidout = pids.shift(25).join(' ')
              out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgclassify -g #{subsystems}:#{cg_path} #{pidout}")
            end
          end
        end

        private

        def self.gen_cgconfig(data)
          rbuf = ""
          if data.respond_to? :each_pair
            if not data.empty?
              rbuf << " {"
              data.each_pair do |k,v|
                rbuf << " #{k}"
                rbuf << gen_cgconfig(v)
              end
              rbuf << " }"
            end
          else
            rbuf << " = #{data};"
          end
          rbuf
        end

        def self.update_cgrules(uuid, subsystems=nil, path=nil)
          overwrite_with_safe_swap(@@CGRULES) do |f_in, f_out|
            f_in.each do |l|
              if not l=~/^#{uuid}\s/
                f_out.puts(l)
              end
            end
            if subsystems and path
              f_out.puts("#{uuid}\t#{subsystems}\t#{path}")
            end
          end
        end

        def self.update_cgconfig(path, newconfig=nil)
          overwrite_with_safe_swap(@@CGCONFIG) do |f_in, f_out|
            f_in.each do |l|
              if not l=~/^group #{path}\s/
                f_out.puts(l)
              end
            end
            if newconfig
              f_out.write("group #{path} ")
              f_out.write(gen_cgconfig(newconfig))
              f_out.write("\n")
            end
          end
        end

        # Compute the network class id
        # Major = 1
        # Minor = UID
        # Caveat: 0 <= Minor <= 0xFFFF (65535)
        def self.net_cls(uid)
          major = 1
          if (uid.to_i < 1) or (uid.to_i > 0xFFFF)
            raise RuntimeError, "Cannot assign network class id for: #{uid}"
          end
          (major << 16) + uid.to_i
        end

        def self.cgcreate(uuid)
          config = OpenShift::Config.new
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)

          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgcreate -t #{uuid}:#{uuid} -g #{subsystems}:#{root}/#{uuid}")
          case rc
          when 0
            return nil
          else
            raise RuntimeError, "Cgroups error: #{err}"
          end
        end

        def self.cgdelete(uuid)
          config = OpenShift::Config.new
          root = (config.get("OPENSHIFT_CGROUP_ROOT") or @@DEFAULT_CGROUP_ROOT)
          subsystems = (config.get("OPENSHIFT_CGROUP_SUBSYSTEMS") or @@DEFAULT_CGROUP_SUBSYSTEMS)

          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgdelete #{subsystems}:#{root}/#{uuid}")
          nil
        end

        def self.reload_cgred
          ::OpenShift::Runtime::Utils::oo_spawn("pkill -USR2 cgrulesengd")
        end

        # Private: Serialize for editing the cgroups config files
        def self.with_cgroups_lock
          r = nil
          $OPENSHIFT_RUNTIME_UTILS_CGROUPS_MUTEX.synchronize do
            File.open(@@LOCKFILE, File::RDWR|File::CREAT|File::TRUNC, 0o0600) do |lockfile|
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
        def self.overwrite_with_safe_swap(filename)
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

          begin
            FileUtils.ln(filename, filename+"~", :force => true)
          rescue Errno::ENOENT
          end
          FileUtils.mv(filename+"-", filename, :force => true)
          SELinux::chcon(filename)

          r
        end

      end
    end
  end
end
