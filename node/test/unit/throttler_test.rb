#!/usr/bin/env oo-ruby

require_relative '../test_helper'
require_relative '../../../node-util/conf/watchman/plugins.d/throttler_plugin'
require_relative '../../../node-util/conf/watchman/plugins.d/monitored_gear'
require          'openshift-origin-node/utils/node_logger'

class ThrottlerTest < OpenShift::NodeTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @@impl = OpenShift::Runtime::Utils::Cgroups::Throttler
    @@mg   = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@cg   = OpenShift::Runtime::Utils::Cgroups
    @@impl.stubs(:start).returns(nil)
    logger = OpenShift::Runtime::NodeLogger::NullLogger.new
    OpenShift::Runtime::NodeLogger.set_logger(logger)

    @@impl.any_instance.stubs(:resource).with('apply_period').returns(120)
    @@impl.any_instance.stubs(:resource).with('apply_percent').returns(30)
    @@impl.any_instance.stubs(:resource).with('restore_percent').returns(70)
    @throttler = @@impl.new

    @mock_usage = {
        'good' => {
            'usage'          => 1,
            'throttled_time' => 2,
            'nr_periods'     => 3,
            'cfs_quota_us'   => 4
        },
        'bad'  => {
            'usage'          => 5,
            'throttled_time' => 6,
            'nr_periods'     => 7,
            'cfs_quota_us'   => 8
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

    @@impl.any_instance.stubs(:resource).with('apply_period').returns(period)
    @@impl.any_instance.stubs(:resource).with('apply_percent').returns(threshold)

    @@mg.expects("intervals=").with([period])
    @@impl.any_instance.expects(:start).once

    throttler = @@impl.new

    assert_equal period, throttler.interval
  end

  def test_init_missing_config
    @@impl.any_instance.unstub(:resource)
    resources = mock().tap do |x|
      x.stubs(:get).returns(nil)
    end

    mock_config = mock('OpenShift::Runtime::Utils::Cgroups::Config')
    mock_config.stubs(:get_group).returns(resources)

    OpenShift::Runtime::Utils::Cgroups::Config.stubs(:new).with('/etc/openshift/resource_limits.conf').returns(mock_config)

    assert_raise ArgumentError do
      @@impl.new
    end
  end

  def test_init_invalid_config
    @@impl.any_instance.unstub(:resource)
    resources = mock().tap do |x|
      x.stubs(:get).returns("asdf")
    end

    mock_config = mock('OpenShift::Runtime::Utils::Cgroups::Config')
    mock_config.stubs(:get_group).returns(resources)

    OpenShift::Runtime::Utils::Cgroups::Config.stubs(:new).with('/etc/openshift/resource_limits.conf').returns(mock_config)

    assert_raise ArgumentError do
      @@impl.new
    end
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
        'A' => {
            utilization: {
                10 => {
                    'usage_percent' => 1.0
                },
                20 => {
                    'usage_percent' => 2.0
                }
            }
        },
        'B' => {
            state:       :throttled,
            utilization: {
                10 => {
                    'usage_percent' => 2.0
                },
                30 => {
                    'usage_percent' => 2.0
                }
            }
        },
        'C' => {
            utilization: {
                10 => {
                    'usage_percent' => 2.0
                },
                20 => {
                    'usage_percent' => 1.0
                },
                30 => {
                    'usage_percent' => 1.0
                }
            }
        },
    }

    # Test finding apps by state only
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
          default:   {"A" => mock_apps['A'], "C" => mock_apps["C"]},
          throttled: {"B" => mock_apps['B']}
      }.each do |state, correct|
        @throttler.expects(:running_apps).returns(mock_apps)
        @throttler.expects(:utilization).returns(mock_util)

        (gears, _) = @throttler.find(state: state)
        assert_equal correct, gears, 'Throttler: find with state only'
      end
    end

    # Test finding with apps that fail
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      apps = {"A" => mock_apps['A'], "C" => mock_apps["C"]}
      @throttler.expects(:running_apps).returns(mock_apps)
      @throttler.expects(:utilization).returns(mock_util)

      apps['A'].gear.expects(:profile).raises(RuntimeError)

      (gears, _) = @throttler.find(state: :default)
      assert_equal ({'C' => apps['C']}), gears, 'Throttler: find failing apps'
    end

    # Test finding apps by usage only
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
          {period: 10, usage: 2.0} => %w(B C),
          {period: 20, usage: 2.0} => %w(A),
          {usage: 2.0}             => %w(B)
      }.each do |opts, uuids|
        begin
          @throttler.expects(:running_apps).returns(mock_apps)
          @throttler.expects(:utilization).returns(mock_util)

          unless opts.has_key?('period')
            @@mg.expects(:intervals).returns([30])
          end

          (gears, _) = @throttler.find(opts)
          assert_equal uuids, gears.keys, 'Throttler: find with usage only'
        ensure
          @@mg.unstub(:intervals)
        end
      end
    end

    # Test combined find
    with_mock_apps(mock_utilization) do |mock_apps, mock_util|
      {
          {period: 10, usage: 2.0, state: :throttled} => %w(B),
      }.each do |opts, uuids|
        @throttler.expects(:running_apps).returns(mock_apps)
        @throttler.expects(:utilization).returns(mock_util)

        (gears, _) = @throttler.find(opts)
        assert_equal uuids, gears.keys, 'Throttler: find with usage and state'
      end
    end
  end

  def test_throttle
    mock_apps = {
      'A' => {
        expects: {
          boosted?: false
        },
      },
      'B' => {
        expects: {
          boosted?: true
        },
      },
      'C' => {
        utilization: {
          10  => {
              'usage_percent' => 0
          },
        },
      },
      'D' => {
        utilization: {
          10  => {
              'usage_percent' => 1000000
          },
        },
      },
      'E' => {},
      'F' => {
        utilization: {
          10  => {
              'usage_percent' => 1000000
          },
        },
      },
    }

    applied = setup_throttler(mock_apps, {
      bad: %w(A B F),
      throttled: %w(C D E F)
    }) do |t|
      @throttler.instance_eval{
        @running_apps = mock_apps
      }

      t.expects(:refuse_action).with(:throttle, 'B', 'gear is boosted')
      t.expects(:refuse_action).with(:restore, 'D', 'still over threshold (1000000)')
      t.expects(:refuse_action).with(:restore, 'E', 'unknown utilization')
      t.expects(:refuse_action).with(:restore, 'F', 'still over threshold (1000000)')
    end

    throttled = applied[:throttle]
    restored = applied[:restore]

    assert throttled.include?('A'), 'Bad gear not throttled'
    refute restored.include?('A'),  'Attempted to restore bad gear'

    refute throttled.include?('B'), 'Attempted to throttle boosted gear'
    refute restored.include?('B'),  'Attempted to restore boosted gear'

    assert restored.include?('C'),  'Previously throttled gear under utilization not restored'
    refute throttled.include?('C'), 'Attempted to throttle previously throttled gear under utilization'

    refute restored.include?('D'),  'Attempted to restore previously throttled gear over utilization'
    refute throttled.include?('D'), 'Attempted to throttle previously throttled gear over utilization'

    refute restored.include?('E'),  'Attempted to restore previously throttled gear with unknown utilization'
    refute throttled.include?('E'), 'Attempted to throttle previously throttled gear with unknown utilization'
  end

  def test_throttle_second_run
    mock_apps = {
      'A' => {
        expects: {
          boosted?: false
        },
      },
      'C' => {}
    }

    applied = setup_throttler(mock_apps, {
      bad: %w(A),
      throttled: [],
      old_bad_gears: {'B' => {}, 'C' => {}}
    }) do
      @prev_old_bad_gears = @throttler.instance_variable_get('@old_bad_gears').keys
    end

    assert applied[:throttle].include?('A'), 'Bad gear not throttled'
    refute applied[:restore].include?('A'),  'Attempted to restore bad gear'

    #assert_equal %w(B), @prev_old_bad_gears
    #assert_empty @throttler.instance_variable_get('@old_bad_gears').keys
  end

  def test_throttle_remove_missing
    mock_apps = {
      'A' => {
        expects: {
          boosted?: false
        },
      },
      'B' => {
      },
    }

    applied = setup_throttler(mock_apps, {
      bad: %w(A C),
      throttled: [],
      old_bad_gears: {'B' => {}, 'C' => {}}
    }) do
      @prev_old_bad_gears = @throttler.instance_variable_get('@old_bad_gears').keys
    end

    assert_equal %w(B C), @prev_old_bad_gears
    # NOTE: We don't actually expect A to be here because that happens in apply action, which we're mocking here
    #       This will only show that old values are removed. Apply_action tests check to see that it's set properly.
    assert_equal %w(B),   @throttler.instance_variable_get('@old_bad_gears').keys
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

      a.gear.expects(:throttle).raises(RuntimeError)
      b.gear.expects(:throttle)

      @throttler.expects(:failed_action).with(:throttle,"A","RuntimeError")
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

      if (e = vals[:expects])
        e.each do |k,v|
          if v == :never
            gear.expects(k).never
          else
            gear.expects(k).returns(v)
          end
        end
      end
      h[uuid] = mg
      h
    end

    @throttler.instance_eval{
      @old_bad_gears = nil
    }

    yield mock_apps, mock_util
  end

  def setup_throttler(apps, _opts)
    default = Hash.new({})
    opts = default.merge(_opts)

    with_mock_apps(apps) do |mock_apps, mock_util|
      bad = mock_apps.select{|k,v| opts[:bad].include?(k) }
      throttled = mock_apps.select{|k,v| opts[:throttled].include?(k) }

      @throttler.expects(:find).returns([bad, mock_util])
      if (old = _opts[:old_bad_gears])
        @throttler.instance_eval{
          @old_bad_gears = old
        }
        @throttler.expects(:find).with(state: :throttled).never
      else
        @throttler.expects(:find).with(state: :throttled).returns([throttled, {}])
      end
      @throttler.expects(:apply_action).with() do |h|
        @retval = h
      end

      @throttler.expects("uuids=").with(mock_apps.keys)
      @throttler.stubs(:running_apps).returns(mock_apps)

      yield @throttler if block_given?

      @throttler.throttle(mock_apps.keys)

      @retval
    end
  end
end
