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

# Provide Watchman with monitoring of CGroups resource killing of gears
class SyslogPlugin < OpenShift::Runtime::WatchmanPlugin
  attr_accessor :log_file, :epoch

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  # @param log_file [String] location of cgroups output
  def initialize(config, logger, gears, operation, log_file = '/var/log/messages')
    super(config, logger, gears, operation)
    @log_file = log_file
  end

  # Search cgroups output for `oom_killer` messages
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration timestamps of given events
  # @return void
  def apply(iteration)
    return if @gears.empty?

    results, error, rc = OpenShift::Runtime::Utils.oo_spawn(%Q{/bin/grep ' killed as a result of limit of ' #{@log_file}},
                                                            quiet: true)
    case rc
      when 1
        ; # grep found no matches
      when 0
        targets = Set.new
        results.split("\n").each do |event|
          ts        = DateTime.strptime(event, '%b %d %T')

          # timezones are just a PITA. Syslog message doesn't include timezone so inject timezone from epoch
          timestamp = DateTime.civil(ts.year, ts.month, ts.day, ts.hour, ts.min, ts.sec, iteration.epoch.zone)
          uuid      = event.scan(/[a-f0-9]{24,32}/).first

          # Skip any messages that occurred before we were started.
          # Assume those have been dealt with manually or on a previous run.
          # We don't want to restart any application that may already be running.
          next if iteration.last_run > timestamp

          # Report only last instance of gear death
          targets << uuid
        end

        targets.each { |u| restart(u) }
      else
        Syslog.notice("Watchman SyslogPlugin failed to read #{@log_file}: (#{rc}) #{error}")
    end
  end
end