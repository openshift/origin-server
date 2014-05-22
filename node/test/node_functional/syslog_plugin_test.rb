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

if File.exist? '../../../node-util/conf/watchman/plugins.d/syslog_plugin.rb'

  require_relative '../../../node-util/conf/watchman/plugins.d/syslog_plugin'

  class SyslogPluginTest < OpenShift::NodeBareTestCase
    def setup
      Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?

      @logs    = '/tmp/syslog_plugin_test.log'
      @gears   = %w(52cc244091aa71fac4000007 52cc244091aa71fac4000008 52cc244091aa71fac4000009)
      @restart = mock
    end

    def teardown
      FileUtils.rm_f(@logs)
    end

    def test_no_gears
      teardown

      @restart.expects(:call).never
      SyslogPlugin.new(nil, nil, [], @restart, @logs).
          apply(OpenStruct.new({epoch: DateTime.now - 1.minute, last_run: DateTime.now}))
    end

    def test_no_log
      teardown

      @restart.expects(:call).never
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: DateTime.now - 1.minute, last_run: DateTime.now}))
    end

    def test_empty_log
      File.open(@logs, 'w') do |file|
        file.write('')
      end

      @restart.expects(:call).never
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: DateTime.now - 1.minute, last_run: DateTime.now}))
    end

    def test_single_entry
      start_time = DateTime.civil(2014, 1, 1, 12, 0, 0, -6)
      File.open(@logs, 'w') do |file|
        file.write(
            "Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
      end

      @restart.expects(:call).with(:restart, '52cc244091aa71fac4000007').once
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
    end

    def test_miss
      start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
      File.open(@logs, 'w') do |file|
        file.write(
            "Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
      end

      @restart.expects(:call).never
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
    end

    def test_floor
      start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
      File.open(@logs, 'w') do |file|
        file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
        file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
      end

      @restart.expects(:call).with(:restart, '52cc244091aa71fac4000008').once
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
    end

    def test_ceiling
      start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
      File.open(@logs, 'w') do |file|
        file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
        file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
        file.write("Jan 10 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000009 killed as a result of limit of .\n")
      end

      @restart.expects(:call).with(:restart, '52cc244091aa71fac4000008').once
      @restart.expects(:call).with(:restart, '52cc244091aa71fac4000009').once
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
    end

    def test_repeat
      start_time = DateTime.civil(2014, 1, 9, 12, 0, 0, -6)
      File.open(@logs, 'w') do |file|
        file.write("Jan  8 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000007 killed as a result of limit of .\n")
        file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
        file.write("Jan  9 18:18:25 ip-10-238-160-216 watchman[6020]:  52cc244091aa71fac4000008 killed as a result of limit of .\n")
      end

      @restart.expects(:call).with(:restart, '52cc244091aa71fac4000008').once
      SyslogPlugin.new(nil, nil, @gears, @restart, @logs).
          apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
    end
  end
end
