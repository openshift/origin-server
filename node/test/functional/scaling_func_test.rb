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
require 'socket'
require 'net/http'
require 'fileutils'
require 'restclient/request'

class ScalingFuncTest < OpenShift::NodeBareTestCase
  def setup
    @tester = ::OpenShift::Runtime::DeploymentTester.new
    @tester.setup

    @framework_cartridge = ENV['CART_TO_TEST'] || 'mock-0.1'
    logger.info("Using framework cartridge: #{@framework_cartridge}")
  end

  def teardown
    @tester.teardown unless @tester.nil?
  end

  # def test_unscaled_add_jenkins_no_keep()
  #   create_jenkins
  #   basic_build_test([@framework_cartridge], add_jenkins: true)
  # end

  def test_unscaled
    @tester.basic_build_test([@framework_cartridge], keep_deployments: 3)
  end

  def test_unscaled_jenkins
    @tester.create_jenkins
    @tester.basic_build_test([@framework_cartridge, 'jenkins-client-1'], keep_deployments: 3)
  end

  def test_scaled
    if @framework_cartridge == 'zend-5.6'
      return
    end

    @tester.basic_build_test([@framework_cartridge], scaling: true, keep_deployments: 3)
  end

  def test_scaled_jenkins
    if @framework_cartridge == 'zend-5.6'
      return
    end

    @tester.up_gears
    @tester.create_jenkins
    @tester.basic_build_test([@framework_cartridge, 'jenkins-client-1'], scaling: true, keep_deployments: 3)
  end
end
