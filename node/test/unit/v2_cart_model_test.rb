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
module OpenShift
  ;
end

require 'test_helper'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/cartridge'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'ostruct'
require 'test/unit'
require 'fileutils'
require 'mocha'

class V2CartModelTest < Test::Unit::TestCase

  GEAR_BASE_DIR = '/var/lib/openshift'

  def setup
    # Set up the config
    @config = mock('OpenShift::Config')
    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)

    OpenShift::Utils::Sdk.stubs(:new_sdk_app?).returns(true)

    script_dir     = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

    OpenShift::Config.stubs(:new).returns(@config)

    # Set up the container
    @gear_uuid = "501"
    @user_uid  = "501"
    @app_name  = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"
    @homedir   = "#{GEAR_BASE_DIR}/#{@gear_uuid}"


    @user = OpenStruct.new(
        uuid:           @gear_uuid,
        uid:            @user_uid,
        container_uuid: @user_uuid,
        container_name: @gear_name,
        namespace:      @namespace,
        homedir:        "#{GEAR_BASE_DIR}/#{@gear_uuid}"

    )

    @model = OpenShift::V2CartridgeModel.new(@config, @user, mock())

    @mock_manifest = %q{#
        Name: mock
        Cartridge-Short-Name: MOCK
        Cartridge-Version: 1.0
        Cartridge-Vendor: Unit Test
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
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT1
            Private-Port:      8080
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT1
            Mappings:
              - Frontend:      "/front1a"
                Backend:       "/back1a"
                Options:       { websocket: true, tohttps: true }
              - Frontend:      "/front1b"
                Backend:       "/back1b"
                Options:       { noproxy: true }
          
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT2
            Private-Port:      8081
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT2
            Mappings:
              - Frontend:      "/front2"
                Backend:       "/back2"
                Options:       { file: true }
          
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT3
            Private-Port:      8082
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT3
            Mappings:
              - Frontend:      "/front3"
                Backend:       "/back3"
          
          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT4
            Private-Port:      9090
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT4
            Mappings:
              - Frontend:      "/front4"
                Backend:       "/back4"
  
          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT5
            Private-Port:      9091
    }

    manifest = "/tmp/manifest-#{Process.pid}"
    IO.write(manifest, @mock_manifest, 0)
    @mock_cartridge = OpenShift::Runtime::Cartridge.new(manifest, '/tmp')
    @model.stubs(:get_cartridge).with('mock-0.1').returns(@mock_cartridge)
  end

  def teardown
    @user.unstub(:homedir)
  end

  def test_get_cartridge_valid_manifest
    local_model = OpenShift::V2CartridgeModel.new(@config, @user, mock())

    manifest_path = "#{@homedir}/unittest-mock/metadata/manifest.yml"
    YAML.stubs(:load_file).with(manifest_path).returns(YAML.load(@mock_manifest))
    Dir.stubs(:glob).returns(["#{@homedir}/unittest-mock"])
    File.stubs(:exist?).with(manifest_path).returns(true)


    cart = local_model.get_cartridge("mock-0.1")

    assert_equal "mock", cart.name
    assert_equal "MOCK", cart.short_name
    assert_equal 5, cart.endpoints.length

    # Exercise caching
    cart = local_model.get_cartridge("mock-0.1")

    assert_equal "mock", cart.name
    assert_equal "MOCK", cart.short_name
    assert_equal 5, cart.endpoints.length
  end

  def test_get_cartridge_error_loading
    local_model = OpenShift::V2CartridgeModel.new(@config, @user, mock())

    YAML.stubs(:load_file).with("#{@homedir}/redhat-CRTest/metadata/manifest.yml").raises(ArgumentError.new('bla'))

    assert_raise(RuntimeError, "Failed to load cart manifest from #{@homedir}/redhat-CRTest/metadata/manifest.yml for cart mock in gear : bla") do
      local_model.get_cartridge("mock-0.1")
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

    @model.create_private_endpoints(@mock_cartridge)
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

    @model.delete_private_endpoints(@mock_cartridge)
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

  def test_frontend_connect_success
    OpenShift::Utils::Environ.stubs(:for_gear).returns({
        "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
        "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
    })

    frontend = mock('OpenShift::FrontendHttpServer')
    OpenShift::FrontendHttpServer.stubs(:new).returns(frontend)

    frontend.expects(:connect).with("/front1a", "127.0.0.1:8080/back1a", { "websocket" => true, "tohttps" => true })
    frontend.expects(:connect).with("/front1b", "127.0.0.1:8080/back1b", { "noproxy" => true })
    frontend.expects(:connect).with("/front2", "127.0.0.1:8081/back2", { "file" => true })
    frontend.expects(:connect).with("/front3", "127.0.0.1:8082/back3", {})
    frontend.expects(:connect).with("/front4", "127.0.0.2:9090/back4", {})

    @model.connect_frontend(@mock_cartridge)
  end
end
