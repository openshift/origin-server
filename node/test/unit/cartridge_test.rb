#!/usr/bin/env oo-ruby
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
#
# Test the OpenShift application_container model
#
module OpenShift; end

require 'test_helper'
require 'openshift-origin-node/model/cartridge'
require 'test/unit'
require 'mocha'

class CartridgeTest < Test::Unit::TestCase
  def test_parse_valid_endpoints
    endpoint_strings = [ 
      "EXAMPLE_IP1:EXAMPLE_PORT1(8080):EXAMPLE_PUBLIC_PORT1",
      "EXAMPLE_IP1:EXAMPLE_PORT2(8081):EXAMPLE_PUBLIC_PORT2",
      "EXAMPLE_IP1:EXAMPLE_PORT3(8082):EXAMPLE_PUBLIC_PORT3",
      "EXAMPLE_IP2:EXAMPLE_PORT4(9090):EXAMPLE_PUBLIC_PORT4",
      "EXAMPLE_IP2:EXAMPLE_PORT5(9091)"
    ]

    endpoints = OpenShift::Runtime::Cartridge::Endpoint.parse_endpoints("EXAMPLE", endpoint_strings)

    assert_equal 5, endpoints.length
  end

  def test_parse_invalid_endpoints
    endpoint_strings = [
      {},
      nil,
      [],
      "1",
      "EXAMPLE_IP2:EXAMPLE_PORT4(9090):EXAMPLE_PUBLIC_PORT4"
    ]

    assert_raise(RuntimeError) do
      endpoints = OpenShift::Runtime::Cartridge::Endpoint.parse_endpoints("EXAMPLE", endpoint_strings)
    end
  end
end