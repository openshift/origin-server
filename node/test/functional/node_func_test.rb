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
require 'openshift-origin-node/model/node'
require 'securerandom'

class NodeTest < OpenShift::NodeTestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    super

    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0]))
    File.stubs(:exist?).returns(true)

    OpenShift::Runtime::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        multiple_yields(["#{@path}/redhat-crtest/1.2/metadata/manifest.yml"])

    OpenShift::Runtime::CartridgeRepository.instance.clear
    OpenShift::Runtime::CartridgeRepository.instance.load
  end

  def test_get_cartridge_list
    buffer = OpenShift::Runtime::Node.get_cartridge_list(true, true, true)
    refute_nil buffer

    assert_equal %Q(CLIENT_RESULT: [\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.1'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.1\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.2'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.3'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\"]),
                 buffer
  end

  MANIFESTS = [
      %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: redhat
        Group-Overrides:
          - components:
            - crtest-0.3
            - web_proxy
        Version-Overrides:
          '0.1':
            Group-Overrides:
              - components:
                - crtest-0.1
                - web_proxy
          '0.2':
            Group-Overrides:
              - components:
                - crtest-0.2
                - web_proxy
      },
  ]
end

module OpenShift
  module Runtime

    class NodeTestSetQuota < OpenShift::NodeTestCase

      GEAR_BASE_DIR = '/var/lib/openshift'

      def before_setup
        super

        @uid = 5994

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

        @uuid = %x(uuidgen -r |sed -e s/-//g).chomp

        begin
          %x(userdel -f #{Etc.getpwuid(@uid).name})
        rescue ArgumentError
        end

        @container = Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "NodeFunctionalTest",
                                                       "NodeFunctionalTest", "functional-test")
        @container.create
      end

      def after_teardown
        @container.destroy
      end

      def test_set_quota_pass
        OpenShift::Runtime::Node.set_quota(@uuid, '300000', '50000')
      end

      def test_set_quota_fail_quota
        results = Runtime::Node.get_quota(@uuid)
        assert_raises(NodeCommandException) do
          OpenShift::Runtime::Node.set_quota(@uuid, (results[1].to_s.to_i - 1), '')
        end
      end

      def test_set_quota_fail_inodes
        results = Runtime::Node.get_quota(@uuid)

        assert_raises(NodeCommandException) do
          OpenShift::Runtime::Node.set_quota(@uuid, results[1], (results[4].to_s.to_i - 1))
        end
      end
    end

    def test_get_quota_pass
      results = OpenShift::Runtime::Node.get_quota(@uuid)
      refute_nil results
      refute_empty results
    end
  end
end
