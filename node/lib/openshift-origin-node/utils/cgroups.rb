require 'openshift-origin-node/utils/shell_exec'
require 'fileutils'
require 'etc'

$OPENSHIFT_RUNTIME_UTILS_CGROUPS_MUTEX = Mutex.new

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        # Create our own hash class so we can implement comparable and change initialize
        class Template < Hash
          include Comparable

          # Allow us to pass in default values and a block
          #  - If a block is passed, it's used to create unknown values
          #  - If vals are passed, they're used to populate the Template
          #    - If the value is another Template, it copies the keys
          #    - If the value is an array, it uses those as the keys
          #    - If the value is a hash, use those values
          def initialize(*vals, &block)
            super(&block)

            case (x = vals.first)
            when Template
              values_at(*(x.keys))
            when Array
              values_at(*x)
            when Hash
              merge!(hash_to_cgroups(x))
            end
          end

          # Compare the values of a template
          # NOTE: It will be considered greater if *any* values are greater
          #       Or else it will then be considered less if *any* values are less
          #       Or else, it will be considered equal
          def <=>(obj)
            vals = each_pair.map do |k,v|
              v <=> obj[k]
            end
            # Find the most significant match
            [1,-1,0].find{|x| vals.include?(x) }
          end

          protected
          # Combine a hash of hashes by combining the keys using the separator
          #  - Separator may be a string or Array
          #   - A string will be used for all levels
          #   - An array will be used in the order its given, when exhausted it will use the last value
          def combine(hash, sep = '.')
            sep = [*sep]
            cur_sep = sep.shift || '.'
            sep = [cur_sep] if sep.empty?

            hash.inject({}) do |h,(k1,v)|
              v = v.is_a?(Hash) ? combine(v,sep): {nil => [*v]}
              v.inject(h) do |h,(k2,val)|
                key = [k1,k2].compact.join(cur_sep)
                if val.is_a?(Array) && val.length == 1
                  val = val.first
                end
                h[key] = val
                h
              end
            end
          end

          # Flatten our hash keys into the correct format
          def hash_to_cgroups(hash)
            combine(hash,['.','_'])
          end
        end

        @@BOOST_VALUES = {
          cpu: {
            shares: 512,
            cfs: {
              quota_us:  50000,
            }
          }
        }

        def self.templates
          @@TEMPLATES ||= (
            {}.tap do |p|
              p[:boosted] = Template.new(@@BOOST_VALUES)
              p[:default] = Template.new(p[:boosted]) do |h,k|
                key = k.gsub('.','_')
                h[k] = OpenShift::Config.new('/etc/openshift/resource_limits.conf').get(key).to_i
              end
            end
          )
        end

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

          # Get the current values for any keys specified in the default template
          def current_values
            Template.new(Cgroups::templates[:default]) do |h,k|
              h[k] = fetch(k).to_i
              h
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

          def boost
            apply_profile(:boosted)
          end

          def restore
            apply_profile(:default)
          end

          def apply_profile(type)
            set_cgroups_values(Cgroups::templates[type])
          end

          # This will loop over all values
          def set_cgroups_values(values)
            values.each do |key,val|
              store(key,val)
            end
          end

          def profile
            cur = current_values
            # Search through known templates and compare them with our current values
            (Cgroups::templates.find{|k,v| v == cur} || [:unknown]).first
          end

          def boosted?
            profile == :boosted
          end
        end

        def self.with_no_cpu_limits(uuid)
          r = nil
          attrs = Attrs.new(uuid)
          begin
            attrs.boost
            if block_given?
              r = yield
            end
          ensure
            attrs.restore
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
