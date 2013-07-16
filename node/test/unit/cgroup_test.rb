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

class CgroupsUtilsTest < OpenShift::NodeTestCase

  def setup

    @resources = {
      "a" => {
        "a.i" => 1,
        "a.ii" => 2,
        "a.iii" => 3,
        "a.iv" => 4,
        "a.v" => 5
      },
      "b" => {
        "b.vi" => 6
      },
      "c" => {
        "c.vii" => 7
      },
      "d" => {
        "d.viii" => 8
      }
    }

    @cgroup_root = "cgroup_root"
    @cgroup_subsystems = @resources.keys.join(",")
    @cgroup_controller_vars = @resources.map { |k,v| v.map { |k,v| k } }.flatten.join(",")

    @uid=123456789
    @uuid="987654321"
    @gecos="blah blah blah"

    @resource_mock = mock('OpenShift::Config')
    @resources.each do |k,v|
      v.each do |k,v|
        limit = "limit_" + k.gsub('.','-')
        @resource_mock.stubs(:get).with(limit).returns(v)
      end
    end
    @resource_mock.stubs(:get).returns(nil)
    OpenShift::Config.stubs(:new).with("/etc/openshift/resource_limits.conf").returns(@resource_mock)

    @config.stubs(:get).with("OPENSHIFT_CGROUP_ROOT").returns(@cgroup_root)
    @config.stubs(:get).with("OPENSHIFT_CGROUP_SUBSYSTEMS").returns(@cgroup_subsystems)
    @config.stubs(:get).with("OPENSHIFT_CGROUP_CONTROLLER_VARS").returns(@cgroup_controller_vars)
    @config.stubs(:get).with("GEAR_GECOS").returns(@gecos)

    @passwd_mock = mock('Etc::Passwd')
    @passwd_mock.stubs(:name).returns(@uuid)
    @passwd_mock.stubs(:uid).returns(@uid)
    @passwd_mock.stubs(:gecos).returns(@gecos)

    @etc_mock = mock('Etc')
    @etc_mock.stubs(:getpwnam).with(@uuid).returns(@passwd_mock)
    @etc_mock.stubs(:passwd).yields(@passwd_mock)

    @attrs_mock = mock('OpenShift::Runtime::Utils::Cgroups::Attrs')
    OpenShift::Runtime::Utils::Cgroups::Attrs.stubs(:new).returns(@attrs_mock)

  end

  def test_with_no_cpu_limits
    @attrs_mock.expects(:[]).with('cpu.cfs_quota_us').returns("foo")
    @attrs_mock.expects(:[]).with("cpu.cfs_period_us").returns("bar")

    quota_calls = sequence('quota_calls')
    @attrs_mock.expects(:[]=).with('cpu.cfs_quota_us', "bar").in_sequence(quota_calls)
    @attrs_mock.expects(:[]=).with('cpu.cfs_quota_us', "foo").in_sequence(quota_calls)

    r = OpenShift::Runtime::Utils::Cgroups::with_no_cpu_limits(@uuid) { "yielded value" }
    assert_equal "yielded value", r, "Did not yield properly"
  end

  def test_gen_cgconfig
    assert_equal " = 1;", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig(1)
    assert_equal " = foo;", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig("foo")
    assert_equal "", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig({})
    assert_equal " { foo = bar; }", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig({ "foo" => "bar" })
    assert_equal " { baz = 1; }", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig({ "baz" => 1 })
    assert_equal " { foo { bar = 1; baz = 2; } }", OpenShift::Runtime::Utils::Cgroups::gen_cgconfig({ "foo" => { "bar" => 1, "baz" => 2 }})
  end

  def test_net_cls
    assert_equal 0x10001,OpenShift::Runtime::Utils::Cgroups::net_cls(1)
    assert_equal 0x10F0F,OpenShift::Runtime::Utils::Cgroups::net_cls(0xF0F)
    assert_equal 0x1FFFF,OpenShift::Runtime::Utils::Cgroups::net_cls(0xFFFF)

    assert_raises RuntimeError do
      OpenShift::Runtime::Utils::Cgroups::net_cls(0x1FFFF)
    end

    assert_raises RuntimeError do
      OpenShift::Runtime::Utils::Cgroups::net_cls("blah")
    end

    assert_raises RuntimeError do
      OpenShift::Runtime::Utils::Cgroups::net_cls(nil)
    end

  end

end
