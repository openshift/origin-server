require 'openshift-origin-node/utils/shell_exec'
require 'fileutils'
require 'etc'

$OPENSHIFT_RUNTIME_UTILS_CGROUPS_MUTEX = Mutex.new

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        # Subclass OpenShift::Config so we can split the values easily
        class Config < ::OpenShift::Config
          def get(key)
            super(key.gsub('.','_'))
          end
        end

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

            # Coerce all values into integers if we can
            merge!(Hash[map{|k,v| [k, (Integer(v) rescue v)] }])
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
                h[k] = @@CGROUPS_CONFIG.get(k)
              end
              p[:frozen]  = Template.new({'freezer.state' => "FROZEN"})
              p[:thawed]  = Template.new({'freezer.state' => "THAWED"})
            end
          )
        end

        @@LOCKFILE='/var/lock/oo-cgroups'

        @@CGCONFIG="/etc/cgconfig.conf"
        @@CGRULES="/etc/cgrules.conf"

        @@DEFAULT_CGROUP_ROOT='/openshift'
        @@DEFAULT_CGROUP_SUBSYSTEMS="cpu,cpuacct,memory,net_cls,freezer"
        @@DEFAULT_CGROUP_CONTROLLER_VARS="cpu.cfs_period_us,cpu.cfs_quota_us,cpu.rt_period_us,cpu.rt_runtime_us,cpu.shares,memory.limit_in_bytes,memory.memsw.limit_in_bytes,memory.soft_limit_in_bytes,memory.swappiness"

        @@CGROUPS_CONFIG = ::OpenShift::Runtime::Utils::Cgroups::Config.new('/etc/openshift/resource_limits.conf')

        @@allowed_vars_cache = []

        class Attrs
          @@DEFAULT_CGROUP_ROOT='/openshift'
          @@RET_NO_USER = 82
          @@RET_NO_VARIABLE = 96
          @@RET_NO_CONTROLLER = 255

          attr_reader :uuid

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
            keys = Cgroups::templates[:default].keys
            fetch(keys)
          end

          def usage
            fetch(%w(cpuacct.usage cpu.stat))
          end

          # Fetch the values from the current cgroup
          #   - If args is a single value, it will return the value
          #   - If args is an array, it will return a Template of values
          def fetch(*args)
            # Join all keys into a string for use in cgget
            keys = [*args].flatten
            key = keys.flatten.map{|x| "-r #{x}" }.join(' ')
            out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgget -n #{key} #{@cgpath}")
            case rc
            when 0
              # Create a new template of the values so we can format them properly
              t = Template.new(parse_cgget(out))
              if (v = t.values).length > 1
                t
              else
                v.first
              end
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

          def store(*args)
            # TODO: If we're able to use multiple values for cgset, this will work
            #vals = Hash[*args].map{|k,v| "-r %s" % [k,v].join('=') }
            vals = Hash[*args]
            cur = vals.map do |key,value|
              out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("cgset -r #{key}=#{value} #{@cgpath}")
              case rc
              when 0
                [key, value]
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
            Hash[cur]
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

          def freeze
            apply_profile(:frozen)
          end

          def thaw
            apply_profile(:thawed)
          end

          def apply_profile(type)
            store(Cgroups::templates[type])
          end

          def profile
            cur = current_values
            # Search through known templates and compare them with our current values
            (Cgroups::templates.find{|k,v| v == cur} || [:unknown]).first
          end

          def boosted?
            profile == :boosted
          end

          # TODO: Is it possible to get this into profile
          def frozen?
            fetch("freezer.state") == "FROZEN"
          end

          def thawed?
            fetch("freezer.state") == "THAWED"
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

          # TODO: This can use @@CGROUPS_CONFIG
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
            Attrs.new(uuid).freeze
          rescue ArgumentError
          end
        end

        def self.thaw(uuid)
          begin
            Attrs.new(uuid).thaw
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
