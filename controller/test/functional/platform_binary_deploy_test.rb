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

require 'socket'
require 'net/http'
require 'fileutils'
require 'restclient/request'

def artifact_name
  framework = ENV['CART_TO_TEST'] || 'mock-0.1'
  return "binary_#{framework}.tar.gz"
end

def artifact_path
  return "/tmp/#{artifact_name}"
end

class PlatformBinaryDeployTest < OpenShift::CartridgeTestCase
  DEFAULT_TITLE = "Welcome to OpenShift"
  CHANGED_TITLE = "Test1"

  def setup
    @framework_cartridge = ENV['CART_TO_TEST'] || 'mock-0.1'
    logger.info("Using framework cartridge: #{@framework_cartridge}")

    @api = FunctionalApi.new
    @namespace = @api.create_domain

    # initiate testing environment
    create_artifact([ @framework_cartridge ]) unless File.exists?(artifact_path)
  end

  def teardown
    unless ENV['PRESERVE']
      @api.delete_domain unless @api.nil?
    end
  end

  def create_artifact(cartridges)
    framework = cartridges[0]
    app_name = "app#{@api.random_string}"

    app_id = @api.create_application(app_name, cartridges, false)
    @api.add_ssh_key(app_id, app_name)
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)
    @api.clone_repo(app_id)
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)
    @api.save_deployment_snapshot_for_app(app_id, artifact_path)
    @api.clean_binary_archive(artifact_path, framework)
  end

  def test_binary_deploy
    binary_deploy_test([ @framework_cartridge ])
  end

  def test_binary_hot_deploy
    options = {}
    options[:hot_deploy] = true
    binary_deploy_test([ @framework_cartridge ], options)
  end

  def test_rest_api_binary_deployment_to_scaled_app
    options = {}
    options[:scaling] = true
    rest_api_binary_deploy_test([ @framework_cartridge ], options)
  end

  def test_rest_api_hot_binary_deployment_to_scaled_app
    options = {}
    options[:scaling] = true
    options[:hot_deploy] = true
    rest_api_binary_deploy_test([ @framework_cartridge ], options)
  end

  def test_rest_api_binary_deployment_to_nonscaled_app
    options = {}
    options[:scaling] = false
    rest_api_binary_deploy_test([ @framework_cartridge ], options)
  end

  def test_rest_api_hot_binary_deployment_to_nonscaled_app
    options = {}
    options[:scaling] = false
    options[:hot_deploy] = true
    rest_api_binary_deploy_test([ @framework_cartridge ], options)
  end

  def binary_deploy_test(cartridges, options = {})
    scaling = !!options[:scaling]
    hot_deploy = !!options[:hot_deploy]
    app_name = "app#{@api.random_string}"

    @api.up_gears
    app_id = @api.create_application(app_name, cartridges, scaling)
    cart_dir = wrap_control_script(cartridges[0], app_id)
    @api.add_ssh_key(app_id, app_name)

    @api.configure_application(app_name, deployment_type: 'binary')
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)

    @api.deploy_artifact(app_id, app_name, artifact_path, hot_deploy)
    sleep 5 if hot_deploy # give the app time to start properly
    @api.assert_http_title_for_app(app_name, @namespace, CHANGED_TITLE, "Check for changed title in second app failed")

    if hot_deploy && File.exist?("#{cart_dir}/last_stop")
      flunk("Cartridge should not have been restarted for hot_deploy=true")
    end
  end

  def rest_api_binary_deploy_test(cartridges, options = {})
    scaling = !!options[:scaling]
    hot_deploy = !!options[:hot_deploy]
    app_name  = "app#{@api.random_string}"

    @api.up_gears
    app_id = @api.create_application(app_name, cartridges, scaling)
    cart_dir = wrap_control_script(cartridges[0], app_id)
    @api.add_ssh_key(app_id, app_name)
    @api.copy_file_to_apache(artifact_path)

    @api.configure_application(app_name, deployment_type: 'binary')
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)

    @api.deploy_binary_artifact_using_rest_api(app_name, "http://localhost:81/#{artifact_name}", hot_deploy)
    sleep 5 if hot_deploy # give the app time to start properly
    @api.assert_http_title_for_app(app_name, @namespace, CHANGED_TITLE, "Check for changed title in second app failed")

    if hot_deploy && File.exist?("#{cart_dir}/last_stop")
      flunk("Cartridge should not have been restarted for hot_deploy=true")
    end
  end

  def wrap_control_script(cartridge,app_id)
    cart_type=cartridge.sub(/(.*?)-.*/,'\1')
    cart_dir="/var/lib/openshift/#{app_id}/#{cart_type}"
    control_wrapper = <<-EOS
      #!/bin/bash
      case "$1" in
        start)     date +%s > last_start;;
        stop)      date +%s > last_stop;;
        restart)   date +%s > last_restart;;
      esac
      #{cart_dir}/bin/wrapped_control $1
    EOS

    `mv #{cart_dir}/bin/control #{cart_dir}/bin/wrapped_control`
    File.write("#{cart_dir}/bin/control",control_wrapper)
    `chmod a+x #{cart_dir}/bin/control`
    cart_dir
  end

end

MiniTest::Unit.after_tests do
  # clean testing environment
  File.delete(artifact_path) if File.exists?(artifact_path)
end
