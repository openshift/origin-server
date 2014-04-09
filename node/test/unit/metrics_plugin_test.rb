#!/usr/bin/env oo-ruby
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
require_relative '../../../node-util/conf/watchman/plugins.d/metrics_plugin'

class MetricsPluginTest < OpenShift::NodeTestCase
  def setup
    @logger = mock()
    @gears = mock()
    @operation = mock()
  end

  def test_initialize_disabled
    [nil, 0, false, 'false', '0', 'TRUE', 'abc', 1, 123].each do |v|
      @config.stubs(:get).with('WATCHMAN_METRICS_ENABLED').returns(v)

      OpenShift::Runtime::WatchmanPlugin::Metrics.expects(:new).never
      plugin = MetricsPlugin.new(@config, @logger, @gears, @operation)

      assert plugin.disabled?
    end
  end

  def test_apply_disabled
    @config.stubs(:get).with('WATCHMAN_METRICS_ENABLED').returns(false)

    @gears.expects(:last_updated).never
    plugin = MetricsPlugin.new(@config, @logger, @gears, @operation)

    plugin.apply(nil)
  end

  def test_initialize_enabled
    @config.stubs(:get).with('WATCHMAN_METRICS_ENABLED').returns('true')
    Syslog.stubs(:open)
    Syslog.stubs(:info)
    metrics = mock()
    metrics.expects(:gears_updated).with(@gears)
    metrics.expects(:start)
    OpenShift::Runtime::WatchmanPlugin::Metrics.expects(:new).returns(metrics)
    plugin = MetricsPlugin.new(@config, @logger, @gears, @operation)
    refute plugin.disabled?
  end

  def test_apply_enabled_update_gears
    @config.stubs(:get).with('WATCHMAN_METRICS_ENABLED').returns('true')
    Syslog.stubs(:open)
    Syslog.stubs(:info)
    metrics = mock()
    metrics.expects(:gears_updated).with(@gears)
    metrics.expects(:start)
    OpenShift::Runtime::WatchmanPlugin::Metrics.expects(:new).returns(metrics)
    plugin = MetricsPlugin.new(@config, @logger, @gears, @operation)

    @gears.expects(:last_updated).returns(123).twice
    metrics.expects(:gears_updated).with(@gears).once
    plugin.apply(nil)

    # the 2nd call shouldn't call @metrics.gears_updated
    plugin.apply(nil)
  end
end

class SyslogLineShiperTest < OpenShift::NodeTestCase
  def test_output
    s = ::OpenShift::Runtime::WatchmanPlugin::SyslogLineShipper.new
    line = 'foo'
    Syslog.expects(:info).with(line)
    s << line
  end
end

