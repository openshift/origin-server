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
require 'securerandom'
require 'digest/sha1'
require 'openshift-origin-node/model/ident'

class ApplicationContainerFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def setup
    @uid  = 5993
    @uuid = SecureRandom.uuid.gsub(/-/, '')

    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns(nil)
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with('REPORT_BUILD_ANALYTICS').returns(false)
    @config.stubs(:get_bool).with("TRAFFIC_CONTROL_ENABLED", "true").returns(true)

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid,
                                                              'ApplicationContainerFuncTest',
                                                              'ApplicationContainerFuncTest',
                                                              'functional-test')
  end

  def teardown
    @container.destroy
  end

  def test_secret_token
    path  = File.join(@container.container_dir, '.env', 'OPENSHIFT_SECRET_TOKEN')
    token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256))

    @container.create(token)

    assert_path_exist(path)
    assert_equal(token, IO.read(path), 'Secret Token corrupt')
  end

  def test_override_secret
    @container.create(Digest::SHA1.base64digest(SecureRandom.random_bytes(256)))

    path  = File.join(@container.container_dir, '.env', 'user_vars', 'OPENSHIFT_SECRET_TOKEN')
    token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256))
    @container.user_var_add('OPENSHIFT_SECRET_TOKEN' => token)


    assert_path_exist(path)
    assert_equal(token, IO.read(path), 'Secret Token corrupt')

    env = OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
    assert_equal(token, env['OPENSHIFT_SECRET_TOKEN'])
  end

  def wrap_control_script(cartridge, app_id, control_wrapper=nil)
    cart_type = cartridge.sub(/(.*?)-.*/,'\1')
    cart_dir = "/var/lib/openshift/#{app_id}/#{cart_type}"
    control_wrapper ||= <<-EOS
      #!/bin/bash
      case "$1" in
        start)     env > start_env;;
        stop)      env > stop_env;;
        restart)   env > restart_env;;
      esac
      #{cart_dir}/bin/wrapped_control $1
    EOS

    `mv #{cart_dir}/bin/control #{cart_dir}/bin/wrapped_control`
    File.write("#{cart_dir}/bin/control", control_wrapper)
    `chmod a+x #{cart_dir}/bin/control`
    cart_dir
  end

  def test_override_cartridge_var
    @container.create(Digest::SHA1.base64digest(SecureRandom.random_bytes(256)))
    cartridge_name = 'mock-0.1'
    path           = File.join(@container.container_dir, '.env', 'user_vars', 'OPENSHIFT_MOCK_EXAMPLE')
    data           = 'override_value'

    ident = OpenShift::Runtime::Ident.new('redhat', 'mock', '0.1')
    # Mock app
    @container.cartridge_model.configure(ident)
    # Control script wrapper captures env
    cart_dir = wrap_control_script(cartridge_name, @uuid)

    # User env var file isn't created yet
    refute_path_exist(path)

    env = OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
    # Default value in OPENSHIFT_MOCK_EXAMPLE
    assert_equal('test_value', env['OPENSHIFT_MOCK_EXAMPLE'])

    @container.cartridge_model.stop_cartridge(cartridge_name)
    # Check stop_env for default value
    assert_path_exist("#{cart_dir}/stop_env")
    if File.exist?("#{cart_dir}/stop_env")
      test_env_var = open("#{cart_dir}/stop_env").grep(/OPENSHIFT_MOCK_EXAMPLE/).first
      test_env_var = test_env_var.chomp.split('=').last
      assert_equal('test_value', test_env_var)
      File.unlink("#{cart_dir}/stop_env")
    else
      flunk("cartridge wrapper script failed to create file stop_env")
    end
    @container.cartridge_model.start_cartridge('start', cartridge_name)
    # Check start_env for default value
    assert_path_exist("#{cart_dir}/start_env")
    if File.exist?("#{cart_dir}/start_env")
      test_env_var = open("#{cart_dir}/start_env").grep(/OPENSHIFT_MOCK_EXAMPLE/).first
      test_env_var = test_env_var.chomp.split('=').last
      assert_equal('test_value', test_env_var)
      File.unlink("#{cart_dir}/start_env")
    else
      flunk("cartridge wrapper script failed to create file start_env")
    end

    # Set user env var to override cart env var
    @container.user_var_add('OPENSHIFT_MOCK_EXAMPLE' => data)

    # Validate user env var created with correct value
    assert_path_exist(path)
    assert_equal(data, IO.read(path), 'User variable corrupt')

    env = OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
    # Validate Environ#for_gear loads user env var override appropriately
    assert_equal(data, env['OPENSHIFT_MOCK_EXAMPLE'])

    @container.cartridge_model.stop_cartridge(cartridge_name)
    # Check stop_env for override value
    assert_path_exist("#{cart_dir}/stop_env")
    if File.exist?("#{cart_dir}/stop_env")
      test_env_var = open("#{cart_dir}/stop_env").grep(/OPENSHIFT_MOCK_EXAMPLE/).first
      test_env_var = test_env_var.chomp.split('=').last
      assert_equal(data, test_env_var, 'User variable override failed')
    else
      flunk("cartridge wrapper script failed to create file stop_env")
    end
    @container.cartridge_model.start_cartridge('start', cartridge_name)
    # Check start_env for override value
    assert_path_exist("#{cart_dir}/start_env")
    if File.exist?("#{cart_dir}/start_env")
      test_env_var = open("#{cart_dir}/start_env").grep(/OPENSHIFT_MOCK_EXAMPLE/).first
      test_env_var = test_env_var.chomp.split('=').last
      assert_equal(data, test_env_var, 'User variable override failed')
    else
      flunk("cartridge wrapper script failed to create file start_env")
    end
  end
end
