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

require 'date'

module OpenShift
  module Runtime
    # @!visibility private
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
      # @!visibility private
      def self.included(klass)
        klass.extend ClassMethods
      end
    end

    # @abstract Subclass for Watchman plugins. Override {#apply} to implement your plugin
    # @api watchman plugin
    #
    # There are three helper methods provided, for your use:
    #   {#restart} to restart a gear,
    #   {#start} to start a gear, and
    #   {#stop} to shutdown the gear's cartridge's daemons
    #
    # @!attribute [r] logger
    #   @return [NodeLogger] logger instance being used
    # @!attribute [r] config
    #   @return [Config] elements from node.conf
    # @!attribute [r] gears
    #   @return [CachedGears] collection of running gears on node
    class WatchmanPlugin
      include WatchmanPluginTemplate

      attr_reader :config, :gears, :logger

      # @param [CachedConfig] config Cached elements from node.conf
      # @param [NodeLogger] logger Logger for items that are not required to be in Syslog
      # @param [CachedGears] gears Cached list of running gears
      # @param [lambda<Symbol, String>] operation lambda passed an operation and gear's uuid to be acted upon.
      #   Supported operations: `:restart`, `:stop` or `:idle`
      def initialize(config, logger, gears, operation)
        @config, @logger, @gears, @operation = config, logger, gears, operation
      end

      # Execute plugin code
      # @param [Iteration] iteration provides timestamps of events
      # @return void
      def apply(iteration)
      end

      # Execute restart on gear
      # @param [String] uuid of gear to restart
      # @return void
      def restart(uuid)
        @operation.call(:restart, uuid)
      end

      # Execute start on gear
      # @param [String] uuid of gear to start
      # @return void
      def start(uuid)
        @operation.call(:start, uuid)
      end

      # Execute stop on gear
      #
      # @note {#stop} attempts to only kill cartridge daemons, not login shells, ssh sessions etc.
      # @param [String] uuid of gear to stop
      # @return void
      def stop(uuid)
        @operation.call(:stop, uuid)
      end

      # Execute idle on gear
      #
      # @param [String] uuid of gear to idle
      # @return void
      def idle(uuid)
        @operation.call(:idle, uuid)
      end
    end

    # Provide Plugins with timestamps of given events
    #
    # @!attribute [r] epoch
    #   @return [DateTime] when was Watchman started?
    # @!attribute [r] last_run
    #   @return [DateTime] when did the last iteration of Watchman start?
    # @!attribute [r] current_run
    #   @return [DateTime] when did this iteration of Watchman start?
    class Iteration
      attr_reader :epoch, :last_run, :current_run

      def initialize(epoch, last_run, current_run = DateTime.now)
        @epoch       = epoch
        @last_run    = last_run
        @current_run = current_run
      end
    end
  end
end
