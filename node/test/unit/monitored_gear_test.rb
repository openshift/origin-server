#!/usr/bin/env oo-ruby

require_relative '../test_helper'
require_relative '../../../node-util/conf/watchman/plugins.d/monitored_gear'

# This will sanity test some Array math helpers
class ArrayTest < OpenShift::NodeTestCase
  def test_average
    x = [1, 2, 3]

    assert_equal 2, x.average
  end

  def test_average_zero
    x = []

    assert_equal 0, x.average
  end

  def test_divide_array
    x = [10, 20, 30, 50]
    y = [2, 4, 3, 20]

    correct = [5.0, 5.0, 10.0, 2.5]

    assert_equal correct, x.divide(y)
  end

  def test_divide_zero
    x = [10, 20, 30, 50]
    y = 0

    correct = [0, 0, 0, 0]

    assert_equal correct, x.divide(y)
  end

  def test_divide_const
    x = [10, 20, 30, 50]
    y = 5

    correct = [2, 4, 6, 10]

    assert_equal correct, x.divide(y)
  end

  def test_mult_array
    x = [1, 2, 3, 5]
    y = [2, 4, 3, 20]

    correct = [2, 8, 9, 100]

    assert_equal correct, x.mult(y)
  end

  def test_mult_const
    x = [1, 2, 3, 5]
    y = 5

    correct = [5, 10, 15, 25]

    assert_equal correct, x.mult(y)
  end
end

# This will allow us to clear module variables on every run
class OpenShift::Runtime::Utils::Cgroups::MonitoredGear
  class << self
    def __clear
      @@intervals = [10.seconds, 30.seconds]
      @@delay     = nil
      @@max       = nil
      @@_delay    = nil
    end
  end
end

class MonitoredGearInstanceTest < OpenShift::NodeTestCase
  def setup
    @@impl = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@impl.__clear
  end

  def test_max
    @@impl.expects(:delay).once.returns(10)
    @@impl.expects(:intervals).once.returns([50, 100])

    # Max should be (intervals.max + (delay * 2))
    assert_equal 120, @@impl.max
  end

  def test_delay
    @@impl.expects(:intervals).once.returns([50, 100])

    # Delay should be (intervals.min / 4)
    assert_equal 12.5, @@impl.delay
  end

  def test_min_delay
    @@impl.expects(:intervals).once.returns([1])

    assert_equal @@impl::MIN_DELAY, @@impl.delay
  end

  def test_explicit_delay
    # Set the interval to something unreasonable
    @@impl.intervals = [Math::PI]
    # Delay values should be nil
    assert_nil @@impl.class_eval('@@delay')
    assert_nil @@impl.class_eval('@@_delay')

    # This should use the explicit value
    @@impl.delay = 10
    @@impl.expects(:intervals).never
    assert_equal 10, @@impl.delay
  end

  def test_module_variable_caching
    # Each call to should hit intervals
    @@impl.expects(:intervals).twice.returns([10, 30])
    @@impl.delay
    @@impl.max

    # The values should be cached
    @@impl.expects(:intervals).never
    @@impl.delay
    @@impl.max

    # This should clear the values
    @@impl.intervals = [10]
    assert_nil @@impl.class_eval('@@max')
    assert_nil @@impl.class_eval('@@delay')
  end
end

