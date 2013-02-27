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

require 'rubygems'
require 'etc'
require 'openshift-origin-common'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift

  # Represents all possible application states
  module State
    BUILDING  = "building"
    DEPLOYING = "deploying"
    IDLE      = "idle"
    NEW       = "new"
    STARTED   = "started"
    STOPPED   = "stopped"
    UNKNOWN   = "unknown"
  end

  module Utils
    # Class to maintain persistent application state
    class ApplicationState

      attr_reader :uuid

      def initialize(uuid)
        @uuid = uuid

        config      = OpenShift::Config.new
        @state_file = File.join(config.get("GEAR_BASE_DIR"), uuid, "app-root", "runtime", ".state")
      end

      # Public: Sets the application state.
      #
      # @param [String]   new_state - From Openshift::State.
      # @return [Object]  self for chaining calls
      def value=(new_state)
        new_state_val = nil
        begin
          new_state_val = OpenShift::State.const_get new_state.upcase.intern
        rescue
          raise ArgumentError, "Invalid state '#{new_state}' specified"
        end

        File.open(@state_file, File::WRONLY|File::TRUNC|File::CREAT, 0640) { |file|
          file.write "#{new_state_val}\n"
        }

        parent = File.dirname(@state_file)
        OpenShift::Utils.oo_spawn(
            "chown --reference #{parent} #@state_file;
             chcon --reference #{parent} #@state_file"
        )
        self
      end


      # Public: Fetch application state from gear.
      #
      # @return [String] application state or State::UNKNOWN on failure
      def value
        begin
          File.open(@state_file) { |input| input.read.chomp }
        rescue
          State::UNKNOWN
        end
      end
    end
  end
end
