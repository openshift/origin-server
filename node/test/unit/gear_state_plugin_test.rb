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
require_relative '../../../node-util/conf/watchman/plugins.d/gear_state_plugin'
require_relative '../../../node/lib/openshift-origin-node/utils/application_state'

class GearStatePluginTest < OpenShift::NodeBareTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @uuid = '461815c0d97e4c94b77b1713dba0901d'
    @ids = mock
    @ids.expects(:each).yields(@uuid)
    @gears = mock
    @gears.expects(:ids).returns(@ids)

    @restart = mock

    @iteration = mock
    @iteration.stubs(:epoch).returns(DateTime.now)
    @iteration.stubs(:last_run).returns(DateTime.now)
    @iteration.stubs(:current_run).returns(DateTime.now)

    @no_logger = mock
  end

  def setup_mocks(state, pids)
    @gears.expects(:state).with(@uuid).returns(state)
    GearStatePlugin.any_instance.expects(:pgrep).with(@uuid).returns(pids)
  end

  def test_new
    setup_mocks(OpenShift::Runtime::State::NEW, [])
    @restart.expects(:call).never
    GearStatePlugin.new(nil, @no_logger, @gears, @restart).apply(@iteration)
  end

  def test_unknown
    setup_mocks(OpenShift::Runtime::State::UNKNOWN, [])
    @restart.expects(:call).with(:restart, @uuid).once

    logger = mock
    logger.expects(:info).with(any_parameters).once
    GearStatePlugin.new(nil, logger, @gears, @restart).apply(@iteration)
  end

  def test_stopped
    setup_mocks(OpenShift::Runtime::State::STOPPED, [])
    @restart.expects(:call).never
    GearStatePlugin.new(nil, @no_logger, @gears, @restart).apply(@iteration)
  end

  def test_stopped_pids
    setup_mocks(OpenShift::Runtime::State::STOPPED, [1, 2, 3])
    @restart.expects(:call).with(:stop, @uuid).once

    gear = GearStatePlugin.new(nil, @no_logger, @gears, @restart)
    gear.apply(@iteration)
  end

  def test_idle
    setup_mocks(OpenShift::Runtime::State::IDLE, [])
    @restart.expects(:call).never
    GearStatePlugin.new(nil, @no_logger, @gears, @restart).apply(@iteration)
  end

  def test_idle_pids
    setup_mocks(OpenShift::Runtime::State::IDLE, [1, 2, 3])
    @restart.expects(:call).with(:idle, @uuid)

    gear = GearStatePlugin.new(nil, @no_logger, @gears, @restart)
    gear.apply(@iteration)
  end

  def test_started_unlocked_pids
    setup_mocks(OpenShift::Runtime::State::STARTED, [1, 2, 3])
    @gears.expects(:stop_lock?).with(@uuid).returns(false)
    @restart.expects(:call).never

    GearStatePlugin.new(nil, @no_logger, @gears, @restart).apply(@iteration)
  end

  def test_started_locked_pids
    path = '/never/create/this/file/please'

    setup_mocks(OpenShift::Runtime::State::STARTED, [1, 2, 3])
    @gears.expects(:stop_lock?).with(@uuid).returns(true)
    @gears.expects(:stop_lock).with(@uuid).returns(path)

    FileUtils.stubs(:rm_f).with(path)
    @restart.expects(:call).never

    GearStatePlugin.new(nil, @no_logger, @gears, @restart).apply(@iteration)
  end
end