class MonitoredGearTest < OpenShift::NodeTestCase
  def setup
    @@impl = OpenShift::Runtime::Utils::Cgroups::MonitoredGear
    @@impl.__clear
    @uuid = 1234
    @gear = @@impl.new(@uuid)
  end

  def test_collapse_hashes
    hash = [
        {
            'foo' => 'foo_a',
            'bar' => 'bar_a',
            'baz' => 'baz_a'
        },
        {
            'foo'  => 'foo_b',
            'bar'  => 'bar_b',
            'zing' => 'zing_b'
        }
    ]

    correct = {
        'foo'  => %w(foo_a foo_b),
        'bar'  => %w(bar_a bar_b),
        'baz'  => %w(baz_a),
        'zing' => %w(zing_b)
    }
    assert_equal correct, @gear.collapse_hashes(hash)
  end

  def test_calculate_difference
    hash = {
        'a' => [1, 2, 3, 4, 5],
        'b' => [0, 0, 0, 0, 0],
        'c' => [1, 3, 5, 7, 10]
    }

    correct = {
        'a' => [1, 1, 1, 1],
        'b' => [0, 0, 0, 0],
        'c' => [2, 2, 2, 3]
    }

    assert_equal correct, @gear.calculate_differences(hash)
  end

  def test_value_storage
    assert_empty @gear.times
    val_1 = {'foo' => 1}
    val_2 = {'foo' => 2}
    val_3 = {'foo' => 3}
    val_4 = {'foo' => 4}

    max = @@impl.max

    times = [
        0,
        max - 1,
        max + 1,
        max + 100000
    ].map { |x| Time.at(x) }

    # The first update should only include that value
    with_time(times[0]) do |now|
      @gear.update(val_1)
      assert_equal [val_1], @gear.times.values
      assert_equal @gear.oldest, now
      assert_equal @gear.newest, now
    end

    # The second update should include both values
    with_time(times[1]) do |now|
      @gear.update(val_2)
      assert_equal [val_1, val_2], @gear.times.values
      assert_equal @gear.oldest, times[0]
      assert_equal @gear.newest, now
    end

    # After the max, this should drop the first value
    with_time(times[2]) do |now|
      @gear.update(val_3)
      assert_equal [val_2, val_3], @gear.times.values
      assert_equal @gear.oldest, times[1]
      assert_equal @gear.newest, now
    end

    # The last update should be so far in advance that it is the only value
    with_time(times[3]) do |now|
      @gear.update(val_4)
      assert_equal [val_4], @gear.times.values
      assert_equal @gear.oldest, now
      assert_equal @gear.newest, now
    end
  end

  def test_age
    @@impl.stubs(:max).returns(10)
    with_time(0) do
      @gear.update({})
    end

    with_time(10) do
      @gear.update({})
      assert_equal 10, @gear.age
    end

    # Not entirely realistic, but this shows that the values are rotated properly
    with_time(11) do
      @gear.update({})
      assert_equal 1, @gear.age
    end
  ensure
    @@impl.unstub(:max)
  end

  def test_utilization
    values = [
        {
            'cfs_quota_us'  => 100000,
            'cfs_period_us' => 100000,
            'nr_periods'    => 0,
            'ts'            => 1234567890.000000,
            'foo'           => 0
        },
        {
            'cfs_quota_us'  => 100000,
            'cfs_period_us' => 100000,
            'nr_periods'    => 1,
            'ts'            => 1234567891.000000,
            'foo'           => 1000000
        },
    ]

    correct = {
        'foo'            => 1000000,
        'foo_per_period' => 1000000.0,
        'foo_percent'    => 0.1
    }

    check_elapsed_usage(values, correct)
  end

  def test_utilization_2
    values = [
        {
            'cfs_quota_us'  => 1000,
            'cfs_period_us' => 1000,
            'nr_periods'    => 0,
            'ts'            => 1234567890.000000,
            'foo'           => 0
        },
        {
            'cfs_quota_us'  => 1000,
            'cfs_period_us' => 1000,
            'nr_periods'    => 1,
            'ts'            => 1234567891.000000,
            'foo'           => 1000000
        },
        {
            'cfs_quota_us'  => 2000,
            'cfs_period_us' => 1000,
            'nr_periods'    => 2,
            'ts'            => 1234567892.000000,
            'foo'           => 3000000
        },
    ]

    correct = {
        'foo'            => 1500000,
        'foo_per_period' => 1500000.0,
        'foo_percent'    => 0.1
    }

    check_elapsed_usage(values, correct)
  end

  def test_utilization_3
    values = [
        {
            'cfs_quota_us'  => 100000,
            'cfs_period_us' => 100000,
            'nr_periods'    => 0,
            'ts'            => 1234567890.0,
            'foo'           => 0
        },
        {
            'cfs_quota_us'  => 100000,
            'cfs_period_us' => 100000,
            'nr_periods'    => 7,
            'ts'            => 1234567897.0,
            'foo'           => 7000000
        },
    ]

    correct = {
        'foo'            => 7000000,
        'foo_per_period' => 1000000.0,
        'foo_percent'    => 0.1
    }

    check_elapsed_usage(values, correct)
  end

  def test_utilization_cache
    # Ensure update_utilization is cached
    @gear.expects(:update_utilization).once.returns({})
    2.times do
      @gear.utilization
    end

    @gear.expects(:update_utilization).once.returns({})
    # Updating the value should clear the cache and force an update
    @gear.update({})
    2.times do
      @gear.utilization
    end
  end

  def test_update_utilization
    @@impl.intervals = [10, 20]
    @@impl.delay     = 5

    # Since we don't have enough values, we should not have any stats
    with_values(5) do
      assert_empty @gear.update_utilization
    end

    # This should only return stats for the 10 second interval
    with_values(10) do
      assert_equal 1, @gear.update_utilization.length
    end

    # These should both return values for both intervals
    [20, 50].each do |i|
      with_values(i) do
        assert_equal 2, @gear.update_utilization.length
      end
    end
  end

  def check_elapsed_usage(hashes, expected)
    elapsed = @gear.elapsed_usage(hashes)
    assert_equal expected, elapsed
  end

  def with_values(max = @@impl.max, delay = @@impl.delay)
    defaults = {
        'cfs_quota_us'  => 10,
        'cfs_period_us' => 10,
        'nr_periods'    => 0,
        'ts'            => 1234567890.000000,
        'foo'           => 0
    }

    times = (0..max).step(@@impl.delay).inject({}) do |h, i|
      with_time(i) do |t|
        h[t] = defaults.merge({'nr_periods' => i, 'foo' => i * 10000, 'ts' => 1234567890.0 + i})
      end
      h
    end

    @gear.expects(:times).at_least(1).returns(times)
    yield
  end

  def with_time(t)
    Time.expects(:now).returns(t)
    yield t
  ensure
    Time.unstub(:now)
  end
end
