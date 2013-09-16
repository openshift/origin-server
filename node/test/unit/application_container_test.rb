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
            Options:           { primary: true }
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

    @container.expects(:add_env_var).with('OPENSHIFT_MOCK_EXAMPLE_PUBLIC_PORT1', @ports_begin)
    @container.expects(:add_env_var).with('LOAD_BALANCER_PORT', @ports_begin, true)
    @container.expects(:add_env_var).with('OPENSHIFT_MOCK_EXAMPLE_PUBLIC_PORT2', @ports_begin+1)
    @container.expects(:add_env_var).with('OPENSHIFT_MOCK_EXAMPLE_PUBLIC_PORT3', @ports_begin+2)
    @container.expects(:add_env_var).with('OPENSHIFT_MOCK_EXAMPLE_PUBLIC_PORT4', @ports_begin+3)

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

    @container.expects(:user_var_push).with(gears, true)

    @container.user_var_add({'UNIT_TEST' => 'true'}, gears)

    assert_path_exist filename
  end

  def test_user_var_remove()
    path  = "/var/lib/openshift/#{@gear_uuid}/.env/user_vars/UNIT_TEST"
    gears = ['unit_test.example.com']

    @container.expects(:user_var_push).with(gears, true)
    @container.expects(:user_var_push).with(gears)

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
           'OPENSHIFT_PRIMARY_CARTRIDGE_DIR' => 'mine',
           'PATH'                            => '/usr/bin',
           'IFS'                             => '/',
           'USER'                            => 'none',
           'SHELL'                           => 'tcsh',
           'HOSTNAME'                        => 'remotehost',
           'LOGNAME'                         => '/tmp/log'}

    env.each do |key, value|
      rc, msg = @container.user_var_add({key => value})
      assert_equal 127, rc, "#{key} should have failed."
      assert_equal "CLIENT_ERROR: #{key} cannot be overridden", msg
    end

    rc, msg = @container.user_var_add({'TOO_BIG' => '*' * 513})
    assert_equal 127, rc
    assert_equal "CLIENT_ERROR: 'TOO_BIG' value exceeds maximum size of 512b", msg
  end

  # Tests that no_overcommit logic works as intended
  def test_no_overcommit
        scenarios = [
        [5507, true, 0.0],
        [5508, true, 100.0],
        [5509, false, 0.0],
        [5510, false, 100.0],
    ]

    scenarios.each do |s|
      if s[1]
        @config.stubs(:get_bool).with('no_overcommit_active', false).returns(true)
      else
        @config.stubs(:get_bool).with('no_overcommit_active', false).returns(false)
      end
      OpenShift::Runtime::Node.stubs(:node_utilization).returns({'gears_active_usage_pct' => s[2]})
      OpenShift::Runtime::Node.stubs(:resource_limits).returns(@config)

      containerization_plugin_mock = mock('OpenShift::Runtime::Containerization::Plugin')
      containerization_plugin_mock.stubs(:create).returns(nil)
      OpenShift::Runtime::Containerization::Plugin.stubs(:new).returns(containerization_plugin_mock)
      Etc.stubs(:getpwnam).returns(
        OpenStruct.new(
          uid: s[0],
          gid: s[0],
          gecos: "OpenShift guest",
          container_dir: "/var/lib/openshift/#{s[0].to_s}"
        )
      )

      container = OpenShift::Runtime::ApplicationContainer.new(s[0].to_s, s[0].to_s, s[0],
                                                               @app_name, s[0].to_s, @namespace, nil, nil, nil)
      container.stubs(:generate_ssh_key).returns('generate_ssh_key stub')
      if s[1] and (s[2] == 100.0)
        assert_raise OpenShift::Runtime::GearCreationException do
          container.create
        end
      else
        container.create
      end
    end
  end

  def test_deconfigure
    @container.cartridge_model.expects(:deconfigure).with('mock-0.1')
    @container.deconfigure('mock-0.1')
  end

  def test_unsubscribe
    @container.cartridge_model.expects(:unsubscribe).with('mock-0.1', 'pub-cart')
    @container.unsubscribe('mock-0.1', 'pub-cart')
  end

  def test_update_cluster_no_web_proxy
    @container.cartridge_model.expects(:web_proxy).returns(nil)
    ::OpenShift::Runtime::Utils::Environ::expects(:for_gear).never
    ::OpenShift::Runtime::GearRegistry.expects(:new).never
    @config.expects(:get).never
    ::OpenShift::Runtime::GearRegistry::Entry.expects(:new).never
    @container.expects(:run_in_container_context).never
    @container.expects(:current_deployment_datetime).never
    @container.expects(:read_deployment_metadata).never
    @container.expects(:activate_many).never
    @container.cartridge_model.expects(:do_control).never

    @container.update_cluster("", "")
  end

  def test_update_cluster_add_gears
    web_proxy = mock()
    @container.cartridge_model.expects(:web_proxy).times(3).returns(web_proxy)

    gear_env = {'OPENSHIFT_APP_DNS' => 'foo-bar.example.com', 'OPENSHIFT_GEAR_DNS' => 'foo-bar.example.com'}
    ::OpenShift::Runtime::Utils::Environ::expects(:for_gear).with(@container.container_dir).returns(gear_env)

    gear_registry = mock()
    ::OpenShift::Runtime::GearRegistry.expects(:new).with(@container).returns(gear_registry)

    uuid1 = @container.uuid
    gear1 = {
      uuid: uuid1,
      namespace: 'bar',
      dns: 'foo-bar.example.com',
      proxy_hostname: 'node1.example.com',
      proxy_port: 35561
    }
    web_entry1 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear1)
    proxy_entry1 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear1.merge(proxy_port: 0))

    uuid2 = (@container.uuid.to_i + 1).to_s
    gear2 = {
      uuid: uuid2,
      namespace: 'bar',
      dns: "#{uuid2}-bar.example.com",
      proxy_hostname: 'node1.example.com',
      proxy_port: 35566
    }
    web_entry2 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear2)
    proxy_entry2 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear2.merge(proxy_port: 0))

    uuid3 = (@container.uuid.to_i + 2).to_s
    gear3 = {
      uuid: uuid3,
      namespace: 'bar',
      dns: "#{uuid3}-bar.example.com",
      proxy_hostname: 'node1.example.com',
      proxy_port: 35571
    }
    web_entry3 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear3)
    proxy_entry3 = ::OpenShift::Runtime::GearRegistry::Entry.new(gear3.merge(proxy_port: 0))

    old_entries = {
      :web => {
        uuid1 => web_entry1
      },
      :proxy => {
        uuid1 => proxy_entry1
      }
    }

    updated_entries = {
      :web => {
        uuid1 => web_entry1,
        uuid2 => web_entry2,
        uuid3 => web_entry3
      },
      :proxy => {
        uuid1 => proxy_entry1,
        uuid3 => proxy_entry3
      }
    }
    gear_registry.expects(:entries).twice.returns(old_entries, updated_entries)
    gear_registry.expects(:clear)

    @config.expects(:get).with('CLOUD_DOMAIN').returns('example.com')
    web_uuids = [uuid1, uuid2, uuid3]

    web_uuids.each do |uuid|
      gear_registry.expects(:add).with(type: :web,
                                       uuid: uuid,
                                       namespace: "namespace#{uuid}",
                                       dns: "name#{uuid}-namespace#{uuid}.example.com",
                                       proxy_hostname: "host#{uuid}",
                                       proxy_port: "port#{uuid}")
    end

    proxy_uuids = [uuid1, uuid3]
    proxy_uuids.each do |uuid|
      gear_registry.expects(:add).with(type: :proxy,
                                       uuid: uuid,
                                       namespace: "namespace#{uuid}",
                                       dns: "name#{uuid}-namespace#{uuid}.example.com",
                                       proxy_hostname: "host#{uuid}",
                                       proxy_port: 0)
    end

    gear_registry.expects(:save)

    [web_entry2, web_entry3].each do |new_entry|
      @container.expects(:run_in_container_context).with("rsync -avz --delete --rsh=/usr/bin/oo-ssh app-deployments/ #{new_entry.uuid}@#{new_entry.proxy_hostname}:app-deployments/",
                                                        env: gear_env,
                                                        chdir: @container.container_dir,
                                                        expected_exitstatus: 0)
    end
    current_deployment_datetime = '2013-08-16_13-36-36.880'
    @container.expects(:current_deployment_datetime).returns(current_deployment_datetime)

    deployment_id = 'abcd1234'
    @container.expects(:read_deployment_metadata).with(current_deployment_datetime, 'id').returns(deployment_id)

    @container.expects(:activate_many).with(gears: [web_entry2, web_entry3].map { |e| "#{e.uuid}@#{e.proxy_hostname}" },
                                            deployment_id: deployment_id,
                                            init: true,
                                            hot_deploy: false)

    @container.expects(:run_in_container_context).with("rsync -avz --delete --exclude hooks --rsh=/usr/bin/oo-ssh git/#{@app_name}.git/ #{proxy_entry3.uuid}@#{proxy_entry3.proxy_hostname}:git/#{@app_name}.git/",
                                                        env: gear_env,
                                                        chdir: @container.container_dir,
                                                        expected_exitstatus: 0)

    do_control_args = web_uuids.map { |uuid| "name#{uuid}-namespace#{uuid}.example.com|host#{uuid}:port#{uuid}" }.join(' ')
    @container.cartridge_model.expects(:do_control).with('update-cluster', web_proxy, args: do_control_args)

    proxy_arg = proxy_uuids.map { |uuid| "#{uuid},name#{uuid},namespace#{uuid},host#{uuid}"}.join(' ')
    cluster_arg = web_uuids.map { |uuid| "#{uuid},name#{uuid},namespace#{uuid},host#{uuid},port#{uuid}"}.join(' ')

    @container.update_cluster(proxy_arg, cluster_arg)
  end
end
