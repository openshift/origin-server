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

require 'rubygems'
require 'test/unit'
require 'mocha/setup'
require 'logger'
require 'securerandom'
require 'digest/sha1'

require_relative '../lib/openshift-origin-node'
require_relative '../lib/openshift-origin-node/utils/node_logger'
require_relative '../lib/openshift-origin-node/utils/logger/stdout_logger'
require_relative 'support/support'

module OpenShift

  # A bare test case class for tests which need to start
  # without any previous stubs or setup
  class NodeBareTestCase < MiniTest::Unit::TestCase
    include Test::Unit::Assertions
    include OpenShift::Runtime::NodeLogger

    alias assert_raise assert_raises

    def before_setup
      OpenShift::Runtime::NodeLogger.set_logger(OpenShift::Runtime::NodeLogger::StdoutLogger.new)
      super
    end

    def assert_path_exist(path, message=nil)
      assert File.exist?(path), "#{path} expected to exist #{message}"
    end

    def refute_path_exist(path, message=nil)
      assert (not File.exists?(path)), "#{path} expected to not exist #{message}"
    end
  end

  class NodeTestCase < NodeBareTestCase
    def before_setup
      @config = mock('OpenShift::Config')
      @config.stubs(:get).returns(nil)
      @config.stubs(:get).with("CONTAINERIZATION_PLUGIN").returns('openshift-origin-container-selinux')
      @config.stubs(:get_bool).with("no_overcommit_active", false).returns(false)
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

      @secret_token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256)).to_s

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

  class FrontendHttpPluginTestCase < NodeBareTestCase

    # Classes inheriting FrontendHttpPluginTestCase should do the following:
    #  1. Instantiate their class in setup and assign to @plugin
    #  2. Set @elements, @aliases, @ssl_certs
    #  3. Add @config variables
    #  4. Use the exercise_* routines to drive functional tests

    def before_setup
      @container_uuid = SecureRandom.uuid.gsub('-', '')
      @container_name = "test" + SecureRandom.uuid.gsub('-', '')[0,8]
      @domain = "example.com"
      @namespace = "testspace"

      @fqdn = "#{@container_name}-#{@namespace}.#{@domain}"

      @config = mock('OpenShift::Config')
      @config.stubs(:get).returns(nil)
      OpenShift::Config.stubs(:new).returns(@config)

      super
    end

    # Is the plugin available to the FrontendHttpServer module
    def exercise_plugin_is_available
      assert (not @plugin.nil?), "Plugin was not initialized"

      assert ::OpenShift::Runtime::Frontend::Http::Plugins.plugins.include?(@plugin.class), "Plugins should include #{@plugin.class}"
    end

    def exercise_connections_api
      yield(:pre_set) if block_given?
      @plugin.connect(*@elements)
      yield(:set) if block_given?

      assert_equal @elements.sort, @plugin.connections.sort, "Connections should return the same as input"

      yield(:pre_unset) if block_given?
      @plugin.disconnect(*(@elements.map { |a,b,c| a }))
      yield(:unset) if block_given?

      assert_equal [], @plugin.connections, "Connections should be empty"
    end

    def exercise_aliases_api
      yield(:pre_set) if block_given?
      @aliases.each do |server_alias|
        @plugin.add_alias(server_alias)
      end
      yield(:set) if block_given?

      assert_equal @aliases.sort, @plugin.aliases.sort, "Aliases should be set to #{@aliases}"

      yield(:pre_unset) if block_given?
      @aliases.each do |server_alias|
        @plugin.remove_alias(server_alias)
      end
      yield(:unset) if block_given?

      assert_equal [], @plugin.aliases, "Aliases should be empty"
    end

    def exercise_ssl_api
      yield(:pre_set) if block_given?
      @ssl_certs.each do |ssl_cert, ssl_key, server_alias|
        @plugin.add_alias(server_alias)
        @plugin.add_ssl_cert(ssl_cert, ssl_key, server_alias)
      end
      yield(:set) if block_given?

      assert_equal @ssl_certs.sort, @plugin.ssl_certs.sort, "SSL certs should be set to #{@ssl_certs}"

      yield(:pre_unset) if block_given?
      @ssl_certs.each do |ssl_cert, ssl_key, server_alias|
        @plugin.remove_ssl_cert(server_alias)
        @plugin.remove_alias(server_alias)
      end
      yield(:unset) if block_given?

      assert_equal [], @plugin.ssl_certs, "SSL certs should be empty"
    end

    def exercise_idle_api
      yield(:pre_set) if block_given?
      @plugin.idle
      yield(:set) if block_given?

      assert @plugin.idle?, "Idle should be set"

      yield(:pre_unset) if block_given?
      @plugin.unidle
      yield(:unset) if block_given?

      assert (not @plugin.idle?), "Idle should not be set"
    end

    def exercise_sts_api
      yield(:pre_set) if block_given?
      @plugin.sts
      yield(:set) if block_given?

      assert @plugin.get_sts, "STS should be set"

      yield(:pre_unset) if block_given?
      @plugin.no_sts
      yield(:unset) if block_given?

      assert (not @plugin.get_sts), "STS should not be set"
    end

  end
end
