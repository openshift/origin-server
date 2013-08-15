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
            val = super(key.gsub('.','_'))
            parse_value(val)
          end

          # Parse values into usable formats
          # This is useful for storing values, such as byte values, in a human readable format
          #
          # NOTE: This function is also copied into the following files and must be updated if this is changed
          #         - plugins/msg-node/mcollective/facts/openshift_facts.rb
          #         - node-util/bin/oo-accept-node b/node-util/bin/oo-accept-node
          def parse_value(val)
            # Convert prefixed byte values to bytes
            factors = { k: 1, m: 2, g: 3, t: 4 }
            val.match(/^(\d+)(#{factors.keys.join('|')})b?/i) do |mg|
              (num,unit) = mg[1,2]
              val = num.to_i * ((2**10)**factors[unit.downcase.to_sym])
            end
            val
          end
        end
      end
    end
  end
end
