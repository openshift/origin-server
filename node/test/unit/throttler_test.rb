#!/usr/bin/env oo-ruby

require_relative '../test_helper'
require          'openshift-origin-node/utils/cgroups/throttler'

class ThrottlerTest < OpenShift::NodeTestCase
  def setup
    @@impl = OpenShift::Runtime::Utils::Cgroups::Throttler
    @@mg   = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@impl.stubs(:start).returns(nil)
    @throttler = @@impl.new

    @mock_usage = {
      "good" => {
        usage: 1,
        throttled_time: 2,
        nr_periods: 3,
        cfs_quota_us: 4
      },
      "bad" => {
        usage: 5,
        throttled_time: 6,
        nr_periods: 7,
        cfs_quota_us: 8
      }
    }

    @mock_apps = {
      "A" => mock(@@mg.to_s),
      "B" => mock(@@mg.to_s)
    }
  end

  def test_init
    @@mg.expects("intervals=").with([5])
    @@mg.expects("delay=").with(10)
    @@impl.any_instance.expects(:start).once

    @@impl.new(intervals: [5], delay: 10)
  end

  def test_parse_usage
    correct = Hash[*(@mock_usage.first)]
    uuid = correct.keys.first
    usage_str = fake_usage(uuid, correct[uuid])
    usage = @throttler.parse_usage(usage_str)
    assert_equal correct, usage
  end

  def test_update
    good = @mock_apps.values.first
    # Ensure our data is updated twice
    good.expects(:update).with(@mock_usage['good']).twice

    # Ensure we only try to create a MonitoredGear for a uuid we want
    @throttler.expects(:uuids).twice.returns(["good"])
    @@mg.expects(:new).with('good').once.returns(good)
    @@mg.expects(:new).with('bad').never

    @throttler.update(@mock_usage)
    # Update a second time to make sure we don't create another MonitoredGear
    @throttler.update(@mock_usage)
  end

  def test_set_uuids
    original_uuids = (1..6).to_a
    new_uuids = (5..6).to_a
    # Set some uuids
    @throttler.instance_eval{
      @uuids = original_uuids
      @running_apps = {
        1 => nil,
        2 => nil,
        3 => nil,
        4 => nil,
        5 => nil,
        6 => nil
      }
    }

    assert_equal original_uuids, @throttler.running_apps.keys
    @throttler.uuids = new_uuids
    assert_equal new_uuids, @throttler.running_apps.keys
  end

  def test_utilization
    @mock_apps.values.each do |x|
      x.expects(:utilization).once
    end

    @throttler.expects(:running_apps).returns(@mock_apps)
    @throttler.utilization
  end

  def test_utilization_with_apps
    @mock_apps.values.each do |x|
      x.expects(:utilization).once
    end

    @throttler.expects(:running_apps).never
    @throttler.utilization(@mock_apps)
  end

  protected
  def fake_usage(uuid, *args)
    opts = Hash[*args].merge(uuid: uuid)
    usage_template % opts
  end

  def usage_template
    <<-STR
/cgroup/all/openshift/%<uuid>s/cpuacct.usage:%<usage>d
/cgroup/all/openshift/%<uuid>s/cpu.stat:throttled_time %<throttled_time>d
/cgroup/all/openshift/%<uuid>s/cpu.stat:nr_periods %<nr_periods>d
/cgroup/all/openshift/%<uuid>s/cpu.cfs_quota_us:%<cfs_quota_us>d
    STR
  end
end
