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
require_relative '../test_helper'
require 'ostruct'
require 'fileutils'

module OpenShift
  class V2CartModelTest < OpenShift::NodeTestCase

    GEAR_BASE_DIR = '/var/lib/openshift'

    def setup
      # Set up the config
      @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)

      script_dir     = File.expand_path(File.dirname(__FILE__))
      cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

      raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

      @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

      # Set up the container
      @gear_uuid = "5501"
      @user_uid  = "5501"
      @app_name  = 'ApplicationContainerTestCase'
      @gear_name = @app_name
      @namespace = 'jwh201204301647'
      @gear_ip   = "127.0.0.1"
      @homedir   = "#{GEAR_BASE_DIR}/#{@gear_uuid}"

      Etc.stubs(:getpwnam).returns(
        OpenStruct.new(
          uid: @user_uid.to_i,
          gid: @user_uid.to_i,
          gecos: "OpenShift guest",
          dir: @homedir
        )
      )

      @container = Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
                                                                @app_name, @gear_uuid, @namespace, nil, nil, nil)

      @hourglass = mock()
      @hourglass.stubs(:remaining).returns(3600)

      @model = Runtime::V2CartridgeModel.new(@config, @container, mock(), @hourglass)

      @mock_manifest = %q{#
        Name: mock
        Cartridge-Short-Name: MOCK
        Cartridge-Version: 1.0
        Cartridge-Vendor: unit_test
        Display-Name: Mock
        Description: "A mock cartridge for development use only."
        Version: '0.1'
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
            Protocols:         ["http", "https", "ws", "wss"]
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
            Protocols:         ["http"]
            Mappings:
              - Frontend:      "/front2"
                Backend:       "/back2"
                Options:       { file: true }

          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT3
            Private-Port:      8082
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT3
            Protocols:         ["http"]
            Mappings:
              - Frontend:      "/front3"
                Backend:       "/back3"

          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT4
            Private-Port:      9090
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT4
            Protocols:         ["http"]
            Mappings:
              - Frontend:      "/front4"
                Backend:       "/back4"

          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT5
            Private-Port:      9091
    }

      manifest = Tempfile.new("manifest-#{Process.pid}")
      IO.write(manifest, @mock_manifest, 0)
      @mock_cartridge = Runtime::Manifest.new(manifest, nil, :file, '/tmp')
      @model.stubs(:get_cartridge).with('mock-0.1').returns(@mock_cartridge)
    end

    def teardown
      @container.unstub(:container_dir)
    end

    def test_get_cartridge_error_loading
      hourglass = mock()
      hourglass.stubs(:remaining).returns(3600)

      local_model = Runtime::V2CartridgeModel.new(@config, @container, mock(), hourglass)

      YAML.stubs(:safe_load_file).with("#{@homedir}/redhat-crtest/metadata/manifest.yml").raises(ArgumentError.new('bla'))

      assert_raise(RuntimeError, "Failed to load cart manifest from #{@homedir}/redhat-crtest/metadata/manifest.yml for cart mock in gear : bla") do
        local_model.get_cartridge("mock-0.1")
      end
    end

    def test_process_erb_templates_success
      cartridge = mock()
      cartridge.stubs(:name).returns('cartridge')

      @container.stubs(:container_dir).returns("/foo")
      env = mock()

      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, '/foo/cartridge').returns(env)
      @container.expects(:processed_templates).with(cartridge).returns(%w(a b c))
      File.expects(:exists?).with('/foo/a').returns(true)
      File.expects(:exists?).with('/foo/b').returns(true)
      File.expects(:exists?).with('/foo/c').returns(true)

      @model.expects(:render_erbs).with(env, %w(/foo/a /foo/b /foo/c))

      result = @model.process_erb_templates(cartridge)

      assert_equal '', result
    end

    def test_process_erb_templates_file_dne
      cartridge = mock()
      cartridge.stubs(:name).returns('cartridge')

      @container.stubs(:container_dir).returns("/foo")
      env = mock()

      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, '/foo/cartridge').returns(env)
      @container.expects(:processed_templates).with(cartridge).returns(%w(a b c))
      File.expects(:exists?).with('/foo/a').returns(true)
      File.expects(:exists?).with('/foo/b').returns(true)
      File.expects(:exists?).with('/foo/c').returns(false)

      @model.expects(:render_erbs).with(env, %w(/foo/a /foo/b))

      result = @model.process_erb_templates(cartridge)

      assert_match /CLIENT_ERROR/, result
    end

    def test_private_endpoint_create
      ip1 = "127.0.250.1"
      ip2 = "127.0.250.2"

      @model.expects(:find_open_ip).with(8080).returns(ip1)
      @model.expects(:find_open_ip).with(9090).returns(ip2)

      @container.expects(:addresses_bound?).returns(false)

      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns({})

      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1", ip1)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1", 8080)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2", 8081)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3", 8082)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2", ip2)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4", 9090)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT5", 9091)

      @model.create_private_endpoints(@mock_cartridge)
    end

    def test_private_endpoint_recreate
      ip1 = "127.0.250.1"
      ip2 = "127.0.250.2"

      @model.expects(:find_open_ip).with(8080).returns(ip1)
      @model.expects(:find_open_ip).with(9090).returns(ip2)

      env = {
        "OPENSHIFT_MOCK_EXAMPLE_PORT5" => '3'
      }

      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)

      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1", ip1)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1", 8080)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2", 8081)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3", 8082)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2", ip2)
      @container.expects(:add_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4", 9090)

      @container.expects(:addresses_bound?).with(responds_with(:size, 4), anything).returns(false)

      @model.create_private_endpoints(@mock_cartridge)
    end

    def test_private_endpoint_create_empty_endpoints
      @container.expects(:add_env_var).never
      @model.expects(:find_open_ip).never
      @container.expects(:address_bound?).never
      @container.expects(:addresses_bound?).never

      cart = mock()
      cart.stubs(:directory).returns("/nowhere")
      cart.stubs(:endpoints).returns([])

      @model.create_private_endpoints(cart)
    end

    def test_private_endpoint_create_binding_failure
      ip1 = "127.0.250.1"
      ip2 = "127.0.250.2"

      @model.expects(:find_open_ip).with(8080).returns(ip1)
      @model.expects(:find_open_ip).with(9090).returns(ip2)

      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns({})

      @container.expects(:add_env_var).times(7)

      @container.expects(:addresses_bound?).returns(true)
      @container.expects(:address_bound?).returns(true).times(5)

      assert_raise(RuntimeError) do
        @model.create_private_endpoints(@mock_cartridge)
      end
    end

    def test_private_endpoint_delete
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT1")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT2")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP1")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT3")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT4")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_IP2")
      @container.expects(:remove_env_var).with("OPENSHIFT_MOCK_EXAMPLE_PORT5")

      @model.delete_private_endpoints(@mock_cartridge)
    end

    # Verifies that an IP can be allocated for a simple port binding request
    # where no other IPs are allocated to any carts in a gear.
    def test_find_open_ip_success
      @model.expects(:get_allocated_private_ips).returns([])

      assert_equal "127.10.190.129", @model.find_open_ip(8080)
    end

    # Ensures that a previously allocated IP within the gear won't be recycled
    # when a new allocation request is made.
    def test_find_open_ip_already_allocated
      @model.expects(:get_allocated_private_ips).returns(["127.10.190.129"])

      assert_equal "127.10.190.130", @model.find_open_ip(8080)
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

      assert_nil @model.find_open_ip(8080)
    end

    # Flow control for destroy success - cartridge_teardown called for each method
    # and unix user destroyed.
    def test_destroy_success
      c1 = mock('Runtime::Manifest')
      c1.stubs(:directory).returns("cartridge1")

      c2 = mock('Runtime::Manifest')
      c2.stubs(:directory).returns("cartridge2")

      @model.expects(:each_cartridge).multiple_yields(c1,c2)
      @model.expects(:unlock_gear).with(c1, false).yields(c1)
      @model.expects(:unlock_gear).with(c2, false).yields(c2)

      @model.expects(:cartridge_teardown).with(c1.directory, false).returns("")
      @model.expects(:cartridge_teardown).with(c2.directory, false).returns("")

      Dir.stubs(:chdir).with(GEAR_BASE_DIR).yields

      @model.destroy
    end

    # Flow control for destroy when teardown raises an error.
    # Verifies that all teardown hooks are called, even if one raises an error,
    # and that unix user is still destroyed.
    def test_destroy_teardown_raises
      c1 = mock('Runtime::Manifest')
      c1.stubs(:directory).returns("cartridge1")

      c2 = mock('Runtime::Manifest')
      c2.stubs(:directory).returns("cartridge2")

      @model.expects(:each_cartridge).multiple_yields(c1,c2)
      @model.expects(:unlock_gear).with(c1, false).yields(c1)
      @model.expects(:unlock_gear).with(c2, false).yields(c2)

      @model.expects(:cartridge_teardown).with(c1.directory, false).raises(Runtime::Utils::ShellExecutionException.new('error'))
      @model.expects(:cartridge_teardown).with(c2.directory, false).returns("")

      Dir.stubs(:chdir).with(GEAR_BASE_DIR).yields

      @model.destroy
    end

    # Flow control for destroy without running hooks
    # Verifies that none of the teardown hooks are called but the user is destroyed
    def test_destroy_skip_hooks
      @model.expects(:each_cartridge).never

      @model.expects(:unlock_gear).never
      @model.expects(:cartridge_teardown).never

      Dir.stubs(:chdir).with(GEAR_BASE_DIR).yields

      @model.destroy(true)
    end

    # Flow control for unlock_gear success - block is yielded to
    # with cartridge name, do_unlock_gear and do_lock_gear bound the call.
    def test_unlock_gear_success
      @container.expects(:locked_files).with('mock-0.1').returns(%w(file1 file2 file3)).at_least_once
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
      @container.expects(:locked_files).with('mock-0.1').returns(%w(file1 file2 file3)).at_least_once
      @model.expects(:do_unlock).with(%w(file1 file2 file3))
      @model.expects(:do_lock).with(%w(file1 file2 file3))

      assert_raise Runtime::Utils::ShellExecutionException do
        @model.unlock_gear('mock-0.1') { raise Runtime::Utils::ShellExecutionException.new('error') }
      end
    end

    def test_frontend_connect_success
      Runtime::Utils::Environ.stubs(:for_gear).returns({
                                                             "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
                                                             "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
                                                         })

      frontend = mock('Runtime::FrontendHttpServer')
      Runtime::FrontendHttpServer.stubs(:new).returns(frontend)

      frontend.expects(:connect).with("/front1a", "127.0.0.1:8080/back1a", {"websocket" => true, "tohttps" => true, "protocols" => ['http', 'https', 'ws', 'wss']})
      frontend.expects(:connect).with("/front1b", "127.0.0.1:8080/back1b", {"noproxy" => true, "protocols" => ['http', 'https', 'ws', 'wss']})
      frontend.expects(:connect).with("/front2", "127.0.0.1:8081/back2", {"file" => true, "protocols" => ['http']})
      frontend.expects(:connect).with("/front3", "127.0.0.1:8082/back3", {"protocols" => ['http']})
      frontend.expects(:connect).with("/front4", "127.0.0.2:9090/back4", {"protocols" => ['http']})

      @model.connect_frontend(@mock_cartridge)
    end

    def mawk
      m = mock()
      yield m
      m
    end

    def test_frontend_connect_default_mapping_web_proxy_conflict
      Runtime::Utils::Environ.stubs(:for_gear).returns({
        "private_ip" => "127.0.0.1",
        "proxy_private_ip" => "127.0.0.2"
      })

      frontend = mock('Runtime::FrontendHttpServer')
      Runtime::FrontendHttpServer.stubs(:new).returns(frontend)

      cartridge = mock()
      cartridge.stubs(:web_proxy?).returns(false)

      cartridge.stubs(:endpoints).returns([mawk {|e|
        e.stubs(:websocket_port).returns(nil)
        e.stubs(:private_ip_name).returns("private_ip")
        e.stubs(:private_port).returns(8080)
        e.stubs(:protocols).returns(["http"])
        e.stubs(:mappings).returns([mawk {|m|
          m.stubs(:frontend).returns("")
          m.stubs(:backend).returns("/backend")
          m.stubs(:options).returns({})
        }])
      }])

      proxy_cart = mock()
      proxy_cart.stubs(:web_proxy?).returns(true)

      proxy_cart.stubs(:endpoints).returns([mawk {|e|
        e.stubs(:websocket_port).returns(nil)
        e.stubs(:private_ip_name).returns("proxy_private_ip")
        e.stubs(:private_port).returns(8080)
        e.stubs(:protocols).returns(["http"])
        e.stubs(:mappings).returns([mawk {|m|
          m.stubs(:frontend).returns("")
          m.stubs(:backend).returns("/backend")
          m.stubs(:options).returns({})
        }])
      }])

      @model.stubs(:web_proxy).returns(proxy_cart)

      frontend.expects(:connect).never

      @model.connect_frontend(cartridge)
    end

    def test_frontend_connect_default_mapping_primary_conflict
      Runtime::Utils::Environ.stubs(:for_gear).returns({
        "private_ip" => "127.0.0.1",
        "embedded_private_ip" => "127.0.0.2"
      })

      frontend = mock('Runtime::FrontendHttpServer')
      Runtime::FrontendHttpServer.stubs(:new).returns(frontend)

      primary_cart = mock()
      primary_cart.stubs(:web_proxy?).returns(false)
      primary_cart.stubs(:name).returns("primary-cart")

      primary_cart.stubs(:endpoints).returns([mawk {|e|
        e.stubs(:websocket_port).returns(nil)
        e.stubs(:private_ip_name).returns("private_ip")
        e.stubs(:private_port).returns(8080)
        e.stubs(:protocols).returns(["http"])
        e.stubs(:mappings).returns([mawk {|m|
          m.stubs(:frontend).returns("")
          m.stubs(:backend).returns("/backend")
          m.stubs(:options).returns({})
        }])
      }])

      embeddable_cart = mock()
      embeddable_cart.stubs(:web_proxy?).returns(false)
      embeddable_cart.stubs(:name).returns("embeddable-cart")

      embeddable_cart.stubs(:endpoints).returns([mawk {|e|
        e.stubs(:websocket_port).returns(nil)
        e.stubs(:private_ip_name).returns("embedded_private_ip")
        e.stubs(:private_port).returns(8080)
        e.stubs(:protocols).returns(["http"])
        e.stubs(:mappings).returns([mawk {|m|
          m.stubs(:frontend).returns("")
          m.stubs(:backend).returns("/backend")
          m.stubs(:options).returns({})
        }])
      }])

      @model.stubs(:web_proxy).returns(nil)
      @model.stubs(:primary_cartridge).returns(primary_cart)

      frontend.expects(:connect).never

      @model.connect_frontend(embeddable_cart)
    end

    def test_unlock_gear_no_relock
      cartridge = mock()
      files = %w(a b c)

      @container.expects(:locked_files).with(cartridge).returns(files).at_least_once
      @model.expects(:do_unlock).with(files)
      @model.expects(:do_lock).never

      @model.unlock_gear(cartridge, false) do |cartridge|

      end
    end

    def test_unlock_gear_relock
      cartridge = mock()
      files = %w(a b c)

      @container.expects(:locked_files).with(cartridge).returns(files).at_least_once
      @model.expects(:do_unlock).with(files)
      @model.expects(:do_lock).with(files)

      @model.unlock_gear(cartridge) do |cartridge|

      end
    end

    def test_unlock_gear_relock_block_raises
      cartridge = mock()
      files = %w(a b c)

      @container.expects(:locked_files).with(cartridge).returns(files).at_least_once
      @model.expects(:do_unlock).with(files)
      @model.expects(:do_lock).with(files)

      assert_raise RuntimeError do
        @model.unlock_gear(cartridge) do |cartridge|
          raise 'foo' 
        end
      end
    end

    def test_unlock_gear_no_relock_block_raises
      cartridge = mock()
      files = %w(a b c)

      @container.expects(:locked_files).with(cartridge).returns(files).at_least_once
      @model.expects(:do_unlock).with(files)
      @model.expects(:do_lock).never()

      assert_raise RuntimeError do
        @model.unlock_gear(cartridge, false) do |cartridge|
          raise 'foo' 
        end
      end
    end

    # Test connector_execute for an ENV hook where there is no cart hook to call.
    def test_connector_execute_env_hook_no_cart_hook
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'ENV:NET_TCP'
      connector = 'set-db-connection-info'
      args = [ '1', '2', '3', { 'gearuuid' => "A=B\nC=D"} ]

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).with(cart_name, pub_cart_name, args)
      @model.expects(:convert_to_shell_arguments).with(args)
      File.expects(:executable?).with(File.join(@container.container_dir,"mock/hooks/set-db-connection-info")).returns(false)

      @container.expects(:run_in_container_context).never()

      result = @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      assert_equal('Set environment variables successfully', result)
    end

    # Test connector_execute for an ENV hook where there is a cart hook to call.
    def test_connector_execute_env_hook_cart_hook
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'ENV:NET_TCP'
      connector = 'set-db-connection-info'
      args = [ '1', '2', '3', { 'gearuuid' => "A=B\nC=D"} ]

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).with(cart_name, pub_cart_name, args)
      @model.expects(:convert_to_shell_arguments).with(args).returns('1 2 3')
      File.expects(:executable?).with(File.join(@container.container_dir,"mock/hooks/set-db-connection-info")).returns(true)

      @container.expects(:run_in_container_context).with(is_a(String), is_a(Hash)).returns(['stdout', 'stderr', 0])

      result = @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      assert_equal('stdout', result)
    end

    def test_connector_execute_env_hook_cart_hook_returns_bad
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'ENV:NET_TCP'
      connector = 'set-db-connection-info'
      args = [ '1', '2', '3', { 'gearuuid' => "A=B\nC=D"} ]

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).with(cart_name, pub_cart_name, args)
      @model.expects(:convert_to_shell_arguments).with(args).returns('1 2 3')
      File.expects(:executable?).with(File.join(@container.container_dir,"mock/hooks/set-db-connection-info")).returns(true)

      @container.expects(:run_in_container_context).with(is_a(String), is_a(Hash)).returns(['stdout', 'stderr', 1])

      assert_raise Runtime::Utils::ShellExecutionException do
        @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      end
    end

    def test_connector_execute_cart_hook
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'NET_TCP'
      connector = 'set-db-connection-info'
      args = "1 2 3"

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).never()
      @model.expects(:convert_to_shell_arguments).never()
      File.expects(:executable?).with(File.join(@container.container_dir,"mock/hooks/set-db-connection-info")).returns(true)

      @container.expects(:run_in_container_context).with(is_a(String), is_a(Hash)).returns(['stdout', 'stderr', 0])

      result = @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      assert_equal('stdout', result)
    end

    def test_connector_execute_cart_hook_returns_bad
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'NET_TCP'
      connector = 'set-db-connection-info'
      args = "1 2 3"

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).never()
      @model.expects(:convert_to_shell_arguments).never()
      File.expects(:executable?).with(File.join @container.container_dir,"mock/hooks/set-db-connection-info").returns(true)

      @container.expects(:run_in_container_context).with(is_a(String), is_a(Hash)).returns(['stdout', 'stderr', 1])

      assert_raise Runtime::Utils::ShellExecutionException do
        @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      end
    end

    def test_connector_execute_cart_hook_not_executable
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'NET_TCP'
      connector = 'set-db-connection-info'
      args = "1 2 3"

      cart = mock()
      cart.stubs(:directory).returns('mock')

      env = mock()

      @model.expects(:get_cartridge).with(cart_name).returns(cart)
      Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir, is_a(String)).returns(env)
      @model.expects(:set_connection_hook_env_vars).never()
      @model.expects(:convert_to_shell_arguments).never()
      File.expects(:executable?).with("#{@container.container_dir}mock/hooks/set-db-connection-info").returns(false)

      @container.expects(:run_in_container_context).never()

      assert_raise Runtime::Utils::ShellExecutionException do
        @model.connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
      end
    end

    def test_connector_execute_nil_cart_name
      pub_cart_name = 'mock-plugin-0.1'
      connection_type = 'NET_TCP'
      connector = 'set-db-connection-info'
      args = "1 2 3"

      @model.expects(:get_cartridge).never()
      
      assert_raise ArgumentError do
        @model.connector_execute(nil, pub_cart_name, connection_type, connector, args)
      end
    end

    def test_set_connection_hook_env_vars
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'
      args = ['1', '2', '3', { 'gearuuid' => "A=B\nC=D\nE=F"}]

      dest_dir = File.join(@container.container_dir, '.env', 'mock-plugin')      

      FileUtils.expects(:mkpath).with(is_a(String))
      @model.expects(:write_environment_variables).with(dest_dir, has_entries('A' => 'B', 'C' => 'D', 'E' => 'F'), false)

      @model.set_connection_hook_env_vars(cart_name, pub_cart_name, args)
    end

    def test_short_name_from_full_cart_name_nil_arg
      assert_raise ArgumentError do
        @model.short_name_from_full_cart_name(nil)
      end
    end

    def test_short_name_from_full_cart_name_no_dash
      full_cart_name = 'mock'
      assert_equal 'mock', @model.short_name_from_full_cart_name(full_cart_name)
    end

    def test_short_name_from_full_cart_name_one_dash
      full_cart_name = 'mock-0.1'
      assert_equal 'mock', @model.short_name_from_full_cart_name(full_cart_name)
    end

    def test_short_name_from_full_cart_name_two_dashes
      full_cart_name = 'mock-plugin-0.1'
      assert_equal 'mock-plugin', @model.short_name_from_full_cart_name(full_cart_name)
    end

    def test_unsubscribe
      cart_name = 'mock-0.1'
      pub_cart_name = 'mock-plugin-0.1'

      FileUtils.expects(:rm_rf).with(File.join(@container.container_dir, '.env', 'mock-plugin'))

      @model.unsubscribe(cart_name, pub_cart_name)
    end

    def with_start_cartridge_scenario
      cart = mock()
      cart.stubs(:name).returns("primary-cart")
      container = @container.dup

      state = mock()
      frontend = mock()
      hourglass = mock()
      hourglass.stubs(:remaining).returns(3600)
      
      model = Runtime::V2CartridgeModel.new(mock(), container, state, hourglass)
      model.stubs(:primary_cartridge).returns(cart)
      model.stubs(:stop_lock?).returns(false)
      model.stubs(:stop_lock).returns("stoplock")


      Runtime::FrontendHttpServer.stubs(:new).with(container).returns(frontend)
      
      yield cart, container, state, frontend, model
      
    end

    def test_start_cartridge_start_as_gear_user
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        container.stubs(:uid).returns(0)
        Process.stubs(:uid).returns(0)

        FileUtils.expects(:rm_f).with("stoplock")

        state.expects(:value=).with(Runtime::State::STARTED)
        frontend.expects(:unprivileged_unidle)
        model.expects(:do_control).with('start', cart, user_initiated: true, hot_deploy: false)

        model.start_cartridge('start', cart, user_initiated: true, hot_deploy: false)
      end
    end

    def test_start_cartridge_start_as_priv_user
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        container.stubs(:uid).returns(1)
        Process.stubs(:uid).returns(0)

        FileUtils.expects(:rm_f).with("stoplock")

        state.expects(:value=).with(Runtime::State::STARTED)
        frontend.expects(:unidle)
        model.expects(:do_control).with('start', cart, user_initiated: true, hot_deploy: false)

        model.start_cartridge('start', cart, user_initiated: true, hot_deploy: false)
      end
    end

    def test_start_cartridge_system_initiated_no_stoplock
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        container.stubs(:uid).returns(1)
        Process.stubs(:uid).returns(0)

        FileUtils.expects(:rm_f).with("stoplock").never

        state.expects(:value=).with(Runtime::State::STARTED)
        frontend.expects(:unidle)
        frontend.expects(:unprivileged_unidle).never
        model.expects(:do_control).with('start', cart, user_initiated: false, hot_deploy: false)

        model.start_cartridge('start', cart, user_initiated: false, hot_deploy: false)
      end
    end

    def test_start_cartridge_system_initiated_stoplock
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        model.stubs(:stop_lock?).returns(true)
        model.expects(:do_control).never

        model.start_cartridge('start', cart, user_initiated: false, hot_deploy: false)
      end
    end

    def test_start_cartridge_secondary
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        secondary = mock()
        secondary.stubs(:name).returns("secondary-cart")

        state.expects(:value=).never
        frontend.expects(:unidle).never
        frontend.expects(:unprivileged_unidle).never
        model.expects(:do_control).with('start', secondary, user_initiated: true, hot_deploy: false)

        model.start_cartridge('start', secondary, user_initiated: true, hot_deploy: false)
      end
    end

    def test_start_cartridge_hot_deploy_as_gear_user
      with_start_cartridge_scenario do |cart, container, state, frontend, model|
        container.stubs(:uid).returns(0)
        Process.stubs(:uid).returns(0)

        FileUtils.expects(:rm_f).with("stoplock")

        state.expects(:value=).with(Runtime::State::STARTED)
        frontend.expects(:unprivileged_unidle)
        model.expects(:do_control).never

        model.start_cartridge('start', cart, user_initiated: true, hot_deploy: true)
      end
    end
  end
end