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
require 'etc'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  class V2CartridgeModelFunctionalTest < OpenShift::V2SdkTestCase
    GEAR_BASE_DIR = '/var/lib/openshift'

    def before_setup
      super

      @uid = 5996

      @config = mock('OpenShift::Config')
      @config.stubs(:get).returns(nil)
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

      script_dir     = File.expand_path(File.dirname(__FILE__))
      cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')
      raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)
      @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

      OpenShift::Config.stubs(:new).returns(@config)

      @uuid = %x(uuidgen -r |sed -e s/-//g).chomp

      begin
        %x(userdel -f #{Etc.getpwuid(@uid).name})
      rescue ArgumentError
      end

      @user = OpenShift::UnixUser.new(@uuid, @uuid,
                                      @uid,
                                      'V2CartridgeModelFunctionalTest',
                                      'V2CartridgeModelFunctionalTest',
                                      'functional-test')
      @user.create
      refute_nil @user.homedir

      OpenShift::CartridgeRepository.instance.clear
      OpenShift::CartridgeRepository.instance.load
      @model = OpenShift::V2CartridgeModel.new(@config, @user, OpenShift::Utils::ApplicationState.new(@uuid))
      @model.configure('mock-0.1')
    end

    def teardown
      @model.deconfigure('mock-plugin-0.1') if File.exist?(File.join(@user.homedir, 'mock-plugin'))
    end

    def after_teardown
      @user.destroy
    end

    def test_hidden_erb
      assert_path_exist(File.join(@user.homedir, 'mock', '.mock_hidden'),
                        'Failed to process .mock_hidden.erb')

      refute_path_exist(File.join(@user.homedir, 'mock', '.mock_hidden.erb'),
                        'Failed to delete .mock_hidden.erb after processing')
    end

    def test_publish_db_connection_info
      @model.configure('mock-plugin-0.1')

      results = @model.connector_execute('mock-plugin-0.1', 'mysql-5.1', 'NET_TCP:db:connection-info', 'publish-db-connection-info', "")
      refute_nil results

      assert_match(
          %r(OPENSHIFT_MOCK_PLUGIN_DB_USERNAME=UT_username; OPENSHIFT_MOCK_PLUGIN_DB_PASSWORD=UT_password; OPENSHIFT_MOCK_PLUGIN_GEAR_UUID=.*; OPENSHIFT_MOCK_PLUGIN_DB_HOST=\d+\.\d+\.\d+\.\d+; OPENSHIFT_MOCK_PLUGIN_DB_PORT=8080; OPENSHIFT_MOCK_PLUGIN_DB_URL=mock://\d+\.\d+\.\d+\.\d+:8080/unit_test;),
          results)
    end

    def test_set_db_connection_info
      @model.configure('mock-plugin-0.1')

      @model.connector_execute('mock-0.1',
                               'mysql-5.1',
                               'NET_TCP:db:connection-info',
                               'set-db-connection-info',
                               "test testdomain 515c7e8bdf3e460939000001 \\'75e36e529c9211e29cc622000a8c0259\\'\\=\\'OPENSHIFT_MOCK_DB_GEAR_UUID\\=75e36e529c9211e29cc622000a8c0259\\;\\;\\ '\n'\\'")

      uservar_file = File.join(@user.homedir, '.env', '.uservars', 'OPENSHIFT_MOCK_DB_GEAR_UUID')
      assert_path_exist(uservar_file)
      assert_equal '75e36e529c9211e29cc622000a8c0259', IO.read(uservar_file).chomp
    end

    def test_configure_with_manifest
      refute_path_exist(File.join(@user.homedir, 'mock-plugin'))

      cartridge = OpenShift::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      cuckoo = File.join(@user.homedir, %w(app-root data cuckoo))
      FileUtils.mkpath(cuckoo)
      %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{cuckoo})

      # build our "remote" cartridge repository
      cuckoo_repo = File.join(@user.homedir, %w(app-root data cuckoo_repo))
      FileUtils.mkpath cuckoo_repo
      Dir.chdir(cuckoo_repo) do
        %x(git init;
          shopt -s dotglob;
          cp -ad #{cuckoo}/* .;
          git add -f .;
          git </dev/null commit -a -m "Creating cuckoo template" 2>&1;
        )
      end

      # Point manifest at "remote" repository
      manifest = IO.read(File.join(cuckoo, 'metadata', 'manifest.yml'))
      manifest << ("Source-Url: file://" + cuckoo + '_repo')

      # install the cuckoo
      begin
        @model.configure('cuckoo-0.1', nil, manifest)
      rescue OpenShift::Utils::ShellExecutionException => e
        NodeLogger.logger.debug(e.message + "\n" +
                                    e.stdout + "\n" +
                                    e.stderr + "\n" +
                                    e.backtrace.join("\n")
        )
      end

      assert_path_exist(File.join(@user.homedir, 'mock-plugin'))
      assert_path_exist(File.join(@user.homedir, %w(mock-plugin bin control)))
    end
  end
end
