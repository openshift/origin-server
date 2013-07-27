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
# Test the OpenShift Cgroup utilities
#
require_relative '../test_helper'

class CgroupsUtilsTest < OpenShift::NodeBareTestCase

  def setup
    @uid  = 1234
    @uuid = "nosuchuser"

    @template_query_methods = {
      :default? => :default,
      :boosted? => :boosted,
      :throttled? => :throttled,
      :frozen? => :frozen,
      :thawed? => :thawed
    }

    @template_set_methods = {
      :default => :default,
      :boost => :boosted,
      :throttle => :throttled,
      :freeze => :frozen,
      :thaw => :thawed
    }

    @templates = {
      :default => { "foo" => 1, "bar" => 2, "baz" => 3 },
      :throttled => { "baz" => 4 },
      :boosted => { "baz" => 11 },
      :frozen => { "a" => "b" },
      :thawed => { "a" => "c" }
    }

    @pids=[ 9999999, 8888888, 7777777, 6666666 ]

    @libcgroup_mock = mock('OpenShift::Runtime::Utils::Cgroups::Libcgroup')
    @libcgroup_mock.stubs(:parameters).returns(@templates.map { |k,v| v.keys }.flatten.uniq)
    OpenShift::Runtime::Utils::Cgroups::Libcgroup.expects(:new).with(@uuid).returns(@libcgroup_mock)

    @cls = OpenShift::Runtime::Utils::Cgroups
    @clsany = @cls.any_instance
    @cgroups = @cls.new(@uuid)
  end

  def call_set_call(meth, templ)
    assert @cgroups.methods.include?(meth), "Failed to define_method for #{meth}"
    if @cgroups.methods.include?(meth)
      @clsany.expects(:apply_profile).with(templ)
      @cgroups.send(meth)
    end
  end

  def test_template_set_calls
    @template_set_methods.each do |meth, templ|
      call_set_call(meth, templ)
    end
    call_set_call(:restore, @template_set_methods[:default])
  end

  def test_template_compare_calls
    @template_query_methods.each do |meth, templ|
      assert @cgroups.methods.include?(meth), "Failed to define_method for #{meth}"
      if @cgroups.methods.include?(meth)
        @clsany.expects(:profile).twice.returns(templ).then.returns(:unknown)
        assert @cgroups.send(meth), "Comparison with wrong profile."
        assert (not @cgroups.send(meth)), "Comparison with wrong profile should have failed."
      end
    end
  end

  def test_create
    @clsany.expects(:templates).returns(@templates)
    @libcgroup_mock.expects(:create).with(@templates[:default])
    @cgroups.create
  end

  def test_delete
    @libcgroup_mock.expects(:delete)
    @cgroups.delete
  end

  def test_templates
    resconf = mock('OpenShift::Runtime::Utils::Cgroups::Config')
    resconf.stubs(:get).returns(nil)
    resconf.stubs(:get_group).returns({})

    @templates[:default].each do |k, v|
      resconf.stubs(:get).with(k).returns(v)
    end

    @templates.each do |templ, ent|
      next if templ == :default
      m = mock('OpenShift::Runtime::Utils::Cgroups::Config templ')
      m.stubs(:get).returns(nil)
      m.stubs(:get_group).returns({})

      ent.each do |k, v|
        m.stubs(:get).with(k).returns(v)
      end
      resconf.stubs(:get_group).with("cg_template_#{templ}").returns(m)
    end

    OpenShift::Runtime::Utils::Cgroups::Config.expects(:new).with('/etc/openshift/resource_limits.conf').returns(resconf)

    assert_equal @templates, @cgroups.templates
  end

  def test_current_values
    @clsany.expects(:templates).returns(@templates)
    @clsany.expects(:fetch).with(@templates[:default].keys).returns(@templates[:default])
    assert_equal @cgroups.current_values, @templates[:default]
  end

  def test_fetch
    @libcgroup_mock.expects(:fetch).with(@templates[:default].keys).returns(@templates[:default])
    assert_equal @templates[:default], @cgroups.fetch(@templates[:default].keys)
  end

  def test_store
    @libcgroup_mock.expects(:store).with(@templates[:default])
    @cgroups.store(@templates[:default])
  end

  def test_store_empty
    @libcgroup_mock.stubs(:store).never
    @cgroups.store
  end

  def test_apply_profile
    profile = :throttled

    @clsany.expects(:templates).returns(@templates)
    @clsany.expects(:store).with(@templates[profile]).returns(@templates[profile])
    @clsany.expects(:store).with(@templates[:default]).never

    @cgroups.apply_profile(profile)
  end

  def test_apply_profile_with_block
    profile = :throttled

    @clsany.expects(:templates).returns(@templates).twice
    @clsany.expects(:store).with(@templates[profile]).returns(@templates[profile])
    @clsany.expects(:store).with(@templates[:default]).returns(@templates[:default])

    block_ran = false
    @cgroups.apply_profile(profile) do
      block_ran = true
    end

    assert block_ran, "Did not call the block."
  end

  def test_apply_profile_unknown_template
    profile = :unknown

    @clsany.expects(:templates).returns(@templates)
    @clsany.expects(:store).never

    block_ran = false
    assert_raise ArgumentError do
      @cgroups.apply_profile(profile) do
        block_ran = true
      end
    end

    assert (not block_ran), "called the block."
  end

  def call_profile(profile, values)
    @clsany.expects(:templates).returns(@templates)
    @clsany.expects(:current_values).returns(values)

    assert_equal profile, @cgroups.profile, "Failed to match profile #{profile}"
  end

  def test_profile_default
    call_profile(:default, @templates[:default])
  end

  def test_profile_throttled
    call_profile(:throttled, @templates[:throttled])
  end

  def test_profile_unknown
    call_profile(:unknown, {})
  end

  def test_processes
    @libcgroup_mock.expects(:processes).returns(@pids)
    assert_equal @pids, @cgroups.processes
  end

  def test_classify_processes
    @libcgroup_mock.expects(:classify_processes)
    @cgroups.classify_processes
  end

  def test_class_show_templates
    t = OpenShift::Runtime::Utils::Cgroups.show_templates
    @templates.keys.each do |tname|
      assert t.include?(tname), "Template is missing #{tname}"
    end
  end

  def test_show_templates
    t = @cgroups.show_templates
    @templates.keys.each do |tname|
      assert t.include?(tname), "Template is missing #{tname}"
    end
  end

end
