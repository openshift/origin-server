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

class PlatformBinaryDeployTest < OpenShift::NodeBareTestCase
  DEFAULT_TITLE     = "Welcome to OpenShift"
  CHANGED_TITLE     = "Test1"

  def setup
    @framework_cartridge = ENV['CART_TO_TEST'] || 'mock-0.1'
    logger.info("Using framework cartridge: #{@framework_cartridge}")

    @api = FunctionalApi.new
    @namespace = @api.create_domain
  end

  def teardown
    unless ENV['PRESERVE']
      @api.delete_domain unless @api.nil?
    end
  end

  def test_binary_deploy
    binary_deploy_test([ @framework_cartridge ])
  end

  def binary_deploy_test(cartridges, options = {})
    scaling = !!options[:scaling]

    @api.up_gears

    app_name = "app#{@api.random_string}"
    framework = cartridges[0]

    app_id = @api.create_application(app_name, cartridges, scaling)
    @api.add_ssh_key(app_id, app_name)
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)

    @api.clone_repo(app_id)
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)
    artifact_path = @api.archive_deployment(app_id)

    app_name2 = "#{app_name}2"
    app_id2 = @api.create_application(app_name2, cartridges, scaling)
    @api.add_ssh_key(app_id2, app_name2)
    @api.deploy_artifact(app_id2, artifact_path)

    @api.assert_http_title_for_app(app_name2, @namespace, CHANGED_TITLE)
  end
end