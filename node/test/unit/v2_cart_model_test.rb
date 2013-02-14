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
require 'openshift-origin-node/model/application_container'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'test/unit'
require 'fileutils'
require 'mocha'

class V2CartModelTest < Test::Unit::TestCase

  def setup
    # Set up the config
    @config = mock('OpenShift::Config')
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    OpenShift::Utils::Sdk.stubs(:is_new_sdk_app).returns(true)

    script_dir = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

    OpenShift::Config.stubs(:new).returns(@config)

    # Set up the container
    @gear_uuid = "501"
    @user_uid = "501"
    @app_name = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip = "127.0.0.1"

    @container = OpenShift::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil, nil)

    @model = OpenShift::V2CartridgeModel.new(@config, @container.user, @container, nil)
    @cart_name = "openshift-origin-cartridge-mock"
  end

  def test_private_endpoint_create
    ip1 = "127.0.250.1"
    ip2 = "127.0.250.2"

    @model.expects(:find_open_ip).with(8080).returns(ip1)
    @model.expects(:find_open_ip).with(9090).returns(ip2)

    @model.expects(:address_bound?).returns(false).times(4)

    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1", ip1)
    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1", 8080)
    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2", 8081)
    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3", 8082)
    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2", ip2)
    @container.user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4", 9090)
    
    @model.create_private_endpoints(@cart_name)
  end
 
  # Verifies that an IP can be allocated for a simple port binding request
  # where no other IPs are allocated to any carts in a gear.
  def test_find_open_ip_success
    @model.expects(:get_allocated_private_ips).returns([])
    @model.expects(:address_bound?).returns(false)

    assert_equal @model.find_open_ip(8080), "127.0.250.129"
  end

  # Ensures that a previously allocated IP within the gear won't be recycled
  # when a new allocation request is made.
  def test_find_open_ip_already_allocated
    @model.expects(:get_allocated_private_ips).returns(["127.0.250.129"])

    @model.expects(:address_bound?).returns(false)

    assert_equal @model.find_open_ip(8080), "127.0.250.130"
  end

  # Verifies that nil is returned from find_open_ip when all requested ports are
  # already bound on all possible IPs.
  def test_find_open_ip_all_previously_bound
    @model.expects(:get_allocated_private_ips).returns([])

    # Simulate an lsof call indicating the IP/port is already bound
    @model.expects(:address_bound?).returns(true).at_least_once

    assert_nil @model.find_open_ip(8080)
  end

  # Verifies that nil is returned from find_open_ip when all possible IPs
  # are already allocated to other endpoints.
  def test_find_open_ip_all_previously_allocated
    # Stub out a mock allocated IP array which will always tell the caller
    # that their input is included in the array. This simulates the case where
    # any IP the caller wants appears to be already allocated by other endpoints.
    allocated_array = mock()
    allocated_array.expects(:include?).returns(true).at_least_once

    @model.expects(:get_allocated_private_ips).returns(allocated_array)

    # Simulate an lsof call indicating the IP/port is available
    @model.expects(:address_bound?).never

    assert_nil @model.find_open_ip(8080)
  end
end
