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

# Provide Watchman with gear env monitoring
class EnvPlugin < OpenShift::Runtime::WatchmanPlugin

  attr_accessor :next_check

  # @param config      [Config]                   node configuration
  # @param gears       [CachedGears]              collection of running gears on node
  # @param restart     [lambda<String, DateTime>] block to call to cause gear restart
  # @param next_update [lambda<>]                 calculate time for next check
  # @param epoch       [DateTime]                 when was object instantiated
  def initialize(config, gears, restart, next_update = lambda { DateTime.now + Rational(1, 24) }, epoch = DateTime.now)
    super(config, gears, restart)
    @next_update = next_update
    @next_check  = epoch
  end

  # execute plugin code
  def apply
    return if DateTime.now < @next_check
    @next_check = @next_update.call

    @gears.each do |uuid|
      path = PathUtils.join(@config.get('GEAR_BASE_DIR', '/var/lib/openshift'), uuid, '.env', 'OPENSHIFT_GEAR_DNS')
      unless File.file? path
        Syslog.warning("watchman unable to determine application setup for gear #{uuid}. #{path} missing.")
      end
    end
  end
end