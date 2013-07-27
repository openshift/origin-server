#--
# Copyright 2010 Red Hat, Inc.
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

require_relative 'coverage_helper'

require 'test/unit'
require 'mocha/setup'
require 'logger'

require_relative '../lib/openshift-origin-node'
require_relative '../lib/openshift-origin-node/utils/logger/stdout_logger'

module OpenShift

  # A bare test case class for tests which need to start
  # without any previous stubs or setup
  class NodeBareTestCase < MiniTest::Unit::TestCase
    alias assert_raise assert_raises

    def assert_path_exist(path, message=nil)
      assert File.exist?(path), "#{path} expected to exist #{message}"
    end

    def refute_path_exist(path, message=nil)
      assert (not File.exists?(path)), "#{path} expected to not exist #{message}"
    end
  end

  class NodeTestCase < NodeBareTestCase
    def before_setup
      log_config = mock()
      log_config.stubs(:get).with("PLATFORM_LOG_CLASS").returns("StdoutLogger")
      ::OpenShift::Runtime::NodeLogger.stubs(:load_config).returns(log_config)

      @config = mock('OpenShift::Config')
      @config.stubs(:get).returns(nil)
      @config.stubs(:get).with("CONTAINERIZATION_PLUGIN").returns('openshift-origin-container-selinux')
      OpenShift::Config.stubs(:new).returns(@config)

      @cgroups_mock = mock('OpenShift::Runtime::Utils::Cgroups')
      OpenShift::Runtime::Utils::Cgroups.stubs(:new).returns(@cgroups_mock)
      @cgroups_mock.stubs(:create)
      @cgroups_mock.stubs(:delete)
      @cgroups_mock.stubs(:boost).yields(:boosted)
      @cgroups_mock.stubs(:freeze).yields(:frozen)
      @cgroups_mock.stubs(:thaw).yields(:thawed)
      @cgroups_mock.stubs(:processes).returns([])

      @tc_mock = mock('OpenShift::Runtime::Utils::TC')
      OpenShift::Runtime::Utils::TC.stubs(:new).returns(@tc_mock)
      @tc_mock.stubs(:startuser)
      @tc_mock.stubs(:stopuser)
      @tc_mock.stubs(:deluser)

      super
    end

    def after_teardown
      super
    end

    # NOTE:
    # #before_setup creates an archive with just the 'mock-plugin' cartridge
    # for testing.
    # Since this plugin's Cartridge-Vendor is 'redhat', which is reserved
    # under certain circumstances (i.e., when cartridge is installed via URL).
    # We need to tweak the Cartridge-Vendor value as required by tests.
    def change_cartridge_vendor_of(manifest, vendor = 'redhat2')
      manifest << "Cartridge-Vendor: #{vendor}"
    end
  end
end
