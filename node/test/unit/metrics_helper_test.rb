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

MetricsHelper = ::OpenShift::Runtime::Utils::MetricsHelper

class MetricsHelperTest < OpenShift::NodeTestCase
  def test_defaults
    @config.stubs(:get).with("METRICS_METADATA").returns(nil)

    expected = {
      'appName' => 'OPENSHIFT_APP_NAME',
      'gear' => 'OPENSHIFT_GEAR_UUID',
      'app' => 'OPENSHIFT_APP_UUID',
      'ns' => 'OPENSHIFT_NAMESPACE'
    }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end

  def test_custom_one_entry
    line = "key1:VAR1"
    @config.stubs(:get).with("METRICS_METADATA").returns(line)

    expected = { 'key1' => 'VAR1' }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end

  def test_custom_one_entry_whitespace
    line = "     key1:    VAR1    "
    @config.stubs(:get).with("METRICS_METADATA").returns(line)

    expected = { 'key1' => 'VAR1' }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end

  def test_custom_multiple_entries
    line = "key1:VAR1,key2:VAR2,key3:VAR3"
    @config.stubs(:get).with("METRICS_METADATA").returns(line)

    expected = {
      'key1' => 'VAR1',
      'key2' => 'VAR2',
      'key3' => 'VAR3'
    }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end

  def test_custom_multiple_entries_whitespace
    line = "  key1: VAR1,  key2:VAR2,key3:   VAR3"
    @config.stubs(:get).with("METRICS_METADATA").returns(line)

    expected = {
      'key1' => 'VAR1',
      'key2' => 'VAR2',
      'key3' => 'VAR3'
    }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end

  def test_secret_token_excluded
    line = "key1:OPENSHIFT_SECRET_TOKEN,key2:VAR2,key3:VAR3"
    @config.stubs(:get).with("METRICS_METADATA").returns(line)

    expected = {
      'key2' => 'VAR2',
      'key3' => 'VAR3'
    }

    assert_equal expected, MetricsHelper.metrics_metadata(@config)
  end
end
