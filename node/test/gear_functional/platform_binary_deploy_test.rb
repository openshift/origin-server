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

  def test_binary_deploy
    binary_deploy_test([ @framework_cartridge ])
  end

  def test_binary_hot_deploy
    options = {}
    options[:hot_deploy] = true
    binary_deploy_test([ @framework_cartridge ],options)
  end

  def test_rest_api_binary_deployment_to_scaled_app
    options = {}
    options[:scaling] = true
    use_the_rest_api_binary_deploy_app_test([ @framework_cartridge ], options)
  end

  def test_rest_api_hot_binary_deployment_to_scaled_app
    options = {}
    options[:scaling] = true
    options[:hot_deploy] = true
    use_the_rest_api_binary_deploy_app_test([ @framework_cartridge ], options)
  end

  def test_rest_api_binary_deployment_to_nonscaled_app
    options = {}
    options[:scaling] = false
    use_the_rest_api_binary_deploy_app_test([ @framework_cartridge ], options)
  end

  def test_rest_api_hot_binary_deployment_to_nonscaled_app
    options = {}
    options[:scaling] = false
    options[:hot_deploy] = true
    use_the_rest_api_binary_deploy_app_test([ @framework_cartridge ], options)
  end

  def binary_deploy_test(cartridges, options = {})
    scaling = !!options[:scaling]
    hot_deploy = !!options[:hot_deploy]
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
    cart_dir=wrap_control_script(cartridges[0],app_id2)    
    @api.add_ssh_key(app_id2, app_name2)
    @api.configure_application(app_name2, deployment_type: 'binary')
    @api.deploy_artifact(app_id2, app_name2, artifact_path, hot_deploy)

    @api.assert_http_title_for_app(app_name2, @namespace, CHANGED_TITLE, "Check for changed title in second app failed", 5)
    puts "checking for last stop"
    if hot_deploy && File.exist?("#{cart_dir}/last_stop")
      flunk ("Cartridge should not have been restarted for hot_deploy=true")
    end
  end

  def use_the_rest_api_binary_deploy_app_test(cartridges, options = {})
    scaling = !!options[:scaling]
    hot_deploy = !!options[:hot_deploy]

    app_name                = "app#{@api.random_string}"
    v1_tgz_file_name        = "#{app_name}v1.tgz"
    v2_tgz_file_name        = "#{app_name}v2.tgz"
    deploy_target_app_name  = "deploytargetapp#{@api.random_string}"

    @api.up_gears

    framework = cartridges[0]

    # 1) create a scaled app
    app_id = @api.create_application(app_name, cartridges, scaling)
    @api.add_ssh_key(app_id, app_name)
    @api.assert_http_title_for_app(app_name, @namespace, DEFAULT_TITLE)

    # 2) Clone the app repo
    @api.clone_repo(app_id)

    # 3) Change the app's title
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)
    @api.assert_http_title_for_app(app_name, @namespace, CHANGED_TITLE)

    # 4) save the snapshot (s1) and copy to the local apache  /var/www/html
    @api.save_deployment_snapshot_for_app(app_id, v1_tgz_file_name)
    @api.copy_file_to_apache(v1_tgz_file_name)

    # 5) change the app's title and confirm it
    @api.change_title(VERSION_TWO_TITLE, app_name, app_id, framework)
    @api.assert_http_title_for_app(app_name, @namespace, VERSION_TWO_TITLE)

    # 6) take a snapshot of the app
    @api.save_deployment_snapshot_for_app(app_id, v2_tgz_file_name)

    # 7) copy new snapshot (s2) to the local apache /var/www/html
    @api.copy_file_to_apache(v2_tgz_file_name)

    # 8) create a new app
    app_id2 = @api.create_application(deploy_target_app_name, cartridges, scaling)
    cart_dir=wrap_control_script(cartridges[0],app_id2)    

    # 9) configure the app as a binary deployment type
    @api.configure_application(deploy_target_app_name, deployment_type: 'binary')
    @api.add_ssh_key(app_id2, deploy_target_app_name)
    @api.assert_http_title_for_app(deploy_target_app_name, @namespace, DEFAULT_TITLE)

    # 10) use the rest api to deploy the s2 artifact to the new app
    @api.deploy_binary_artifact_using_rest_api(deploy_target_app_name, "http://localhost:81/#{v2_tgz_file_name}", hot_deploy)

    # 11) confirm the title is correct
    @api.assert_http_title_for_app(app_name, @namespace, VERSION_TWO_TITLE)

    # 12) use the rest api to deploy the s1 artifact to the new app
    @api.deploy_binary_artifact_using_rest_api(deploy_target_app_name, "http://localhost:81/#{v1_tgz_file_name}", hot_deploy)

    # 13) confirm the title is correct
    @api.assert_http_title_for_app(deploy_target_app_name, @namespace, CHANGED_TITLE)
    puts "checking for last stop"
    if hot_deploy && File.exist?("#{cart_dir}/last_stop")
      flunk ("Cartridge should not have been restarted for hot_deploy=true")
    end

  end # use_the_rest_api_binary_deploy_to_scaled_app_test

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
