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
require_relative '../../../node-util/conf/watchman/plugins.d/gear_state_plugin'

class GearStatePluginTest < OpenShift::NodeBareTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @uuid = '461815c0d97e4c94b77b1713dba0901d'
    @ids  = mock('CachedGearIds')
    @ids.expects(:each).yields(@uuid)
    @gears = mock('CachedGear')
    @gears.expects(:ids).returns(@ids)

    @op = mock('Operation')

    @iteration = mock('Iteration')
    @iteration.stubs(:epoch).returns(DateTime.now - Rational(20, 86400))
    @iteration.stubs(:last_run).returns(DateTime.now - Rational(10, 86400))
    @iteration.stubs(:current_run).returns(DateTime.now + Rational(10, 86400))

    @no_logger = mock('NoLogger')
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
    plugin.expects(:change_state?).with(@uuid).returns(true)

    plugin.apply(@iteration)
  end

  def test_stopped
    OpenShift::Runtime::ApplicationContainer.expects(:from_uuid).returns nil
    container = mock("ApplicationContainer")
    container.expects(:idle?).returns false
    OpenShift::Runtime::FrontendHttpServer.expects(:new).with(nil).returns container

    @op.expects(:call).never
    plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
    setup_mocks(plugin, OpenShift::Runtime::State::STOPPED, [])
    plugin.apply(@iteration)
  end

  def test_stopped_pids
    OpenShift::Runtime::ApplicationContainer.expects(:from_uuid).returns nil
    container = mock("ApplicationContainer")
    container.expects(:idle?).returns false
    OpenShift::Runtime::FrontendHttpServer.expects(:new).with(nil).returns container

    @op.expects(:call).with(:stop, @uuid).once

    plugin = GearStatePlugin.new(nil, @no_logger, @gears, @op)
    setup_mocks(plugin, OpenShift::Runtime::State::STOPPED, [1, 2, 3])
    plugin.expects(:change_state?).with(@uuid).returns(true)
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
    plugin.expects(:change_state?).with(@uuid).returns(true)

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

  def test_skip_appy
    @ids.unstub(:each)
    @gears.unstub(:ids)

    @iteration.stubs(:current_run).returns(DateTime.now - Rational(10, 86400))

    @op.expects(:call).never

    plugin = GearStatePlugin.new(nil, @no_logger, @gear, @op,
                                 lambda { DateTime.now - Rational(1, 24) }, DateTime.now)
    plugin.expects(:load_ps_table).never

    plugin.apply(@iteration)
  end
end
