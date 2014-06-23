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
        @config.stubs(:get).with('REPORT_BUILD_ANALYTICS').returns(false)


        script_dir     = File.expand_path(File.dirname(__FILE__))
        cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')
        raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)
        @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

        @uuid = SecureRandom.uuid.gsub(/-/, '')

        begin
          %x(userdel -f #{Etc.getpwuid(@uid).name})
        rescue ArgumentError
        end

        @container = Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "NodeFunctionalTest",
                                                       "NodeFunctionalTest", "functional-test")
        @container.create(@secret_token)
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
          OpenShift::Runtime::Node.set_quota(@uuid, results[:blocks_used] - 1, '')
        end
      end

      def test_set_quota_fail_inodes
        results = Runtime::Node.get_quota(@uuid)

        assert_raises(NodeCommandException) do
          OpenShift::Runtime::Node.set_quota(@uuid, results[:blocks_used], results[:inodes_used] - 1)
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
