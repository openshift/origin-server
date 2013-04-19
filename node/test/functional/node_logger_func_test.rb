#--
# Copyright 2013 Red Hat, Inc.
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

module OpenShift
  class LoggerTest
    include NodeLogger

    def write_log(message)
      logger.debug(message)
    end

    def write_trace(message)
      trace_logger.info(message)
    end
  end
end

class NodeLoggerFunctionalTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_standard
    skip "unit tests have the log files redirected"

    msg = "This is a Unit Test Message: #{Process.pid}"
    OpenShift::LoggerTest.new.write_log(msg)
    %x[grep "#{msg}" /var/log/openshift/node/platform.log]
    assert_equal 0, $?.exitstatus, 'Test message not found in platform.log'
  end

  def test_trace
    skip "unit tests have the log files redirected"

    msg = "This is a trace test: #{Process.pid}"
    OpenShift::LoggerTest.new.write_trace(msg)
    %x[grep "#{msg}" /var/log/openshift/node/platform-trace.log]
    assert_equal 0, $?.exitstatus, 'Test message not found in platform-trace.log'
  end
end