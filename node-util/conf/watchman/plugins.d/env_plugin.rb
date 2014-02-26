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
# @!attribute [r] next_check
#   @return [DateTime] timestamp for next check
class EnvPlugin < OpenShift::Runtime::WatchmanPlugin

  attr_reader :next_check

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  # @param [lambda<>] next_update calculates the time for next check
  # @param [DateTime] epoch is when plugin was object instantiated
  def initialize(config, logger, gears, operation, next_update = lambda { DateTime.now + Rational(1, 24) }, epoch = DateTime.now)
    super(config, logger, gears, operation)
    @next_update = next_update
    @next_check  = epoch
  end

  # Test gears' environment for OPENSHIFT_GEAR_DNS existing
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration not used
  # @return void
  def apply(iteration)
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