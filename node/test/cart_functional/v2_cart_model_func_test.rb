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
  class V2CartridgeModelFunctionalTest < NodeTestCase
    GEAR_BASE_DIR = '/var/lib/openshift'

    def before_setup
      super

      @uid = 5996

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

      script_dir     = File.expand_path(File.dirname(__FILE__))
      cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')
      raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)
      @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

      @uuid = %x(uuidgen -r |sed -e s/-//g).chomp

      begin
        %x(userdel -f #{Etc.getpwuid(@uid).name})
      rescue ArgumentError
      end

      @container = Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "V2CartridgeModelFunctionalTest",
                                                                "V2CartridgeModelFunctionalTest", "functional-test")
      @container.create(@secret_token)

      refute_nil @container.container_dir

      Runtime::CartridgeRepository.instance.clear
      Runtime::CartridgeRepository.instance.load

      @hourglass = mock()
      @hourglass.stubs(:remaining).returns(3600)

      @model = Runtime::V2CartridgeModel.new(@config, @container, ::OpenShift::Runtime::Utils::ApplicationState.new(@container), @hourglass)
    end

    def teardown
      @model.deconfigure('mock-plugin-0.1') if File.exist?(File.join(@container.container_dir, 'mock-plugin'))
      @model.deconfigure('mock-0.1') if File.exist?(File.join(@container.container_dir, 'mock'))
      FileUtils.rm_rf(File.join(@container.container_dir, 'git'))
    end

    def after_teardown
      %x(restorecon -rv #{@container.container_dir})
      @container.destroy
    end

    def test_hidden_erb
      @model.configure('mock-0.1')

      assert_path_exist(File.join(@container.container_dir, 'mock', '.mock_hidden'),
                        'Failed to process .mock_hidden.erb')

      refute_path_exist(File.join(@container.container_dir, 'mock', '.mock_hidden.erb'),
                        'Failed to delete .mock_hidden.erb after processing')
    end

    def test_configure_with_manifest
      @model.configure('mock-0.1')

      refute_path_exist(File.join(@container.container_dir, 'mock-plugin'))

      cartridge = Runtime::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      cuckoo = File.join(@container.container_dir, %w(app-root data cuckoo))
      FileUtils.mkpath(cuckoo)
      %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{cuckoo})

      # build our "remote" cartridge repository
      cuckoo_repo = File.join(@container.container_dir, %w(app-root data cuckoo_repo))
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
      manifest << ("Source-Url: file://" + cuckoo + '_repo') << "\n"
      manifest = change_cartridge_vendor_of manifest

      # install the cuckoo
      begin
        @model.configure('cuckoo-0.1', nil, manifest)
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        NodeLogger.logger.debug(e.message + "\n" +
                                    e.stdout + "\n" +
                                    e.stderr + "\n" +
                                    e.backtrace.join("\n")
        )
      end

      assert_path_exist(File.join(@container.container_dir, 'mock-plugin'))
      assert_path_exist(File.join(@container.container_dir, %w(mock-plugin bin control)))
    end

    def test_configure_with_no_template
      cartridge = Runtime::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      cuckoo = File.join(@container.container_dir, %w(app-root data cuckoo))
      FileUtils.mkpath(cuckoo)
      %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{cuckoo})
      refute_path_exist File.join(cuckoo, 'template')

      # Point manifest at "remote" repository
      manifest                     = YAML.load_file(File.join(cuckoo, 'metadata', 'manifest.yml'))
      manifest['Name']             = 'cuckoo'
      manifest['Source-Url']       = "file://#{cuckoo}"
      manifest['Cartridge-Vendor'] = 'unittest'
      manifest['Categories']       = %w(service cuckoo web_framework)
      manifest                     = manifest.to_yaml

      # install the cuckoo
      begin
        @model.configure('cuckoo-0.1', nil, manifest)
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        NodeLogger.logger.debug(e.message + "\n" +
                                    e.stdout + "\n" +
                                    e.stderr + "\n" +
                                    e.backtrace.join("\n")
        )
      end

      entries = Dir.entries(File.join(@container.container_dir, 'git'))
      assert_equal(2, entries.size, "Found application template: #{entries}")
      assert_path_exist(File.join(@container.container_dir, 'cuckoo'))
      assert_path_exist(File.join(@container.container_dir, %w(cuckoo bin control)))
    end

    def test_configure_with_short_name
      cartridge = Runtime::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      # Point manifest at "remote" repository
      manifest                     = YAML.load_file(File.join(cartridge.repository_path, 'metadata', 'manifest.yml'))
      manifest['Name']             = 'cuckoo'
      manifest['Source-Url']       = "file://#{cartridge.repository_path}"
      manifest['Cartridge-Vendor'] = 'unittest'
      manifest['Categories']       = %w(service cuckoo web_framework)
      manifest                     = manifest.to_yaml

      # install the cuckoo
      begin
        @model.configure('cuckoo-0.1', nil, manifest)
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        NodeLogger.logger.debug(e.message + "\n" +
                                    e.stdout + "\n" +
                                    e.stderr + "\n" +
                                    e.backtrace.join("\n")
        )
      end

      env = File.join(@container.container_dir, 'cuckoo', 'env')
      assert_path_exist File.join(env, 'OPENSHIFT_MOCK_PLUGIN_DIR')
      assert_path_exist File.join(env, 'OPENSHIFT_MOCK_PLUGIN_IDENT')
      refute_path_exist File.join(env, 'OPENSHIFT_CUCKOO_DIR')
      refute_path_exist File.join(env, 'OPENSHIFT_CUCKOO_IDENT')
    end

    def test_configure_with_envvar_override
      cartridge = Runtime::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      cuckoo = File.join(@container.container_dir, %w(app-root data cuckoo))
      FileUtils.mkpath(cuckoo)
      %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{cuckoo})
      IO.write(File.join(cuckoo, 'bin', 'setup'),
               %q(echo 'Illegal Operation' >env/OPENSHIFT_GEAR_UUID),
               0,
               mode: 'w', perm: 0755)

      # Point manifest at "remote" repository
      manifest                     = YAML.load_file(File.join(cuckoo, 'metadata', 'manifest.yml'))
      manifest['Name']             = 'cuckoo'
      manifest['Source-Url']       = "file://#{cuckoo}"
      manifest['Cartridge-Vendor'] = 'unittest'
      manifest['Categories']       = %w(service cuckoo web_framework)
      manifest                     = manifest.to_yaml

      # install the cuckoo
      assert_raises RuntimeError do
        @model.configure('cuckoo-0.1', nil, manifest)
      end
    end

    def test_configure_with_bad_directory
      cartridge = Runtime::CartridgeRepository.instance.select('mock-plugin', '0.1')
      skip 'Mock Plugin 0.1 cartridge required for this test' unless cartridge

      cuckoo = File.join(@container.container_dir, %w(app-root data cuckoo))
      FileUtils.mkpath(cuckoo)
      %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{cuckoo})
      IO.write(File.join(cuckoo, 'bin', 'setup'),
               %q(mkdir ~/illegal_directory),
               0,
               mode: 'w', perm: 0755)

      # Point manifest at "remote" repository
      manifest                     = YAML.load_file(File.join(cuckoo, 'metadata', 'manifest.yml'))
      manifest['Name']             = 'cuckoo'
      manifest['Source-Url']       = "file://#{cuckoo}"
      manifest['Cartridge-Vendor'] = 'unittest'
      manifest['Categories']       = %w(service cuckoo web_framework)
      manifest                     = manifest.to_yaml

      # install the cuckoo
      assert_raises RuntimeError do
        @model.configure('cuckoo-0.1', nil, manifest)
      end
    end
  end
end
