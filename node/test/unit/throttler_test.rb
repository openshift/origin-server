#!/usr/bin/env oo-ruby

require_relative '../test_helper'
require          'openshift-origin-node/utils/cgroups/throttler'

class ThrottlerTest < OpenShift::NodeTestCase
  def setup
    @@impl = OpenShift::Runtime::Utils::Cgroups::Throttler
    @@mg   = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@cg   = OpenShift::Runtime::Utils::Cgroups
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
      "B" => mock(@@mg.to_s),
      "C" => mock(@@mg.to_s)
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

  def test_find_errors
    assert_raise(ArgumentError) do
      @throttler.find()
    end

    assert_raise(ArgumentError) do
      @throttler.find({})
    end
  end

  def test_find
    mock_utilization = {
      "A" => {
        utilization: {
          10  => {
            usage_percent: 1.0
          },
          20 => {
            usage_percent: 2.0
          }
        }
      },
      "B" => {
        state: :throttled,
        utilization: {
          10  => {
            usage_percent: 2.0
          },
          30 => {
            usage_percent: 2.0
          }
        }
      },
      "C" => {
        utilization: {
          10  => {
            usage_percent: 2.0
          },
          20 => {
            usage_percent: 1.0
          },
          30 => {
            usage_percent: 1.0
          }
        }
      },
    }

    # Test finding apps by state only
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
        default:    {"A" => mock_apps['A'], "C" => mock_apps["C"]},
        throttled:  {"B" => mock_apps['B']}
      }.each do |state,correct|
        @throttler.expects(:running_apps).returns(mock_apps)
        @throttler.expects(:utilization).returns(mock_util)

        (gears, _) = @throttler.find(state: state)
        assert_equal correct, gears, "Throttler: find with state"
      end
    end

    # Test finding apps by usage only
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
        {period: 10, usage: 2.0} => %w(B C),
        {period: 20, usage: 2.0} => %w(A),
        {usage: 2.0} => %w(B)
      }.each do |opts,uuids|
        begin
          @throttler.expects(:running_apps).returns(mock_apps)
          @throttler.expects(:utilization).returns(mock_util)

          unless opts.has_key?(:period)
            @@mg.expects(:intervals).returns([30])
          end

          (gears, _) = @throttler.find(opts)
          assert_equal uuids, gears.keys, "Throttler: find with usage"
        ensure
          @@mg.unstub(:intervals)
        end
      end
    end

    # Test combined find
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
        {period: 10, usage: 2.0, state: :throttled} => %w(B),
      }.each do |opts,uuids|
        @throttler.expects(:running_apps).returns(mock_apps)
        @throttler.expects(:utilization).returns(mock_util)

        (gears, _) = @throttler.find(opts)
        assert_equal uuids, gears.keys, "Throttler: find with usage and state"
      end
    end
  end

  def test_throttle
    mock_apps = {
      "A" => { },
      "B" => { }
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      bad_gears = mock_apps.select{|k,v| %w(A).include?(k) }

      bad_gears.each do |k,v|
        v.gear.expects(:throttle)
      end
      assert_nil @throttler.instance_variable_get('@old_bad_gears')

      # We should find any bad gears
      @throttler.expects(:find).returns([bad_gears, {}])
      # The first run should try to find previously throttled gears
      @throttler.expects(:find).with(state: :throttled).returns([{},{}])
      @throttler.throttle({})

      # Make sure we properly save the old bad gears for next run
      assert_equal bad_gears, @throttler.instance_variable_get('@old_bad_gears')
    end
  end

  def test_throttle_second_run
    mock_apps = {
      "A" => { },
      "B" => { }
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      bad_gears = mock_apps.select{|k,v| %w(A).include?(k) }

      bad_gears.each do |k,v|
        v.gear.expects(:throttle)
      end

      assert_nil @throttler.instance_variable_get('@old_bad_gears')
      @throttler.instance_eval{
        @old_bad_gears = {}
      }
      assert_equal ({}), @throttler.instance_variable_get('@old_bad_gears')

      # We should find any bad gears
      @throttler.expects(:find).returns([bad_gears, {}])
      # The first run should try to find previously throttled gears
      @throttler.expects(:find).with(state: :throttled).never
      @throttler.throttle({})

      # Make sure we properly save the old bad gears for next run
      assert_equal bad_gears, @throttler.instance_variable_get('@old_bad_gears')
    end
  end

  def test_throttle_previous_throttled
    mock_apps = {
      "A" => { },
      "B" => { },
      "C" => {
        state: :throttled,
      }
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      bad_gears = mock_apps.select{|k,v| %w(A B).include?(k) }
      old_gears = mock_apps.select{|k,v| %w(B C).include?(k) }

      mock_apps['A'].gear.expects(:throttle)
      mock_apps['C'].gear.expects(:restore)

      @throttler.expects(:find).returns([bad_gears, {}])
      @throttler.expects(:find).with(state: :throttled).returns([old_gears,{}])
      @throttler.throttle({})
    end
  end

  def test_get_util
    mock_utilization = {
      "A" => {
        utilization: {
          10  => {
            usage_percent: 1.0
          },
        }
      },
      "B" => {
        utilization: {
          10  => {
            usage_percent: 2.0
          },
        }
      },
      "C" => { },
    }

    correct = {
      "A" => 1.0,
      "C" => "???"
    }

    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      wanted_apps = mock_apps.select{|k,v| correct.keys.include?(k) }
      retval = @throttler.get_util(wanted_apps, mock_util)
      assert_equal correct, retval
    end
  end

  protected
  def with_mock_apps(args)
    mock_util = {}
    mock_apps = args.inject({}) do |h,(uuid,vals)|
      mg = mock(@@mg.to_s)
      gear = mock(@@cg.to_s)

      gear.stubs(:profile).returns(vals[:state] || :default)
      mg.stubs(:gear).returns(gear)

      if (util = vals[:utilization])
        mg.stubs(:utilization).returns(util)
        mock_util[uuid] = util
      end
      h[uuid] = mg
      h
    end

    yield mock_apps, mock_util
  end

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
