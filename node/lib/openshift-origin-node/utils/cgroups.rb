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
require_relative 'cgroups/template'

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


        @@TEMPLATE_SET = {
          :default => [ :restore, :default? ],
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

        # TODO: Move template defs to resource_limits.conf
        #       Raise an exception if the default template does not have a value for every other template?
        def templates
          if not @@templates_cache
            res = Config.new('/etc/openshift/resource_limits.conf')
            @@templates_cache={}
            @@TEMPLATE_SET.each do |templ, calls|
              if templ == :default
                @@templates_cache[templ]=Template.new(param_cfg(res))
              else
                @@templates_cache[templ]=Template.new(param_cfg(res.get_group("cg_template_#{templ}")))
              end
            end
          end
          @@templates_cache
        end

        # Get the current values for any keys specified in the default template
        def current_values
          keys = templates[:default].keys
          fetch(keys)
        end

        def usage
          fetch(%w(cpuacct.usage cpu.stat))
        end

        # Public: Fetch the values from the current cgroup
        #   - If args is a single value, it will return the value
        #   - If args is an array, it will return a Template of values
        def fetch(*args)
          t = Template.new(@impl.fetch(*args))
          if (v = t.values).length > 1
            t
          else
            v.first
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
          r = store(templates[type])
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
        # TODO: This probably needs to be fixed based on the changes to templates
        def profile
          cur = current_values
          # Search through known templates and compare them with our current values
          (templates.find{|k,v| v == cur} || [:unknown]).first
        end

        # Public: List the process ids which are a member of this gear's cgroup.
        def processes
          @impl.processes
        end

        # Public: Distribute this user's processes into their cgroup
        def classify_processes
          @impl.classify_processes
        end

        # Public: List the templates available to this gear
        def show_templates
          self.class.templates
        end

        # Public: List the templates available in the implementation
        def self.show_templates
          @@TEMPLATE_SET.keys
        end

        protected

        # Private: Extract parameters from the configuration
        def param_cfg(res)
          Hash[ *(@impl.parameters.map { |k| [k, res.get(k)] }.select { |ent| ent[1] }.flatten) ]
        end

      end
    end
  end
end
