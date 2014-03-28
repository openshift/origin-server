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

class PlatformDeploymentIntegrityTest < OpenShift::NodeBareTestCase
  DEFAULT_TITLE     = "Welcome to OpenShift"
  CHANGED_TITLE     = "Test1"
  VERSION_TWO_TITLE = "Test2"

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

  def test_git_push
    deployment_integrity_check_test([ @framework_cartridge ])
  end

  def deployment_integrity_check_test(cartridges, options = {})
    scaling = !!options[:scaling]

    app_name = "app#{@api.random_string}"
    framework = cartridges[0]

    app_id = @api.create_application(app_name, cartridges, scaling)
    @api.add_ssh_key(app_id, app_name)
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)

    `unlink /var/lib/openshift/#{app_id}/app-deployments/current`
    `rm -rf /var/lib/openshift/#{app_id}/app-deployments/by-id`

    @api.clone_repo(app_id)
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)
    @api.assert_http_title_for_app(app_name, @namespace, CHANGED_TITLE)
  end
end
