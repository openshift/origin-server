#--
# Copyright 2014 Red Hat, Inc.
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
  class MetricsFunctionalTest < NodeTestCase
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

      @container = Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "MetricsFunctionalTest",
                                                                "MetricsFunctionalTest", "functional-test")
      @container.create(@secret_token)

      refute_nil @container.container_dir

      @hourglass = mock()
      @hourglass.stubs(:remaining).returns(3600)

      @model = Runtime::V2CartridgeModel.new(@config, @container, ::OpenShift::Runtime::Utils::ApplicationState.new(@container), @hourglass)
    end

    def teardown
      ident = OpenShift::Runtime::Ident.new('redhat', 'mock-plugin', '0.1')
      @model.deconfigure(ident) if File.exist?(File.join(@container.container_dir, 'mock-plugin'))

      ident = OpenShift::Runtime::Ident.new('redhat', 'mock', '0.1')
      @model.deconfigure(ident) if File.exist?(File.join(@container.container_dir, 'mock'))

      FileUtils.rm_rf(File.join(@container.container_dir, 'git'))
      Mocha::Mockery.instance.stubba.unstub_all
    end

    def after_teardown
      %x(restorecon -rv #{@container.container_dir})
      @container.destroy
    end

    def capture_stdout(&block)
      old = $stdout
      $stdout = fake = StringIO.new
      block.call
      fake.string
    ensure
      $stdout = old
    end

    def test_metrics
      ident = OpenShift::Runtime::Ident.new('redhat', 'mock-plugin', '0.1')
      @model.configure(ident)

      ident = OpenShift::Runtime::Ident.new('redhat', 'mock', '0.1')
      @model.configure(ident)

      hooks_dir = PathUtils.join(@container.container_dir, %w(app-root runtime repo .openshift action_hooks))
      FileUtils.mkdir_p(hooks_dir)

      hook = PathUtils.join(hooks_dir, 'metrics')
      File.open(hook, 'w', 0755) do |f|
        f.write <<EOF
#!/bin/bash
echo 'from_app=1'
EOF
      end

      output = capture_stdout { @container.metrics }

      %w(mock mock-plugin).each do |cart|
        assert_match /type=metric cart=#{cart} appName=#{@container.application_name} gear=#{@container.uuid} app=#{@container.application_uuid} ns=#{@container.namespace} uptime=[0-9.]+/, output
      end

      assert_match /type=metric appName=#{@container.application_name} gear=#{@container.uuid} app=#{@container.application_uuid} ns=#{@container.namespace} from_app=1/, output
    end

  end
end
