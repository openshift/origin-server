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
require 'mocha'

require_relative '../lib/openshift-origin-node'

module OpenShift
  module NodeLogger

    def logger
      NodeLogger.logger
    end

    def self.logger
      @logger ||= begin
        logger       = Logger.new(STDOUT)
        logger.level = Logger::DEBUG
        logger
      end
    end

    def trace_logger
      NodeLogger.trace_logger
    end

    def self.trace_logger
      @trace_logger ||= begin
        logger       = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end
    end
  end

  class V2SdkTestCase < MiniTest::Unit::TestCase
    alias assert_raise assert_raises

    def assert_path_exist(path, message=nil)
      assert File.exist?(path),  "#{path} expected to exist #{message}"
    end

    def refute_path_exist(path, message=nil)
      assert (not File.exists?(path)), "#{path} expected to not exist #{message}"
    end

    def before_setup
      OpenShift::Utils::Sdk.stubs(:new_sdk_app?).returns(true)
      OpenShift::Utils::Sdk.stubs(:node_default_model).returns(:v2)
      super
    end

    def after_teardown
      OpenShift::Utils::Sdk.unstub(:new_sdk_app?)
      OpenShift::Utils::Sdk.unstub(:node_default_model)
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
