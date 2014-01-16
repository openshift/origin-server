#--
# Copyright 2014 Red Hat, Inc.
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

module OpenShift
  module Runtime
    module WatchmanPluginTemplate
      module ClassMethods
        # Watchman plugin repository
        def repository
          @repository ||= []
        end

        # Add class to repository when it inherits from class included this method
        def inherited(klass)
          repository << klass
        end
      end

      # Extend class with repository when class is included
      def self.included(klass)
        klass.extend ClassMethods
      end
    end

    # @abstract class and class methods for Watchman plugins. Override {#apply} to implement
    class WatchmanPlugin
      include WatchmanPluginTemplate

      attr_accessor :config, :gears, :restart

      # @param config  [CachedConfig]             Cached elements from node.conf
      # @param gears   [CachedGears]              Cached list of running gears
      # @param restart [lambda<String, DateTime>] lambda passed a gear's uuid and event timestamp
      #   will conditionally restart the gear
      def initialize(config, gears, restart)
        @config, @gears, @restart = config, gears, restart
      end

      # Execute plugin code
      def apply
      end
    end
  end
end