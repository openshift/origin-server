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
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/cgroups/libcgroup'
require 'openshift-origin-node/model/application_container'

# Provide Watchman with monitoring of CGroups resource killing of gears
class OomPlugin < OpenShift::Runtime::WatchmanPlugin
  PLUGIN_NAME    = 'OOM Plugin'
  MEMSW_LIMIT    = 'memory.memsw.limit_in_bytes'
  MEMSW_USAGE    = 'memory.memsw.usage_in_bytes'
  CG_RETRIES     = 3
  BUMP_RETRIES   = 3

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  # @param [Fixnum] number of seconds to wait after calling forcestop
  def initialize(config, logger, gears, operation, stop_wait_seconds = 5)
    super(config, logger, gears, operation)
    # TODO: Make this configurable?
    @memsw_multiplier = 1.1
    @last_check = 0
    @check_interval = ENV['OOM_CHECK_PERIOD'].nil? ? 0 : ENV['OOM_CHECK_PERIOD'].to_i
    @stop_wait_seconds = stop_wait_seconds
  end

  def try_cgstore(cg, attr, value, retries=CG_RETRIES)
    1.upto(retries) do
      begin
        cg.store(attr, value)
        return true
      rescue
        sleep 1
      end
    end
    return false
  end

  def try_cgfetch(cg, attr, retries=CG_RETRIES)
    1.upto(retries) do
      begin
        return cg.fetch(attr)
      rescue
        sleep 1
      end
    end
    return nil
  end

  def safe_pkill(uuid)
    # We need to background and detach this pkill command, because it
    # will usually hang until the memsw limit is bumped.
    pid = Kernel.spawn("pkill -9 -u #{uuid}")
    Process.detach(pid)
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
        oom_control = try_cgfetch(cgroup, 'memory.oom_control')['memory.oom_control']
      rescue
        # Usually means the user has been deleted
        next
      end
      next if oom_control['under_oom'] != '1'

      Syslog.info %Q(#{PLUGIN_NAME}: Found gear #{uuid} under OOM.)

      # Now we need to extend the memory temporarily to see if that solves
      # the problem.

      #store memory limit
      # Should we infer the template from the current values?
      cg = OpenShift::Runtime::Utils::Cgroups.new(uuid)
      restore_memsw_limit = cg.templates[:default][MEMSW_LIMIT].to_i
      orig_memsw_limit = try_cgfetch(cgroup, MEMSW_LIMIT)[MEMSW_LIMIT].to_i
      if orig_memsw_limit == 0
        # Assume it is currently at the templated limit
        orig_memsw_limit = restore_memsw_limit
      end

      begin
        retries = BUMP_RETRIES
        # Verify that we are ready to reset to the old limit
        current = try_cgfetch(cgroup, MEMSW_USAGE)[MEMSW_USAGE].to_i
        increased = orig_memsw_limit
        while (current >= restore_memsw_limit or current == 0 or oom_control['under_oom'] == '1') && retries > 0
          # Increase limit by 10% in order to clean up processes. Trying to
          # restart a gear already at its memory limit is treacherous.
          increased = (increased * @memsw_multiplier).round(0)
          Syslog.info %Q(#{PLUGIN_NAME}: Increasing memory for gear #{uuid} to #{increased} and killing processes)
          safe_pkill(uuid)
          if not try_cgstore(cgroup, MEMSW_LIMIT, increased)
            Syslog.warning %Q(#{PLUGIN_NAME}: Failed to increase memsw limit for gear #{uuid})
          end
          sleep @stop_wait_seconds
          retries -= 1
          current = try_cgfetch(cgroup, MEMSW_USAGE)[MEMSW_USAGE].to_i
          oom_control = try_cgfetch(cgroup, 'memory.oom_control')['memory.oom_control']
        end
      rescue => e
        Syslog.warning %Q(#{PLUGIN_NAME}: error in OOM handling: #{e})
      ensure
        # Reset memory limit
        if not try_cgstore(cgroup, MEMSW_LIMIT, restore_memsw_limit)
          Syslog.warning %Q(#{PLUGIN_NAME}: Failed to lower memsw limit for gear #{uuid} from #{increased} to #{orig_memsw_limit})
        end

        # Finally, restart
        begin
          restart(uuid)
        rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
          Syslog.info %Q(#{PLUGIN_NAME}: Start failed for gear #{uuid}: #{e.message}")
        end
      end
    end
  end
end
