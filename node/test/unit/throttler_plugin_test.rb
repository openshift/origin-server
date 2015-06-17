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

require_relative '../test_helper'

require 'date'
require_relative '../../../node-util/conf/watchman/plugins.d/throttler_plugin'
require_relative '../../../node-util/conf/watchman/plugins.d/monitored_gear'

class ThrottlerPluginTest < OpenShift::NodeTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @cgroups_config = mock('OpenShift::Runtime::Utils::Cgroups::Config')
    @cgroups_config.stubs(:get_group).
        with('cg_template_throttled').
        returns({
                    cpu_shares:       128,
                    cpu_cfs_quota_us: 30000,
                    apply_period:     120,
                    apply_percent:    30,
                    restore_percent:  70,
                })
    OpenShift::Runtime::Utils::Cgroups::Config.stubs(:new).returns(@cgroups_config)
  end

  def test_apply
    gears = []
    OpenShift::Runtime::Utils::Cgroups::Throttler.
        any_instance.
        stubs(:throttle).
        with(gears)
    ThrottlerPlugin.new(nil, nil, gears, nil).apply({})
  end
end