class MetricsPluginMetricsTest < OpenShift::NodeTestCase
  def setup
    @config.stubs(:get).with('GEAR_BASE_DIR').returns('/var/lib/openshift')
  end

  def test_default_delay
    Syslog.stubs(:info)
    @config.stubs(:get).with('WATCHMAN_METRICS_INTERVAL').returns(nil)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal OpenShift::Runtime::WatchmanPlugin::Metrics::DEFAULT_INTERVAL, @metrics.delay
  end

  def test_custom_delay
    Syslog.stubs(:info)
    @config.stubs(:get).with('WATCHMAN_METRICS_INTERVAL').returns(123)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 123, @metrics.delay
  end

  def test_delay_too_small
    Syslog.stubs(:info)
    Syslog.stubs(:warning)
    @config.stubs(:get).with('WATCHMAN_METRICS_INTERVAL').returns(1)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 10, @metrics.delay
  end

  def test_gears_updated_adds_gears
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 0, @metrics.gear_metadata.count
    update = %w(uuid1 uuid2 uuid3)
    @metrics.gears_updated(update)
    assert_equal 3, @metrics.gear_metadata.count
    update.each { |uuid| assert_includes @metrics.gear_metadata, uuid }
  end

  def test_gears_updated_removes_stale_gears
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 0, @metrics.gear_metadata.count

    update = %w(uuid1 uuid2 uuid3)
    @metrics.gears_updated(update)

    assert_equal 3, @metrics.gear_metadata.count
    update.each { |uuid| assert_includes @metrics.gear_metadata, uuid }

    update = %w(uuid2)
    @metrics.gears_updated(update)
    assert_equal 1, @metrics.gear_metadata.count
    update.each { |uuid| assert_includes @metrics.gear_metadata, uuid }
  end

  def test_tick_no_gears
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    @metrics.expects(:get_gear_metrics).never
    @metrics.expects(:get_application_container_metrics).never
    @metrics.tick
  end

  def test_tick_gears
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    update = %w(uuid2)
    @metrics.gears_updated(update)
    @metrics.expects(:get_gear_metrics).once
    @metrics.expects(:get_application_container_metrics).once
    @metrics.tick
  end

  def test_tick_exception
    Syslog.expects(:info).with("Initializing Watchman metrics plugin")
    Syslog.expects(:info).with("Watchman metrics interval = 60s")
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    update = %w(uuid2)
    @metrics.gears_updated(update)
    @metrics.expects(:get_gear_metrics).raises('foo')
    @metrics.expects(:get_application_container_metrics).never
    Syslog.expects(:info).with(regexp_matches /^Metrics: unhandled exception foo/)
    @metrics.tick
  end

  def test_cgget_paths_one
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    update = %w(uuid1)
    @metrics.gears_updated(update)
    assert_equal '/openshift/uuid1', @metrics.cgget_paths
  end

  def test_cgget_paths_many
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    update = %w(uuid1 uuid2 uuid3)
    @metrics.gears_updated(update)
    assert_equal '/openshift/uuid1 /openshift/uuid2 /openshift/uuid3', @metrics.cgget_paths
  end

  def test_cgget_command_default
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 'cgget -a /openshift/uuid1', @metrics.cgget_command('/openshift/uuid1')
  end

  def test_cgget_command_custom
    Syslog.stubs(:info)
    @config.stubs(:get).with('CGROUPS_METRICS_KEYS').returns('cpu.stat, cpuacct.stat')
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    assert_equal 'cgget -r cpu.stat -r cpuacct.stat /openshift/uuid1', @metrics.cgget_command('/openshift/uuid1')
  end

  def test_get_cgroups_metrics
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    update = %w(uuid1)
    @metrics.gears_updated(update)
    OpenShift::Runtime::Utils.expects(:oo_spawn)
                             .with('cgget -a /openshift/uuid1',
                                   has_entries(out: instance_of(OpenShift::Runtime::WatchmanPlugin::CggetMetricsParser)))
    @metrics.get_cgroups_metrics
  end

  def test_gear_file_system
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)

    OpenShift::Runtime::Utils.expects(:oo_spawn)
                             .with("df -P /var/lib/openshift | tail -1 | cut -d ' ' -f 1",
                                   expected_exitstatus: 0)
                             .returns("/var\n")

    assert_equal '/var', @metrics.gear_file_system
  end

  def test_get_quota_metrics
    Syslog.stubs(:info)
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    @metrics.expects(:gear_file_system).returns('/var')

    OpenShift::Runtime::Utils.expects(:oo_spawn)
                             .with("repquota /var",
                                   has_entries(expected_exitstatus: 0,
                                               out: instance_of(OpenShift::Runtime::WatchmanPlugin::QuotaMetricsParser)))

    @metrics.get_quota_metrics
  end

  def test_publish
    Syslog.expects(:info).with("Initializing Watchman metrics plugin")
    Syslog.expects(:info).with("Watchman metrics interval = 60s")
    @config.stubs(:get).with('METRICS_METADATA').returns('app:OPENSHIFT_APP_NAME,gear:OPENSHIFT_GEAR_UUID')
    @metrics = OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    File.expects(:read).with('/var/lib/openshift/uuid1/.env/OPENSHIFT_APP_NAME').returns('appName')
    File.expects(:read).with('/var/lib/openshift/uuid1/.env/OPENSHIFT_GEAR_UUID').returns('uuid1')
    Syslog.expects(:info).with("type=metric app=appName gear=uuid1 key=value")
    @metrics.publish('uuid1', 'key=value')
  end
end

class CggetMetricsParserTest < OpenShift::NodeTestCase
  def test_append_one_gear
    config = mock()
    config.stubs(:get).with('MAX_CGROUPS_METRICS_MESSAGE_LENGTH').returns(1024)

    parent = mock()
    parent.expects(:config).returns(config)

    parser = OpenShift::Runtime::WatchmanPlugin::CggetMetricsParser.new(parent)

    output = 'cpu.rt_period_us=1000000 cpu.stat.nr_periods=6266 cpu.stat.nr_throttled=0 cpu.stat.throttled_time=0 cpuacct.usage_percpu.0=3180064217 cpuacct.usage_percpu.1=3240110361 cpuacct.usage=6420174578'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    input = <<EOF
/openshift/533c34e04b85e4913e000009:
cpu.rt_period_us: 1000000
cpu.stat: nr_periods 6266
	nr_throttled 0
	throttled_time 0
cpuacct.usage_percpu: 3180064217 3240110361
cpuacct.usage: 6420174578
EOF

    parser << input
  end

  def test_append_two_gears
    config = mock()
    config.stubs(:get).with('MAX_CGROUPS_METRICS_MESSAGE_LENGTH').returns(1024)

    parent = mock()
    parent.expects(:config).returns(config)

    parser = OpenShift::Runtime::WatchmanPlugin::CggetMetricsParser.new(parent)

    output = 'cpu.rt_period_us=1000000 cpu.stat.nr_periods=6266 cpu.stat.nr_throttled=0 cpu.stat.throttled_time=0 cpuacct.usage_percpu.0=3180064217 cpuacct.usage_percpu.1=3240110361 cpuacct.usage=6420174578'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    output2 = 'cpu.rt_period_us=1000000 cpu.stat.nr_periods=1234 cpu.stat.nr_throttled=1 cpu.stat.throttled_time=2 cpuacct.usage_percpu.0=1234 cpuacct.usage_percpu.1=4567 cpuacct.usage=7899'
    parent.expects(:publish).with('533c34e04b85e4913e000010', output2)

    input = <<EOF
