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
class GearStatePlugin < OpenShift::Runtime::WatchmanPlugin
  include OpenShift::Runtime

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
        #pids      = pgrep(uuid)
        pids  = ps(uuid)

        case state
          when State::NEW
            # Caught gear while being created... leave it alone.

          when State::UNKNOWN
            @logger.info %Q(watchman gear #{uuid} in unknown state, will be restarted.)
            restart(uuid)

          when State::STOPPED
            stop(uuid) unless pids.empty?

          when State::IDLE
            idle(uuid) unless pids.empty?

          else
            # Gear has a stop_lock file and a state of running... remove stop_lock
            if @gears.stop_lock?(uuid)
              FileUtils.rm_f(@gears.stop_lock(uuid))
              Syslog.info %Q(watchman deleted stop lock for gear #{uuid} because the state of the gear was #{state})
            end

            restart(uuid) if pids.empty?
        end
      rescue Exception => e
        Syslog.info %Q(watchman GearStatePlugin failed for gear #{uuid}: #{e.message}. Processing remaining gears.)
        @logger.info %Q(#{e.message}\n#{e.backtrace.join("\n")})
      end
    end

    @ps_table = nil # free resources
  end

  # Find any processes running for this gear
  # @param [String] uuid of gear we're operating on
  # @return [Array<String>] pids of running processes
  def pgrep(uuid)
    command     = %Q(/usr/bin/pgrep -u $(id -u #{uuid}))
    pids, _, rc = Utils.oo_spawn(command, quiet: true, timeout: 300)

    case rc
      when 0
        pids.split("\n")
      when 1
        Array.new
      else
        raise RuntimeError, %Q(watchman search for running processes failed: #{command} (#{rc}))
    end
  end

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

  def ps(uuid)
    @ps_table[uuid]
  end
end