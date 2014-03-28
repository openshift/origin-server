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
require 'openshift-origin-node/model/watchman/watchman_plugin'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/shell_exec'

# Provide Watchman monitoring of gear status vs. state
#
# @!attribute [r] ps_table
#   @return [Hash<String, Array<String>>] Hash of login name and running processes.
#     Exposed for testing.
# @!attribute [r] candidates
#   @return [Hash<String, Struct>] Hash of candidate gears for enforced state change
#   @option candidates [String] :uuid gear's uuid
class GearStatePlugin < OpenShift::Runtime::WatchmanPlugin
  include OpenShift::Runtime

  attr_accessor :ps_table, :candidates

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  def initialize(config, logger, gears, operation)
    super
    @target_gear = Struct.new 'TargetGear', :target_time
    @candidates = Hash.new

    @state_change_delay = 900
    @state_change_delay = ENV['STATE_CHANGE_DELAY'].to_i unless ENV['STATE_CHANGE_DELAY'].nil?
    Syslog.info %Q(Starting Gear State Monitoring, #{@state_change_delay}s state change delay)
  end

  # Determine if state and status are out of sync
  #
  #   State => New
  #     Action: Do nothing, gear is being created
  #   State => Unknown
  #     Action: Restart gear
  #   State => Stopped
  #     Action: Stop gear if processes exist
  #       Gear may have been stopped by system or user, so stop_lock is `NOT` set
  #   State => Idle
  #     Action: Idle gear if processes exist
  #       stop_lock is always `SET`
  #   State => started, building, deploying
  #     Action: remove existing stop_lock, restart gear if no processes exist
  #       Watchman throttles restarts
  #
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration not used
  def apply(iteration)
    load_ps_table
    return if @ps_table.empty?

    @gears.ids.each do |uuid|
      begin
        state = @gears.state(uuid)
        pids  = ps(uuid)

        case state
          when State::NEW
            # Caught gear while being created... leave it alone.

          when State::UNKNOWN
            @logger.info %Q(watchman gear #{uuid} in unknown state, will be restarted.)
            restart(uuid) if change_state?(uuid)

          when State::STOPPED
            if pids.empty?
              reset_state(uuid)
            else
              stop(uuid) if change_state?(uuid)
            end

          when State::IDLE
            if pids.empty?
              reset_state(uuid)
            else
              idle(uuid) if change_state?(uuid)
            end

          else
            # Gear has a stop_lock file and a state of running... remove stop_lock
            if @gears.stop_lock?(uuid)
              FileUtils.rm_f(@gears.stop_lock(uuid))
              Syslog.info %Q(watchman deleted stop lock for gear #{uuid} because the state of the gear was #{state})
            end

            if pids.empty?
              restart(uuid) if change_state?(uuid)
            else
              reset_state(uuid)
            end
        end
      rescue Exception => e
        Syslog.info %Q(watchman GearStatePlugin failed for gear #{uuid}: #{e.message}. Processing remaining gears.)
        @logger.info %Q(#{e.message}\n#{e.backtrace.join("\n")})
      end
    end

    @ps_table = nil # release resources
  end

  # Stop tracking state changes for this gear
  #
  # @param uuid [String] gear uuid
  def reset_state(uuid)
    @candidates.delete(uuid)
  end

  # Has gear been observed in the "wrong" state for 15 minutes?
  #
  # @param uuid [String] gear uuid
  # @return [True, False] true if gear state should be changed
  def change_state?(uuid)
    if @candidates.has_key?(uuid)
      if DateTime.now > @candidates[uuid].target_time
        reset_state(uuid)
        return true
      end
      return false
    end

    @candidates[uuid] = @target_gear.new(DateTime.now + Rational(@state_change_delay, 86400))
    false
  end

  # Load process table into Hash
  #
  # @return [Hash<String, Array<Fixnum>>] login name: [running pids]
  def load_ps_table
    @ps_table = Hash.new { |h, k| h[k] = Array.new }

    results, error, rc = Utils.oo_spawn(%Q(ps ax --format 'uid,pid=,ppid='), timeout: 300, quiet: true)
    results.each_line do |entry|
      uid, pid, ppid = entry.split(' ')

      # skip everything owned by root (for speed) and not a "daemon" (we can be fooled here)
      next unless uid != '0' && ppid == '1'

      begin
        name = Etc.getpwuid(uid.to_i).name
        @ps_table[name] << pid
      rescue ArgumentError
        # gear was deleted mid-flight
      end
    end
    @ps_table
  end

  # @param uuid [String] gear uuid
  # @return [Array<Fixnum>] Running processes for gear
  def ps(uuid)
    @ps_table[uuid]
  end
end