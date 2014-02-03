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
require_relative '../../../node-util/conf/watchman/plugins.d/syslog_plugin'

class SyslogPluginTest < OpenShift::NodeBareTestCase
  def setup
    Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

    @logs = '/tmp/syslog_plugin_test.log'
  end

  def teardown
    FileUtils.rm_f(@logs)
  end

  def test_no_gears
    teardown

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, [], restart, DateTime.now, @logs).apply

    assert_equal 0, counter, 'Failed to handle missing file'
  end

  def test_no_log
    teardown

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, DateTime.now, @logs).apply

    assert_equal 0, counter, 'Failed to handle missing file'
  end

  def test_empty_log
    File.open(@logs, 'w') do |file|
      file.write('')
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, DateTime.now, @logs).apply

    assert_equal 0, counter, 'Failed to process empty file'
  end

  def test_single_entry
    start_time = DateTime.civil(2014, 1, 1, 12, 0, 0, -6)
    File.open(@logs, 'w') do |file|
      file.write(
          "Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, start_time, @logs).apply

    assert_equal 1, counter, 'Failed to find single entry'
  end

  def test_floor
    start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
    File.open(@logs, 'w') do |file|
      file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
      file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, start_time, @logs).apply

    assert_equal 1, counter, 'Failed floor test'
  end

  def test_ceiling
    start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
    File.open(@logs, 'w') do |file|
      file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
      file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
      file.write("Jan 10 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000009 killed as a result of limit of .\n")
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, start_time, @logs).apply

    assert_equal 2, counter, 'Failed to find 2 entries'
  end

  def test_repeat
    start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
    File.open(@logs, 'w') do |file|
      file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
      file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
      file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
    end
    counter = 0
    restart = lambda { |u, t| counter += 1 }
    SyslogPlugin.new(nil, %w(52cc244091aa71fac4000008), restart, start_time, @logs).apply

    assert_equal 1, counter, 'Failed to compress repeats'
  end
end
