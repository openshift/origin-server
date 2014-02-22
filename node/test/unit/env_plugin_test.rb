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
require_relative '../../../node-util/conf/watchman/plugins.d/env_plugin'

class EnvPluginTest < OpenShift::NodeBareTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def setup
    Syslog.open('EnvPluginFuncTest', Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @uuid        = '461815c0d97e4c94b77b1713dba0901d'
    @gears       = mock
    @config      = mock
    @next_update = lambda { DateTime.now - Rational(1, 86400) }

    @nologger = mock
    @restart  = mock
    @restart.expects(:call).never

    @path = PathUtils.join(GEAR_BASE_DIR, @uuid, '.env', 'OPENSHIFT_GEAR_DNS')
  end

  def test_refute_gear_dns
    @gears.expects(:each).yields(@uuid)
    @config.expects(:get).with('GEAR_BASE_DIR', GEAR_BASE_DIR).returns(GEAR_BASE_DIR)
    File.expects(:file?).with(@path).returns(false)
    Syslog.expects(:warning).with(regexp_matches(/watchman unable to determine application setup for gear/))

    EnvPlugin.new(@config, @nologger, @gears, @restart, @next_update, @next_update.call).apply({})
  end

  def test_assert_gear_dns
    @gears.expects(:each).yields(@uuid)
    @config.expects(:get).with('GEAR_BASE_DIR', GEAR_BASE_DIR).returns(GEAR_BASE_DIR)
    File.expects(:file?).with(@path).returns(true)
    Syslog.expects(:warning).never

    EnvPlugin.new(@config, @nologger, @gears, @restart, @next_update, @next_update.call).apply({})
  end

  def test_next_check
    @config.expects(:get).never
    @gears.expects(:each).never
    Syslog.expects(:warning).never

    next_update = lambda { DateTime.now + Rational(1, 86400) }
    EnvPlugin.new(@config, @nologger, @gears, @restart, next_update, next_update.call).apply({})
  end
end
