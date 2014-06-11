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

# if File.exist? '../../../node-util/conf/watchman/plugins.d/oom_plugin.rb'
require_relative '../../../node-util/conf/watchman/plugins.d/oom_plugin'

class OomPluginTest < OpenShift::NodeBareTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @uuids = %w(52cc244091aa71fac4000007 52cc244091aa71fac4000008 52cc244091aa71fac4000009)
    @gears = mock
    @gears.stubs(:ids).returns @uuids
    @gears.stubs(:empty?).returns @uuids.empty?

    @operation = mock
  end

  def test_no_oom_control
    cgroup = mock
    cgroup.expects(:fetch).
        with('memory.oom_control').
        returns({'memory.oom_control' => {'under_oom' => '0'}}).
        times(@uuids.length)
    OpenShift::Runtime::Utils::Cgroups::Libcgroup.expects(:new).
        with(any_of(*@uuids)).
        returns(cgroup).
        times(@uuids.length)
    @operation.expects(:call).never

    OomPlugin.new(nil, nil, @gears, @operation).apply(nil)
  end

  def test_oom_control
    cgroup = mock
    cgroup.expects(:fetch).
        with('memory.oom_control').
        returns({'memory.oom_control' =>
                     {'under_oom'        => '1',
                      'oom_kill_disable' => '0'}}).
        times(@uuids.length)
    cgroup.expects(:fetch).with(OomPlugin::MEMSW_LIMIT).returns({OomPlugin::MEMSW_LIMIT => 1024}).times(3)
    cgroup.expects(:fetch).with(OomPlugin::MEMSW_USAGE).returns({OomPlugin::MEMSW_LIMIT => 1024}).times(3)
    cgroup.expects(:store).with(OomPlugin::MEMSW_LIMIT, kind_of(Fixnum)).times(@uuids.length * 2)

    OpenShift::Runtime::ApplicationContainer.expects(:from_uuid).
        with(any_of(*@uuids)).
        returns(nil).
        times(@uuids.length)

    OpenShift::Runtime::Utils::Cgroups::Libcgroup.expects(:new).
        with(any_of(*@uuids)).
        returns(cgroup).
        times(@uuids.length)

    @operation.expects(:call).with(:restart, any_of(*@uuids)).times(3)

    OomPlugin.new(nil, nil, @gears, @operation, 0).apply(nil)
  end
end
# end
