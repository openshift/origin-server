require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  module Utils
    class Cgroups

      class Attrs
        @@RET_NO_USER = 82
        @@RET_NO_VARIABLE = 96
        @@RET_NO_CONTROLLER = 255

        def initialize(uuid)
          @uuid = uuid
          @cgpath = "/openshift/#{uuid}"

          out, err, rc = OpenShift::Utils::oo_spawn("cgget -a #{@cgpath} >/dev/null")
          if rc != 0
            raise ValueError, "User does not exist in cgroups: #{@uuid}"
          end
        end

        def fetch(key)
          out, err, rc = OpenShift::Utils::oo_spawn("cgget -n -v -r #{key} #{@cgpath}")
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
          out, err, rc = OpenShift::Utils::oo_spawn("cgset -r #{key}=#{value} #{@cgpath}")
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
        param = "cpu.cfs_quota_us"
        attrs = Attrs.new(uuid)
        full_cpu = attrs["cpu.cfs_period_us"]
        oldlimit = attrs[param]
        begin
          attrs[param]=full_cpu
          yield
        ensure
          attrs[param]=oldlimit
        end
      end

      def self.disable_cgroups(uuid)
        OpenShift::Utils::oo_spawn("oo-admin-ctl-cgroups stopuser #{uuid}",
                                   expected_exitstatus: 0)
      end

      def self.enable_cgroups(uuid)
        OpenShift::Utils::oo_spawn("oo-admin-ctl-cgroups startuser #{uuid}",
                                   expected_exitstatus: 0)
      end
    end
  end
end
