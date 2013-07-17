#!/usr/bin/env oo-ruby
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
#
# Test the OpenShift application_container model
#
require_relative '../test_helper'
require 'fileutils'
require 'yaml'

module OpenShift
  ;
end

class BuildLifecycleTest < OpenShift::NodeTestCase

  def setup
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    # Set up the container
    @gear_uuid = "5503"
    @user_uid  = "5503"
    @app_name  = 'ApplicationContainerTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"

    @cartridge_model = mock()
    OpenShift::Runtime::V2CartridgeModel.stubs(:new).returns(@cartridge_model)

    @state = mock()
    OpenShift::Runtime::Utils::ApplicationState.stubs(:new).returns(@state)

    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil)

    @frontend = mock('OpenShift::Runtime::FrontendHttpServer')
    OpenShift::Runtime::FrontendHttpServer.stubs(:new).returns(@frontend)
  end

  def test_pre_receive_default_builder
    @cartridge_model.expects(:builder_cartridge).returns(nil)

    @container.expects(:stop_gear).with(user_initiated: true, hot_deploy: nil, out: $stdout, err: $stderr)

    @container.pre_receive(out: $stdout, err: $stderr)
  end

  def test_post_receive_default_builder
    repository = mock()

    OpenShift::Runtime::ApplicationRepository.expects(:new).returns(repository)

    @cartridge_model.expects(:builder_cartridge).returns(nil)

    primary = mock()
    @cartridge_model.stubs(:primary_cartridge).returns(primary)

    @cartridge_model.expects(:do_control).with('pre-repo-archive',
                                                primary,
                                                out:                       $stdout,
                                                err:                       $stderr,
                                                pre_action_hooks_enabled:  false,
                                                post_action_hooks_enabled: false)

    repository.expects(:archive)

    @container.expects(:build).with(out: $stdout, err: $stderr)
    @container.expects(:deploy).with(out: $stdout, err: $stderr)
    @container.expects(:report_build_analytics)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_pre_receive_builder_cart
    builder = mock()
    @cartridge_model.expects(:builder_cartridge).returns(builder)

    @cartridge_model.expects(:do_control).with('pre-receive', builder, out: $stdout, err: $stderr)

    @container.pre_receive(out: $stdout, err: $stderr)
  end

  def test_post_receive_builder_cart
    builder = mock()
    @cartridge_model.expects(:builder_cartridge).returns(builder)

    @cartridge_model.expects(:do_control).with('post-receive', builder, out: $stdout, err: $stderr)

    @container.expects(:report_build_analytics)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_build_success
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary).times(3)

    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary,
                                               pre_action_hooks_enabled:  false,
                                               post_action_hooks_enabled: false,
                                               out:                       $stdout,
                                               err:                       $stderr)
                                          .returns('update-configuration|')

    @cartridge_model.expects(:do_control).with('pre-build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                          .returns('pre-build|')

    @cartridge_model.expects(:do_control).with('build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('build')

    output = @container.build(out: $stdout, err: $stderr)

    assert_equal "update-configuration|pre-build|build", output
  end

  def test_deploy_no_web_proxy_success
    @state.expects(:value=).with(OpenShift::Runtime::State::DEPLOYING)

    primary = mock()
    @cartridge_model.stubs(:primary_cartridge).returns(primary)
    @cartridge_model.stubs(:web_proxy).returns(nil)

    @container.expects(:start_gear).with(secondary_only: true, user_initiated: true, hot_deploy: nil, out: $stdout, err: $stderr).returns('start_gear|')

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy|')

    @container.expects(:start_gear).with(primary_only: true, user_initiated: true, hot_deploy: nil, out: $stdout, err: $stderr).returns('start_gear|')

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('post-deploy')

    output = @container.deploy(out: $stdout, err: $stderr)

    assert_equal "start_gear|deploy|start_gear|post-deploy", output
  end

  def test_deploy_web_proxy_success
    @state.expects(:value=).with(OpenShift::Runtime::State::DEPLOYING)

    primary = mock()
    @cartridge_model.stubs(:primary_cartridge).returns(primary)
    proxy = mock()
    @cartridge_model.stubs(:web_proxy).returns(proxy)

    @container.expects(:start_gear).with(secondary_only: true, user_initiated: true, hot_deploy: nil, out: $stdout, err: $stderr).returns("start_gear|")

    @cartridge_model.expects(:do_control).with('deploy',
                                               proxy,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy|')

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy|')

    @container.expects(:start_gear).with(primary_only: true, user_initiated: true, hot_deploy: nil, out: $stdout, err: $stderr).returns("start_gear|")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('post-deploy')

    output = @container.deploy(out: $stdout, err: $stderr)

    assert_equal "start_gear|deploy|deploy|start_gear|post-deploy", output
  end


  def test_remote_deploy_success
    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)
    
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary,
                                               pre_action_hooks_enabled:  false,
                                               post_action_hooks_enabled: false,
                                               out:                       $stdout,
                                               err:                       $stderr)
                                          .returns('')

    @container.expects(:deploy).with(out: $stdout, err: $stderr)

    @container.remote_deploy(out: $stdout, err: $stderr)
  end
end
