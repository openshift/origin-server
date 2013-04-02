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
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/frontend_proxy'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/utils/application_state'
require 'etc'
require 'test/unit'
require 'mocha'

class V2CartridgeModelFunctionalTest < Test::Unit::TestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @config = mock('OpenShift::Config')
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
    @config.stubs(:get).with("UID_BEGIN").returns(1000)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')

    script_dir     = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')
    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)
    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

    OpenShift::Config.stubs(:new).returns(@config)

    OpenShift::Utils::Sdk.stubs(:new_sdk_app?).returns(true)

    @uuid = %x(uuidgen -r |sed -e s/-//g).chomp

    begin
      %x(userdel -f #{Etc.getpwuid(1002).name})
    rescue ArgumentError
    end

    @user = OpenShift::UnixUser.new(@uuid, @uuid,
                                    1002,
                                    'V2CartridgeModelFunctionalTest',
                                    'V2CartridgeModelFunctionalTest',
                                    'functional-test')
    @user.create
    refute_nil @user.homedir

    OpenShift::CartridgeRepository.instance.clear
    OpenShift::CartridgeRepository.instance.load
    @model = OpenShift::V2CartridgeModel.new(@config, @user, OpenShift::Utils::ApplicationState.new(@uuid))
    @model.configure('mock-0.1')
    @model.configure('mock-plugin-0.1')
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    @user.destroy
  end

  def test_publish_db_connection_info
    results = @model.connector_execute('mock-plugin-0.1', 'publish-db-connection-info', "")
    refute_nil results

    assert_match(
        %r(OPENSHIFT_MOCK_PLUGIN_DB_USERNAME=UT_username; OPENSHIFT_MOCK_PLUGIN_DB_PASSWORD=UT_password; OPENSHIFT_MOCK_PLUGIN_DB_HOST=\d+\.\d+\.\d+\.\d+; OPENSHIFT_MOCK_PLUGIN_DB_PORT=8080; OPENSHIFT_MOCK_PLUGIN_DB_URL=mock://\d+\.\d+\.\d+\.\d+:8080/unit_test;),
        results)
  end

  def test_set_db_connection_info
    @model.connector_execute('mock-0.1', 'set-db-connection-info', "test testdomain 515c7e8bdf3e460939000001 \\'75e36e529c9211e29cc622000a8c0259\\'\\=\\'OPENSHIFT_MOCK_DB_GEAR_UUID\\=75e36e529c9211e29cc622000a8c0259\\;\\;\\ '\n'\\'")

    uservar_file = File.join(@user.homedir, '.env', '.uservars', 'OPENSHIFT_MOCK_DB_GEAR_UUID')
    assert File.exists? uservar_file
    assert_equal "export OPENSHIFT_MOCK_DB_GEAR_UUID='75e36e529c9211e29cc622000a8c0259'", IO.read(uservar_file).chomp
  end
end