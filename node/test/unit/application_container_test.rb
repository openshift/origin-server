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
require 'fileutils'
require 'yaml'

module OpenShift
  ;
end

class ApplicationContainerTest < OpenShift::NodeTestCase

  def setup
    @ports_begin    = 35531
    @ports_per_user = 5
    @uid_begin      = 500

    @config.stubs(:get).with("PORT_BEGIN").returns(@ports_begin.to_s)
    @config.stubs(:get).with("PORTS_PER_USER").returns(@ports_per_user.to_s)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid_begin.to_s)
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    script_dir     = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)
    #@config.stubs(:get).with("CONTAINERIZATION_PLUGIN").returns('openshift-origin-container-selinux')

    # Set up the container
    @gear_uuid = '5504'
    @user_uid  = '5504'
    @app_name  = 'ApplicatioContainerTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = '127.0.0.1'

    Etc.stubs(:getpwnam).returns(
        OpenStruct.new(
            uid:   @user_uid.to_i,
            gid:   @user_uid.to_i,
            gecos: "OpenShift guest",
            dir:   "/var/lib/openshift/#{@gear_uuid}"
        )
    )

    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
                                                              @app_name, @gear_uuid, @namespace, nil, nil, nil)


    @mock_manifest = %q{#
        Name: mock
        Cartridge-Short-Name: MOCK
        Cartridge-Version: 1.0
        Cartridge-Vendor: unit_test
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
    @mock_cartridge = OpenShift::Runtime::Manifest.new(manifest, nil, :file)
    @container.cartridge_model.stubs(:get_cartridge).with("mock").returns(@mock_cartridge)
  end

  def teardown
    FileUtils.rm_rf @container.container_dir
  end

  def test_public_endpoints_create
    OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns({
                                                                    "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
                                                                    "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
                                                                })

    proxy = mock('OpenShift::Runtime::FrontendProxyServer')
    OpenShift::Runtime::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:add).with(@user_uid.to_i, "127.0.0.1", 8080).returns(@ports_begin)
    proxy.expects(:add).with(@user_uid.to_i, "127.0.0.1", 8081).returns(@ports_begin+1)
    proxy.expects(:add).with(@user_uid.to_i, "127.0.0.1", 8082).returns(@ports_begin+2)
    proxy.expects(:add).with(@user_uid.to_i, "127.0.0.2", 9090).returns(@ports_begin+3)

    @container.expects(:add_env_var).returns(nil).times(4)

    @container.create_public_endpoints(@mock_cartridge.name)
  end

  def test_public_endpoints_delete
    OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns({
                                                                    "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
                                                                    "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
                                                                })

    proxy = mock('OpenShift::Runtime::FrontendProxyServer')
    OpenShift::Runtime::FrontendProxyServer.stubs(:new).returns(proxy)
    OpenShift::Runtime::V2CartridgeModel.any_instance.expects(:list_proxy_mappings).returns([
                                                                                                {public_port_name: "Endpoint_1", proxy_port: @ports_begin},
                                                                                                {public_port_name: "Endpoint_2", proxy_port: @ports_begin+1},
                                                                                                {public_port_name: "Endpoint_3", proxy_port: @ports_begin+2},
                                                                                                {public_port_name: "Endpoint_4", proxy_port: @ports_begin+3}])
    #proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8080).returns(@ports_begin)
    #proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8081).returns(@ports_begin+1)
    #proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8082).returns(@ports_begin+2)
    #proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.2", 9090).returns(@ports_begin+3)

    delete_all_args = [@ports_begin, @ports_begin+1, @ports_begin+2, @ports_begin+3]
    proxy.expects(:delete_all).with(delete_all_args, true).returns(nil)

    @container.expects(:remove_env_var).returns(nil).times(4)

    @container.delete_public_endpoints(@mock_cartridge.name)
  end

  def test_tidy_success
    OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name'})

    @container.stubs(:stop_gear)
    @container.stubs(:gear_level_tidy_tmp).with('/foo/.tmp')
    @container.cartridge_model.expects(:tidy)
    @container.stubs(:gear_level_tidy_git).with('/foo/git/app_name.git')
    @container.stubs(:start_gear)

    @container.stubs(:cartridge_model).returns(mock())

    @container.tidy
  end

  def test_tidy_stop_gear_fails
    OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name'})

    @container.stubs(:stop_gear).raises(Exception.new)
    @container.stubs(:gear_level_tidy_tmp).with('/foo/.tmp')
    @container.cartridge_model.expects(:tidy).never
    @container.stubs(:gear_level_tidy_git).with('/foo/git/app_name.git')
    @container.stubs(:start_gear).never

    assert_raise Exception do
      @container.tidy
    end
  end

  def test_tidy_gear_level_tidy_fails
    OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name'})

    @container.expects(:stop_gear)
    @container.expects(:gear_level_tidy_tmp).with('/foo/.tmp').raises(Exception.new)
    @container.expects(:start_gear)

    @container.tidy
  end

  def test_force_stop
    FileUtils.mkpath("/tmp/#@user_uid/app-root/runtime")
    OpenShift::Runtime::Containerization::Plugin.stubs(:kill_procs).with(@user_uid).returns(nil)
    @container.state.expects(:value=).with(OpenShift::Runtime::State::STOPPED)
    @container.cartridge_model.expects(:create_stop_lock)
    @container.force_stop
  end

  def test_connector_execute
    cart_name      = 'mock-0.1'
    pub_cart_name  = 'mock-plugin-0.1'
    connector_type = 'ENV:NET_TCP'
    connector      = 'set-db-connection-info'
    args           = 'foo'

    @container.cartridge_model.expects(:connector_execute).with(cart_name, pub_cart_name, connector_type, connector, args)

    @container.connector_execute(cart_name, pub_cart_name, connector_type, connector, args)
  end

  # Tests a variety of UID/host ID to IP address conversions.
  #
  # TODO: Is there a way to do this algorithmically?
  def test_get_ip_addr_success
    scenarios = [
        [501, 1, "127.0.250.129"],
        [501, 10, "127.0.250.138"],
        [501, 20, "127.0.250.148"],
        [501, 100, "127.0.250.228"],
        [540, 1, "127.1.14.1"],
        [560, 7, "127.1.24.7"]
    ]

    scenarios.each do |s|
      Etc.stubs(:getpwnam).returns(
          OpenStruct.new(
              uid:   s[0].to_i,
              gid:   s[0].to_i,
              gecos: "OpenShift guest",
              dir:   "/var/lib/openshift/gear_uuid"
          )
      )

      container = OpenShift::Runtime::ApplicationContainer.new("gear_uuid", "gear_uuid", s[0],
                                                               "app_name", "gear_uuid", "namespace", nil, nil, nil)

      assert_equal container.get_ip_addr(s[1]), s[2]
    end
  end

  def test_user_var_add()
    target   = ".env/user_vars"
    source   = "/var/lib/openshift/#{@gear_uuid}/#{target}"
    filename = "#{source}/UNIT_TEST"
    gears    = ['unit_test.example.com']

    @container.expects(:user_var_push).with(gears)

    @container.user_var_add({'UNIT_TEST' => 'true'}, gears)

    assert_path_exist filename
  end

  def test_user_var_remove()
    path  = "/var/lib/openshift/#{@gear_uuid}/.env/user_vars/UNIT_TEST"
    gears = ['unit_test.example.com']

    @container.expects(:user_var_push).with(gears).twice

    @container.user_var_add({'UNIT_TEST' => 'true'}, gears)
    assert_path_exist path

    @container.user_var_remove(['UNIT_TEST'], gears)
    refute_path_exist path
  end

  def test_user_var_list()
    @container.user_var_remove(['UNIT_TEST', 'FUNC_TEST'])
    assert_equal({}, @container.user_var_list())

    @container.user_var_add({'UNIT_TEST' => 'true'})
    actual = @container.user_var_list()
    assert_equal({'UNIT_TEST' => 'true'}, actual)

    @container.user_var_add({'FUNC_TEST' => 'false'})
    actual = @container.user_var_list(['FUNC_TEST'])
    assert_equal({'FUNC_TEST' => 'false'}, actual)
  end

  def test_bad_user_var()
    env = {'OPENSHIFT_TEST_IDENT'            => 'x:x:x:x',
           'OPENSHIFT_NAMESPACE'             => 'namespace',
           'OPENSHIFT_PRIMARY_CARTRIDGE_DIR' => 'mine'}

    env.each do |key, value|
      rc, msg = @container.user_var_add({key => value})
      assert_equal 127, rc, "#{key} should have failed."
      assert_equal "CLIENT_ERROR: #{key} cannot be overridden", msg
    end

    rc, msg = @container.user_var_add({'TOO_BIG' => '*' * 513})
    assert_equal 127, rc
    assert_equal 'CLIENT_ERROR: TOO_BIG value exceeds maximum size of 512b', msg
  end
end
