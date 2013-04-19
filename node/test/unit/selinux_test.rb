#!/usr/bin/env oo-ruby
#--
# Copyright 2012-2013 Red Hat, Inc.
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
#
# Test the OpenShift selinux utilities
#
require_relative '../test_helper'

class SELinuxUtilsTest < Test::Unit::TestCase

  def setup
    @config_mock = mock('OpenShift::Config')
    @config_mock.stubs(:get).returns(nil)
    OpenShift::Config.stubs(:new).returns(@config_mock)
  end

  def teardown
  end

  def test_mcs_labels
    labelset = OpenShift::Utils::SELinux.mcs_labels.to_a
    assert_equal 523776, labelset.length
    assert_equal [1, "s0:c0,c1"], labelset[0]
    assert_equal [523776, "s0:c1022,c1023"], labelset[-1]
  end

  def test_mcs_label
    scenarios = [
                 [500,    "s0:c0,c500"],
                 [1023,   "s0:c0,c1023"],
                 [1024,   "s0:c1,c2"],
                 [1524,   "s0:c1,c502"],
                 [2045,   "s0:c1,c1023"],
                 [2046,   "s0:c2,c3"],
                 [4092,   "s0:c4,c10"],
                 [8184,   "s0:c8,c36"],
                 [14191,  "s0:c13,c983"],
                 [16368,  "s0:c16,c136"],
                 [26851,  "s0:c26,c604"],
                 [32736,  "s0:c32,c528"],
                 [65472,  "s0:c66,c165"],
                 [130944, "s0:c137,c246"],
                 [261888, "s0:c299,c861"],
                 [523776, "s0:c1022,c1023"],
                ]
    scenarios.each do |s|
      assert_equal s[1], OpenShift::Utils::SELinux.get_mcs_label(s[0])
    end

    def test_set_mcs_label
      pathargs="foo bar baz"
      label="s0:c0,c1,c2,c3,c4,c5,c6,c7,c8"
      OpenShift::Utils::SELinux.expects(:call_selinux_cmd).with("/sbin/restorecon #{pathargs}; /usr/bin/chcon -l #{label} #{pathargs}").returns("").twice
      assert_equal "", OpenShift::Utils::SELinux.set_mcs_label(label, "foo", "bar", "baz")
      assert_equal "", OpenShift::Utils::SELinux.set_mcs_label(label, [ "foo", "bar", "baz" ])
    end

    def test_set_mcs_label_R
      pathargs="foo bar baz"
      label="s0:c0,c1,c2,c3,c4,c5,c6,c7,c8"
      OpenShift::Utils::SELinux.expects(:call_selinux_cmd).with("/sbin/restorecon -R #{pathargs}; /usr/bin/chcon -R -l #{label} #{pathargs}").returns("").twice
      assert_equal "", OpenShift::Utils::SELinux.set_mcs_label_R(label, "foo", "bar", "baz")
      assert_equal "", OpenShift::Utils::SELinux.set_mcs_label_R(label, [ "foo", "bar", "baz" ])
    end

    def test_clear_mcs_label
      pathargs="foo bar baz"
      OpenShift::Utils::SELinux.expects(:call_selinux_cmd).with("/sbin/restorecon -F #{pathargs}").returns("").twice
      assert_equal "", OpenShift::Utils::SELinux.clear_mcs_label("foo", "bar", "baz")
      assert_equal "", OpenShift::Utils::SELinux.clear_mcs_label([ "foo", "bar", "baz" ])
    end

    def test_clear_mcs_label_R
      pathargs="foo bar baz"
      OpenShift::Utils::SELinux.expects(:call_selinux_cmd).with("/sbin/restorecon -R -F #{pathargs}").returns("").twice
      assert_equal "", OpenShift::Utils::SELinux.clear_mcs_label("foo", "bar", "baz")
      assert_equal "", OpenShift::Utils::SELinux.clear_mcs_label([ "foo", "bar", "baz" ])
    end

    def test_context_from_defaults
      assert_equal "unconfined_u:system_r:openshift_t:s0", OpenShift::Utils::SELinux.context_from_defaults()
      assert_equal "unconfined_u:system_r:openshift_t:foo", OpenShift::Utils::SELinux.context_from_defaults("foo")
      assert_equal "unconfined_u:system_r:bar:foo", OpenShift::Utils::SELinux.context_from_defaults("foo", "bar")
      assert_equal "unconfined_u:baz:bar:foo", OpenShift::Utils::SELinux.context_from_defaults("foo", "bar", "baz")
      assert_equal "boing:baz:bar:foo", OpenShift::Utils::SELinux.context_from_defaults("foo", "bar", "baz", "boing")
    end

    def test_getcon
      File.expects(:read).with("/proc/#{$$}/attr/current").returns("boing:baz:bar:foo\n\n\n").once
      assert_equal "boing:baz:bar:foo", OpenShift::Utils::SELinux.getcon
    end

    def test_call_selinux_cmd_success
      OpenShift::NodeLogger.logger.expects(:debug).never
      OpenShift::Utils.stubs(:oo_spawn).returns(["OUT", "ERR", 0]).once
      assert_equal "OUTERR", OpenShift::Utils::SELinux.call_selinux_cmd("foo")
    end

    def test_call_selinux_cmd_fail
      OpenShift::NodeLogger.logger.expects(:debug).once
      OpenShift::Utils.stubs(:oo_spawn).raises(OpenShift::Utils::ShellExecutionException.new('error')).once
      assert_raises RuntimeError do
        OpenShift::Utils::SELinux.call_selinux_cmd("bar")
      end
    end

  end
end
