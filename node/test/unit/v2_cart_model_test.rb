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
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/cartridge'
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

    OpenShift::Utils::Sdk.stubs(:new_sdk_app?).returns(true)

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

    @user = mock()
    @user.stubs(:uuid).returns(@user_uuid)
    @user.stubs(:uid).returns(@user_uid)

    @model = OpenShift::V2CartridgeModel.new(@config, @user)

    @mock_manifest = %q{#
        Name: mock
        Namespace: MOCK
        Display-Name: Mock
        Description: "A mock cartridge for development use only."
        Version: 0.1
        License: "None"
        Vendor: Red Hat
        Categories:
        - service
        Provides:
        - mock
        Scaling:
        Min: 1
        Max: -1
        Group-Overrides:
        - components:
        - mock
        Endpoints:
        - "EXAMPLE_IP1:EXAMPLE_PORT1(8080):EXAMPLE_PUBLIC_PORT1"
        - "EXAMPLE_IP1:EXAMPLE_PORT2(8081):EXAMPLE_PUBLIC_PORT2"
        - "EXAMPLE_IP1:EXAMPLE_PORT3(8082):EXAMPLE_PUBLIC_PORT3"
        - "EXAMPLE_IP2:EXAMPLE_PORT4(9090):EXAMPLE_PUBLIC_PORT4"
        - "EXAMPLE_IP2:EXAMPLE_PORT5(9091)"
    }

    @mock_cartridge = OpenShift::Runtime::Cartridge.new(YAML.load(@mock_manifest))
    @model.stubs(:get_cartridge).with("mock").returns(@mock_cartridge)
  end

  def test_get_cartridge_valid_manifest
    local_model = OpenShift::V2CartridgeModel.new(@config, @user)
    YAML.stubs(:load_file).with(any_parameters).returns(YAML.load(@mock_manifest))
    cart = local_model.get_cartridge("mock")

    assert_equal "mock", cart.name
    assert_equal "MOCK", cart.namespace
    assert_equal 5, cart.endpoints.length
  end

  def test_get_system_cartridge_path
    scenarios = { 
      'mock' => '/path/v2/mock',
      'mock-0.0' => '/path/v2/mock',
      'mock-plugin' => '/path/v2/mock-plugin',
      'mock-plugin-0.0' => '/path/v2/mock-plugin',
      'mock-' => '/path/v2/mock-',
      'mock--' => '/path/v2/mock--',
      'mock--0.0' => '/path/v2/mock-',
      'mock-0.0-' => '/path/v2/mock-0.0-'
    }

    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns('/path')

    scenarios.each do |cart_name, expected_path|
      res = @model.get_system_cartridge_path(cart_name)
      assert_equal expected_path, res
    end
  end

  def test_get_cartridge_version_argument
    scenarios = {
      'mock' => nil,
      'mock-0.0' => '0.0',
      'mock-plugin' => nil,
      'mock-plugin-0.0' => '0.0',
      'mock-plugin-' => nil,
      'mock-plugin--0.0' => '0.0',
      'mock-plugin-0.0-' => nil
    }

    scenarios.each do |cart_name, expected_version|
      res = @model.get_cartridge_version_argument(cart_name)
      assert_equal expected_version, res
    end
  end

  def test_private_endpoint_create
    ip1 = "127.0.250.1"
    ip2 = "127.0.250.2"

    @model.expects(:find_open_ip).with(8080).returns(ip1)
    @model.expects(:find_open_ip).with(9090).returns(ip2)

    @model.expects(:address_bound?).returns(false).times(5)

    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1", ip1)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1", 8080)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2", 8081)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3", 8082)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2", ip2)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4", 9090)
    @user.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT5", 9091)

    @model.create_private_endpoints("mock")
  end

  def test_private_endpoint_delete
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2")
    @user.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT5")

    @model.delete_private_endpoints("mock")
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

  # Flow control for destroy success - cartridge_teardown called for each method
  # and unix user destroyed.
  def test_destroy_success
    @model.expects(:process_cartridges).multiple_yields(%w(/var/lib/openshift/0001000100010001/cartridge1),
                                                        %w(/var/lib/openshift/0001000100010001/cartridge2))
    @model.expects(:cartridge_teardown).with('cartridge1').returns("")
    @model.expects(:cartridge_teardown).with('cartridge2').returns("")
    @user.expects(:destroy)

    @model.destroy
  end

  # Flow control for destroy when teardown raises an error.
  # Verifies that all teardown hooks are called, even if one raises an error,
  # and that unix user is still destroyed.
  def test_destroy_teardown_raises
    @model.expects(:process_cartridges).multiple_yields(%w(/var/lib/openshift/0001000100010001/cartridge1),
                                                        %w(/var/lib/openshift/0001000100010001/cartridge2))
    @model.expects(:cartridge_teardown).with('cartridge1').raises(OpenShift::Utils::ShellExecutionException.new('error'))
    @model.expects(:cartridge_teardown).with('cartridge2').returns("")
    @user.expects(:destroy)

    @model.destroy
  end

  # Flow control for unlock_gear success - block is yielded to
  # with cartridge name, do_unlock_gear and do_lock_gear bound the call.
  def test_unlock_gear_success
    @model.expects(:lock_files).with('mock-0.1').returns(%w(file1 file2 file3))
    @model.expects(:do_unlock).with(%w(file1 file2 file3))
    @model.expects(:do_lock).with(%w(file1 file2 file3))

    params = []
    @model.unlock_gear('mock-0.1') { |cart_name| params << cart_name }

    assert_equal 1, params.size
    assert_equal 'mock-0.1', params[0]
  end

  # Flow control for unlock gear failure - do_lock_gear is called
  # even when the block raises and exception.  Exception bubbles
  # out to caller.
  def test_unlock_gear_block_raises
    @model.expects(:lock_files).with('mock-0.1').returns(%w(file1 file2 file3))
    @model.expects(:do_unlock).with(%w(file1 file2 file3))
    @model.expects(:do_lock).with(%w(file1 file2 file3))

    assert_raise OpenShift::Utils::ShellExecutionException do
      @model.unlock_gear('mock-0.1') { raise OpenShift::Utils::ShellExecutionException.new('error') }
    end
  end
end
