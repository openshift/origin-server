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

require 'openshift-origin-node/model/watchman/watchman_plugin'

# Provide Watchman with JBoss server.log monitoring
class JbossPlugin < OpenShift::Runtime::WatchmanPlugin
  attr_accessor :epoch

  # @param config  [Config]                   node configuration
  # @param gears   [CachedGears]              collection of running gears on node
  # @param restart [lambda<String, DateTime>] block to call to cause gear restart
  # @param epoch   [DateTime]                 Time when this plugin was started
  def initialize(config, gears, restart, epoch = DateTime.now)
    super(config, gears, restart)
    @epoch = epoch
  end

  # execute plugin code
  def apply
    @gears.each do |uuid|
      path    = PathUtils.join(@config.get('GEAR_BASE_DIR', '/var/lib/openshift'),
                               uuid,
                               '*',
                               'env',
                               'OPENSHIFT_JBOSS*_LOG_DIR')
      results = Dir.glob(path)
      next if results.nil? || results.empty?

      results.each do |var|
        log = PathUtils.join(IO.read(var).chomp, 'server.log')

        # skip missing log files as jboss may be coming up.
        next unless File.exist?(log)

        File.open(log, 'r:utf-8').grep(/ java.lang.OutOfMemoryError/) do |event|
          # timezones are just a PITA. server.log message doesn't include timezone or date so inject both from today
          #
          # Set the timestamp for messages with invalid timestamps to the 'epoch',
          # which will prevent to retry the parsing and exceptions in the log (BZ#999183)
          ts = DateTime.strptime(event, '%Y/%m/%d %T') rescue @epoch
          timestamp = DateTime.civil(ts.year, ts.month, ts.day, ts.hour, ts.min, ts.sec, @epoch.zone)
          next if @epoch > timestamp

          @restart.call(uuid, timestamp)
        end
      end
    end
  end
end
