#!/usr/bin/env oo-ruby

require_relative '../test_helper'
require          'openshift-origin-node/utils/cgroups/throttler'
require          'openshift-origin-node/utils/node_logger'

class ThrottlerTest < OpenShift::NodeTestCase
  def setup
    @@impl = OpenShift::Runtime::Utils::Cgroups::Throttler
    @@mg   = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@cg   = OpenShift::Runtime::Utils::Cgroups
    @@impl.stubs(:start).returns(nil)
    logger = OpenShift::Runtime::NodeLogger::NullLogger.new
    OpenShift::Runtime::NodeLogger.set_logger(logger)

    @resources = mock().tap do |x|
      x.stubs(:get).with('apply_period').returns(10)
      x.stubs(:get).with('apply_threshold').returns(10)
    end

    @mock_config = mock('OpenShift::Runtime::Utils::Cgroups::Config')
    @mock_config.stubs(:get_group).returns(@resources)

    OpenShift::Runtime::Utils::Cgroups::Config.stubs(:new).with('/etc/openshift/resource_limits.conf').returns(@mock_config)

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

  # Correct usage
  def test_init
    period = 9999
    threshold = 5555

    @resources.expects(:get).with('apply_period').returns(period)
    @resources.expects(:get).with('apply_threshold').returns(threshold)

    @@mg.expects("intervals=").with([period])
    @@impl.any_instance.expects(:start).once

    throttler = @@impl.new

    assert_equal period, throttler.interval
    assert_equal threshold, throttler.threshold
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

    # Test finding with apps that fail
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      apps = {"A" => mock_apps['A'], "C" => mock_apps["C"]}
      @throttler.expects(:running_apps).returns(mock_apps)
      @throttler.expects(:utilization).returns(mock_util)

      apps['A'].gear.expects(:profile).raises(RuntimeError)

      (gears, _) = @throttler.find(state: :default)
      assert_equal ({'C' => apps['C']}), gears, "Throttler: find with state"
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
      bad_gears = {
        'A' => mock_apps['A']
      }

      # We should find any bad gears
      @throttler.expects(:find).returns([bad_gears, {}])
      # The first run should try to find previously throttled gears
      @throttler.expects(:find).with(state: :throttled).returns([{},{}])
      @throttler.expects(:apply_action).with({
        restore: {},
        throttle: bad_gears,
      },{})

      @throttler.throttle({})
    end
  end

  def test_throttle_previous_throttled
    mock_apps = {
      "A" => { },
      "B" => { },
      'C' => { }
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      bad_gears = {
        'A' => mock_apps['A']
      }
      throttled_gears = {
        'B' => mock_apps['B']
      }

      # We should find any bad gears
      @throttler.expects(:find).returns([bad_gears, {}])
      # The first run should try to find previously throttled gears
      @throttler.expects(:find).with(state: :throttled).returns([throttled_gears,{}])
      @throttler.expects(:apply_action).with({
        restore: throttled_gears,
        throttle: bad_gears,
      },{})

      @throttler.throttle({})
    end
  end

  def test_throttle_second_run
    mock_apps = {
      "A" => { },
      "B" => { }
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      @throttler.instance_eval{
        @old_bad_gears = {}
      }

      bad_gears = {
        'A' => mock_apps['A']
      }

      # We should find any bad gears
      @throttler.expects(:find).returns([bad_gears, {}])
      # The first run should try to find previously throttled gears
      @throttler.expects(:find).with(state: :throttled).never

      @throttler.expects(:apply_action).with({
        restore: {},
        throttle: bad_gears,
      },{})

      @throttler.throttle({})
    end
  end

  def test_apply_action_failure
    mock_apps = {
      "A" => { },
      "B" => { },
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      @throttler.instance_eval{
        @old_bad_gears = {}
        @bad_gears = {}
      }

      a = mock_apps['A']
      b = mock_apps['B']

      mock_apps.values.each do |g|
        g.gear.expects(:boosted?).returns(false)
      end

      a.gear.expects(:throttle).raises(RuntimeError)
      b.gear.expects(:throttle)

      @throttler.expects(:log_action).with("FAILED throttle","A","RuntimeError", :warning)
      @throttler.expects(:log_action).with(:throttle, 'B', nil)

      apply_hash = {
        throttle: {
          'A' => a,
          'B' => b
        },
      }

      @throttler.instance_eval{
        @old_bad_gears = {}
      }

      @throttler.apply_action(apply_hash, {})

      assert_equal %w(B), @throttler.instance_variable_get('@old_bad_gears').keys
    end
  end

  def test_apply_throttle
    mock_apps = {
      'A' => {}
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      @throttler.instance_eval{
        @old_bad_gears = {}
      }
      a = mock_apps['A'].tap do |app|
        app.gear.tap do |g|
          g.expects(:throttle)
          g.expects(:restore).never
          g.expects(:boosted?).returns(false)
        end
      end
      @throttler.expects(:log_action).with(:throttle, 'A', nil)
      @throttler.apply_action({
        throttle: {
          'A' => a
        }
      },{})
      assert_equal %w(A), @throttler.instance_variable_get('@old_bad_gears').keys
    end
  end

  def test_apply_throttle_already_throttled
    mock_apps = {
      'A' => {}
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      a = mock_apps['A'].tap do |app|
        app.gear.tap do |g|
          g.expects(:throttle).never
          g.expects(:restore).never
          g.expects(:boosted?).never
        end
      end

      @throttler.instance_eval{
        @old_bad_gears = { 'A' => a }
      }
      @throttler.expects(:log_action).with('REFUSED throttle', 'A', "gear already throttled", any_parameters)
      @throttler.apply_action({
        throttle: {
          'A' => a
        }
      },{})
      assert_equal %w(A), @throttler.instance_variable_get('@old_bad_gears').keys
    end
  end

  def test_apply_throttle_to_boosted
    mock_apps = {
      'A' => {}
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      @throttler.instance_eval{
        @old_bad_gears = {}
      }
      a = mock_apps['A'].tap do |app|
        app.gear.tap do |g|
          g.expects(:throttle).never
          g.expects(:restore).never
          g.expects(:boosted?).returns(true)
        end
      end

      @throttler.expects(:log_action).with('REFUSED throttle', 'A', "gear is boosted", any_parameters)
      @throttler.apply_action({
        throttle: {
          'A' => a
        }
      },{})
      assert_empty @throttler.instance_variable_get('@old_bad_gears').keys
    end
  end

  def test_apply_restore
    mock_apps = {
      'A' => {}
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      @throttler.instance_eval{
        @old_bad_gears = {}
        @bad_gears = {}
      }
      a = mock_apps['A'].tap do |app|
        app.gear.tap do |g|
          g.expects(:throttle).never
          g.expects(:restore)
          g.expects(:boosted?).never
        end
      end
      @throttler.expects(:log_action).with(:restore, 'A', nil)
      @throttler.apply_action({
        restore: {
          'A' => a
        }
      },{})
      assert_empty @throttler.instance_variable_get('@old_bad_gears').keys
    end
  end

  def test_apply_restore_over_threshold
    mock_apps = {
      'A' => {}
    }

    with_mock_apps(mock_apps) do |mock_apps, mock_util|
      a = mock_apps['A'].tap do |app|
        app.gear.tap do |g|
          g.expects(:throttle).never
          g.expects(:restore).never
          g.expects(:boosted?).never
        end
      end

      @throttler.instance_eval{
        @old_bad_gears = {}
        @bad_gears = { 'A' => a }
      }
      @throttler.expects(:log_action).with('REFUSED restore', 'A', 'still over threshold', any_parameters)
      @throttler.apply_action({
        restore: {
          'A' => a
        }
      },{})
      assert_empty @throttler.instance_variable_get('@old_bad_gears').keys
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

    @throttler.instance_eval{
      @old_bad_gears = nil
    }

    yield mock_apps, mock_util
  end
end
