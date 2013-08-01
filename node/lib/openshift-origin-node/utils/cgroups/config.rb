require 'openshift-origin-common/config'

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        # Subclass OpenShift::Config so we can split the values easily
        class Config < ::OpenShift::Config
          RESOURCE_LIMITS_FILE = PathUtils.join(CONF_DIR, 'resource_limits.conf')
          def initialize(conf_path = RESOURCE_LIMITS_FILE, defaults = {})
            super
          end

          def get(key)
            super(key.gsub('.','_'))
          end
        end
      end
    end
  end
end
