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
require 'set'
require 'openshift-origin-node/model/watchman/watchman_plugin'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/cgroups/libcgroup'
require 'openshift-origin-node/model/application_container'

OP_TIMEOUT=90

# Provide Watchman with monitoring of CGroups resource killing of gears
class OomPlugin < OpenShift::Runtime::WatchmanPlugin
  PLUGIN_NAME    = 'OOM Plugin'
  MEMSW_LIMIT    = 'memory.memsw.limit_in_bytes'
  MEMSW_USAGE    = 'memory.memsw.usage_in_bytes'

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  def initialize(config, logger, gears, operation)
    super(config, logger, gears, operation)
    # TODO: Make this configurable?
    @memsw_multiplier = 1.1
    @last_check = 0
    @check_interval = ENV['OOM_CHECK_PERIOD'].nil? ? 0 : ENV['OOM_CHECK_PERIOD'].to_i
  end

  # Search for gears under_oom
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration timestamps of given events
  # @return void
  def apply(iteration)
    return if @gears.empty? || (Time.now.to_i - @check_interval) < @last_check
    # Syslog.info %Q(#{PLUGIN_NAME}: Iterating gears)
    @last_check = Time.now.to_i

    @gears.ids.each do |uuid|
      cgroup = OpenShift::Runtime::Utils::Cgroups::Libcgroup.new(uuid)
      begin
        oom_control = cgroup.fetch('memory.oom_control')['memory.oom_control']
      rescue
        # Usually means the user has been deleted
        next
      end
      next if oom_control['under_oom'] != '1'

      Syslog.info %Q(#{PLUGIN_NAME}: Found gear #{uuid} under OOM.)

      # Now we need to extend the memory temporarily to see if that solves
      # the problem.

      #store memory limit
      orig_memsw_limit = cgroup.fetch(MEMSW_LIMIT)[MEMSW_LIMIT].to_i

      # Increase limit by 10% in order to clean up processes. Trying to
      # restart a gear already at its memory limit is treacherous.
      increased = (orig_memsw_limit * @memsw_multiplier).round(0)
      Syslog.info %Q(#{PLUGIN_NAME}: Increasing memory for gear #{uuid} to #{increased} and restarting)
      begin
        cgroup.store(MEMSW_LIMIT, increased)
      rescue
        # This is not fatal; it just makes things less likely to work
        Syslog.info %Q(#{PLUGIN_NAME}: Failed to increase memory limit for gear #{uuid})
      end

      begin
        # If gear is under OOM and OOM kill is enabled, skip this and go
        # straight to kill_procs / restart, since the gear has already
        # received kill signals, and if it's wedged, spawning more
        # processes for stop action will just make the kernel do more work.
        if oom_control['oom_kill_disable'] == '1'
          begin
            out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("oo-admin-ctl-gears forcestopgear #{uuid}", timeout: OP_TIMEOUT)
            # Does rc == 0 here indicate success when forcestop is used?
            # Also, does forcestop actually get to its "pkill -9" if
            # the gear is under OOM?
            # NB: memory reset and gear restart happen in the "ensure" block
            next unless rc != 0
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException
            Syslog.info %Q(#{PLUGIN_NAME}: Force stop failed for gear #{uuid} , rc=#{rc}")
            # This is primarily to catch timeouts
          end
        end

        sleep 10

        # Verify that we are ready to reset to the old limit
        retries = 3
        current = cgroup.fetch(MEMSW_USAGE)[MEMSW_LIMIT].to_i
        app = ApplicationContainer.from_uuid(uuid)
        while current > orig_memsw_limit && retries > 0
          increased = (increased * @memsw_multiplier).round(0)
          Syslog.info %Q(#{PLUGIN_NAME}: Increasing memory for gear #{uuid} to #{increased} and killing processes)
          cgroup.store(MEMSW_LIMIT, increased)
          app.kill_procs()
          sleep 5
          retries -= 1
          current = cgroup.fetch(MEMSW_USAGE)[MEMSW_LIMIT].to_i
        end
      ensure
        # Reset memory limit
        begin
          cgroup.store(MEMSW_LIMIT, orig_memsw_limit)
        rescue
          Syslog.warn %Q(#{PLUGIN_NAME}: Failed to lower memsw limit for gear #{uuid} from #{increased} to #{orig_memsw_limit})
        end

        # Finally, restart
        restart(uuid)
      end
    end
  end
end
