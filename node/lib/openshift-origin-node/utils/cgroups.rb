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
require 'openshift-origin-common/config'

require_relative 'cgroups/libcgroup'

module OpenShift
  module Runtime
    module Utils
      class Cgroups

        class InvalidCgroupSettingException < StandardError
          def initialize(setting=nil, value=nil, msg=nil)
            @setting = setting
            @value = value
            super(msg)
          end

          def to_s
            m = super
            m+= ": Value #{@value} for #{@setting} is invalid in /etc/openshift/resource_limits.conf"
            m
          end
        end

        # Subclass OpenShift::Config so we can split the values easily
        class Config < ::OpenShift::Config
          def initialize(conf_path, default={})
            super
            @tc_outbound_htb = Hash.new {|h, k| h[k] = []}
            tc_outbound_groups.each do |group_name|
              rate = validate_tc_rate(@conf[group_name]["rate"])
              ceil = validate_tc_rate(@conf[group_name]["ceil"])
              port = validate_tc_port(@conf[group_name]["port"])

              k = [rate, ceil]
              @tc_outbound_htb[k] << port
            end
          end

          def validate_tc_rate(rate)
            si_units = "bit|kbit|mbit|gbit|tbit|bps|kbps|mbps|gbps|tbps"
            iec_units = "kibit|mibit|gibit|tibit|kibps|mibps|gibps|tibps"
            unless rate =~ /\d+#{si_units}|#{iec_units}/
              raise InvalidCgroupSettingException.new("rate", rate, "Please see the tc manpage for the supported SI or IEC units")
            end

            return rate
          end

          def validate_tc_port(port)
            if port !~ /\d+/ or port.to_i <= 0 or port.to_i > 65535
              raise InvalidCgroupSettingException.new("port", port, "Outside valid range")
            end

            return port
          end

          def tc_outbound_groups
            @conf.groups.select {|g| g =~ /tc_outbound_limit/}
          end

          def tc_outbound_htb
            # Defaults for backwards compatibility
            # TODO: Remove this logic as soon as Online has the new code and
            # has updated resource_limits.conf.
            if @tc_outbound_htb.keys.empty?
              @tc_outbound_htb = { ["128kbit", "256kbit"] => [587],
                                   ["12kbit", "24kbit"] => [25, 465]
                                 }
            else
              @tc_outbound_htb
            end
          end

          def get(key)
            super(key.gsub('.','_'))
          end
        end


        @@TEMPLATE_SET = {
          :default => [ :default, :default? ],
          :boosted => [ :boost, :boosted? ],
          :throttled => [ :throttle, :throttled?],
          :frozen => [ :freeze, :frozen?],
          :thawed => [ :thaw, :thawed?]
        }

        # Define template set and test methods
        @@TEMPLATE_SET.each do |templ, calls|
          define_method(calls[0]) do |&blk|
            apply_profile(templ, &blk)
          end
          define_method(calls[1]) do
            profile == templ
          end
        end

        def restore(&blk)
          apply_profile(:default, &blk)
        end

        @@templates_cache = nil

        def initialize(uuid)
          # TODO: Make this configurable and move libcgroup impl to a stand-alone plugin gem.
          @impl = ::OpenShift::Runtime::Utils::Cgroups::Libcgroup.new(uuid)
        end

        def create
          @impl.create(templates[:default])
        end

        def delete
          @impl.delete
        end

        def templates
          if not @@templates_cache
            res = Config.new('/etc/openshift/resource_limits.conf')
            @@templates_cache={ :default => {} }

            @@TEMPLATE_SET.each do |templ, calls|
              if templ != :default
                t = param_cfg(res.get_group("cg_template_#{templ}"))
                @@templates_cache[templ] = t
                @@templates_cache[:default].update(Hash[*(t.map { |k,v| [k, @impl.parameters[k]] }.flatten)])
              end
            end
            @@templates_cache[:default].update(param_cfg(res))
            @@templates_cache.freeze
          end
          @@templates_cache
        end

        # Get the current values for any keys specified in the default template
        def current_values
          keys = templates.map { |k,v| v.keys }.flatten.uniq
          fetch(*keys)
        end

        # Public: Fetch the values from the current cgroup
        #   - If args is a single value, it will return the value
        #   - If args is an array, it will return a Template of values
        def fetch(*args)
          t = @impl.fetch(*args)
          if t.length > 1
            t
          else
            t.values.first
          end
        end

        # Public: Store cgroups configuration in the gear
        def store(*args)
          if not args.empty?
            @impl.store(*args)
          end
        end

        # Public: Apply a cgroups template to a gear.  If called with
        #  a block, the default will be restored after the block is
        #  completed and return the value of the block.
        def apply_profile(type, &blk)
          t = templates[type]

          if t == nil
            raise ArgumentError, "Unknown template: #{type}"
          end

          r = store(t)
          if blk
            begin
              r = blk.call(type)
            ensure
              store(templates[:default])
            end
          end
          r
        end

        # Public: Infer the current profile based on current values.
        def profile
          cur = current_values
          tmpls = templates.map { |k,v| [ k, v.length ] }.sort { |a,b| a[1]  <=> b[1] }.map { |ent| ent[0] }

          # Return the most specific match to all the current values or unknown
          prof = :unknown
          tmpls.each do |tmpl|
            cmpvals = cur.select { |k,v| templates[tmpl].keys.include? k }
            if cmpvals == templates[tmpl]
              prof = tmpl
            end
          end
          prof
        end

        # Public: List the process ids which are a member of this gear's cgroup.
        def processes
          @impl.processes
        end

        # Public: Distribute this user's processes into their cgroup
        #
        # Returns: A hash PID => exception for failures.
        def classify_processes
          @impl.classify_processes
        end

        # Public: List the templates available to this gear
        def show_templates
          @@TEMPLATE_SET.keys
        end

        # Public: List the templates available in the implementation
        def self.show_templates
          @@TEMPLATE_SET.keys
        end

        protected

        # Private: Extract parameters from the configuration
        def param_cfg(res)
          Hash[ *(@impl.parameters.map { |k,v| [k, res.get(k)] }.select { |ent| ent[1] }.flatten) ]
        end

      end
    end
  end
end