/openshift/533c34e04b85e4913e000009:
cpu.rt_period_us: 1000000
cpu.stat: nr_periods 6266
	nr_throttled 0
	throttled_time 0
cpuacct.usage_percpu: 3180064217 3240110361
cpuacct.usage: 6420174578

/openshift/533c34e04b85e4913e000010:
cpu.rt_period_us: 1000000
cpu.stat: nr_periods 1234
	nr_throttled 1
	throttled_time 2
cpuacct.usage_percpu: 1234 4567
cpuacct.usage: 7899
EOF

    parser << input
  end

  def test_append_short_max_line_length
    config = mock()
    config.stubs(:get).with('MAX_CGROUPS_METRICS_MESSAGE_LENGTH').returns(100)

    parent = mock()
    parent.expects(:config).returns(config)

    parser = OpenShift::Runtime::WatchmanPlugin::CggetMetricsParser.new(parent)

    output = 'cpu.rt_period_us=1000000 cpu.stat.nr_periods=6266 cpu.stat.nr_throttled=0 cpu.stat.throttled_time=0'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    output = 'cpuacct.usage_percpu.0=3180064217 cpuacct.usage_percpu.1=3240110361 cpuacct.usage=6420174578'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    input = <<EOF
/openshift/533c34e04b85e4913e000009:
cpu.rt_period_us: 1000000
cpu.stat: nr_periods 6266
	nr_throttled 0
	throttled_time 0
cpuacct.usage_percpu: 3180064217 3240110361
cpuacct.usage: 6420174578
EOF

    parser << input
  end

  def test_append_partials
    config = mock()
    config.stubs(:get).with('MAX_CGROUPS_METRICS_MESSAGE_LENGTH').returns(100)

    parent = mock()
    parent.expects(:config).returns(config)

    parser = OpenShift::Runtime::WatchmanPlugin::CggetMetricsParser.new(parent)

    output = 'cpu.rt_period_us=1000000 cpu.stat.nr_periods=6266'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    output = 'cpu.stat.nr_throttled=0 cpu.stat.throttled_time=0 cpuacct.usage_percpu.0=3180064217'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    output = 'cpuacct.usage_percpu.1=3240110361 cpuacct.usage=6420174578'
    parent.expects(:publish).with('533c34e04b85e4913e000009', output)

    input = []
    input << '/openshift/533c34e04b'
    input << "85e4913e000009:\ncpu.rt_p"
    input << "eriod_us: 1000000"
    input << "\ncpu.stat: nr_periods 6266\n"
    input << "	nr_throt"
    input << <<EOF
tled 0
	throttled_time 0
cpuacct.usage_percpu: 3180064217 3240110361
cpuacct.usage: 6420174578
EOF

    input.each { |i| parser << i }
  end
end

class QuotaMetricsParserTest < OpenShift::NodeTestCase
  def test_append
    input = <<EOF
*** Report for user quotas on device /dev/mapper/VolGroup-lv_root
Block grace time: 7days; Inode grace time: 7days
                        Block limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      -- 4358824       0       0         203280     0     0
daemon    --       8       0       0              2     0     0
533364839023f0bdad00001d --    1044       0 1048576            255     0 40000
#501      --     924       0       0             73     0     0


EOF
    parent = mock()
    md = {'533364839023f0bdad00001d' => 1}
    parent.stubs(:gear_metadata).returns(md)

    parser = OpenShift::Runtime::WatchmanPlugin::QuotaMetricsParser.new(parent)

    output = 'quota.blocks.used=1044 quota.blocks.limit=1048576 quota.files.used=255 quota.files.limit=40000'
    parent.expects(:publish).with('533364839023f0bdad00001d', output)

    parser << input
  end

  def test_append_partials
    input = []
    input << <<EOF
*** Report for user quotas on device /dev/mapper/VolGroup-lv_root
Block grace time: 7days; Inode grace time: 7days
                        Block limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      -- 4358824       0       0         203280     0     0
daemon    --       8       0       0              2     0     0
533364839023
EOF
    input[0].chomp!

    input << <<EOF
f0bdad00001d --    1044       0 1048576            255     0 40000
#501      --     924       0       0             73     0     0


EOF
    parent = mock()
    md = {'533364839023f0bdad00001d' => 1}
    parent.stubs(:gear_metadata).returns(md)

    parser = OpenShift::Runtime::WatchmanPlugin::QuotaMetricsParser.new(parent)

    output = 'quota.blocks.used=1044 quota.blocks.limit=1048576 quota.files.used=255 quota.files.limit=40000'
    parent.expects(:publish).with('533364839023f0bdad00001d', output)

    input.each { |i| parser << i }
  end
end
