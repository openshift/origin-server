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
require_relative '../../../node/lib/openshift-origin-node/utils/application_state'

path = '../../../node-util/conf/watchman/plugins.d/gear_state_plugin'
if File.exists? path
  require_relative path

  class GearStatePluginTest < OpenShift::NodeBareTestCase
    def setup
      Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

      @uuid = '461815c0d97e4c94b77b1713dba0901d'
      @ids  = mock
      @ids.expects(:each).yields(@uuid)
      @gears = mock
      @gears.expects(:ids).returns(@ids)

      @op = mock

      @iteration = mock
      @iteration.stubs(:epoch).returns(DateTime.now)
      @iteration.stubs(:last_run).returns(DateTime.now)
      @iteration.stubs(:current_run).returns(DateTime.now)

      @no_logger = mock
    end

    def setup_mocks(plugin, state, pids)
      @gears.expects(:state).with(@uuid).returns(state)
      plugin.expects(:load_ps_table).once
      plugin.ps_table = {@uuid => pids}
      plugin.expects(:ps).with(@uuid).returns(pids)
    end

    def test_new
      @op.expects(:call).never
      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::NEW, [])
      plugin.apply(@iteration)
    end

    def test_unknown
      @op.expects(:call).with(:restart, @uuid).once

      logger = mock
      logger.expects(:info).with(any_parameters).once
      plugin = GearStatePlugin.new(nil, logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::UNKNOWN, [])
      plugin.apply(@iteration)
    end

    def test_stopped
      @op.expects(:call).never
      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::STOPPED, [])
      plugin.apply(@iteration)
    end

    def test_stopped_pids
      @op.expects(:call).with(:stop, @uuid).once

      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::STOPPED, [1, 2, 3])
      plugin.apply(@iteration)
    end

    def test_idle
      @op.expects(:call).never
      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::IDLE, [])
      plugin.apply(@iteration)
    end

    def test_idle_pids
      @op.expects(:call).with(:idle, @uuid)

      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::IDLE, [1, 2, 3])
      plugin.apply(@iteration)
    end

    def test_started_unlocked_pids
      @gears.expects(:stop_lock?).with(@uuid).returns(false)
      @op.expects(:call).never

      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::STARTED, [1, 2, 3])
      plugin.apply(@iteration)
    end

    def test_started_locked_pids
      path = '/never/create/this/file/please'

      @gears.expects(:stop_lock?).with(@uuid).returns(true)
      @gears.expects(:stop_lock).with(@uuid).returns(path)

      FileUtils.stubs(:rm_f).with(path)
      @op.expects(:call).never

      plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
      setup_mocks(plugin, OpenShift::Runtime::State::STARTED, [1, 2, 3])
      plugin.apply(@iteration)
    end
  end
end