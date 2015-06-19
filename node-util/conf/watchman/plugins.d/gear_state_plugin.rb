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

  attr_accessor :ps_table, :candidates, :state_change_delay, :state_check_period

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  # @param [lambda<>] next_update calculates the time for next check
  # @param [DateTime] epoch is when plugin was object instantiated
  def initialize(config, logger, gears, operation, next_update = nil, epoch = DateTime.now)
    super(config, logger, gears, operation)
    @candidates = Hash.new

    @state_change_delay = 900
    @state_change_delay = ENV['STATE_CHANGE_DELAY'].to_i unless ENV['STATE_CHANGE_DELAY'].nil?

    @state_check_period = 0
    @state_check_period = ENV['STATE_CHECK_PERIOD'].to_i unless ENV['STATE_CHECK_PERIOD'].nil?

    @next_update = next_update || lambda { DateTime.now + Rational(@state_check_period, 86400) }
    @next_check  = epoch

    Syslog.info %Q(Starting Gear State Monitoring, #{@state_change_delay}s state change delay, #{@state_check_period}s check frequency)
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
    return if iteration.current_run < @next_check
    @next_check = @next_update.call

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
            # If node idles gear then user does $(gear stop), frontend cannot be updated.
            # This forces frontend to match .state file
            # https://bugzilla.redhat.com/show_bug.cgi?id=1111077
            frontend = OpenShift::Runtime::FrontendHttpServer.new(
                OpenShift::Runtime::ApplicationContainer.from_uuid(uuid)
            )

            # When a gear is idled, the following happens:
            # 1) the frontend plugin is idled
            # 2) the gear's state is set to STOPPED
            # 3) the gear is stopped (cartridge 'control stop')
            # 4) the gear's state is set to IDLE
            #
            # If this plugin sees the gear at either steps 2 or 3 above, it may
            # incorrectly think there is a mismatch between gear state (STOPPED)
            # and frontend state (idle). To avoid this plugin from prematurely
            # calling unidle, make sure that the gear's state has been STOPPED
            # for at least as long as STATE_CHANGE_DELAY. Also, if there is truly
            # a mismatch, return after calling unidle and let the next iteration
            # perform the logic below the idle check.
            #
            # https://bugzilla.redhat.com/show_bug.cgi?id=1161165
            if frontend.idle? and change_state?(uuid)
              @logger.info %Q(watchman gear #{uuid} httpd frontend server updated to reflect 'stopped' state)
              frontend.unidle

              # let the next iteration handle the logic that follows this block
              return
            end

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
      rescue => e
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

    @candidates[uuid] = TargetGear.new(DateTime.now + Rational(@state_change_delay, 86400))
    false
  end

  # Load process table into Hash
  #
  # @return [Hash<String, Array<Fixnum>>] login name: [running pids]
  def load_ps_table
    @ps_table = Hash.new { |h, k| h[k] = Array.new }

    results, error, rc = Utils.oo_spawn(%Q(ps ax --format 'uid,pid=,ppid=,args='), timeout: 300, quiet: true)
    results.each_line do |entry|
      uid, pid, ppid, *command = entry.split(' ')
      command = command.join(' ')

      # skip everything owned by root (for speed) and not a "daemon" (we can be fooled here)
      if uid == '0' || ppid != '1'
        # bz1134686 - don't skip jenkins builder slaves
        if command !~ /jenkins\/slave.jar/
          next
        end
      end

      # bz1133629
      # skip haproxy and logshifter related processes
      next if command =~ /haproxy/ or command =~ /logshifter/

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

class TargetGear
  attr_accessor :target_time

  def initialize(target_time)
    @target_time = target_time
  end
end
