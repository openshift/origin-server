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
require 'openshift-origin-node/model/ident'

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

    @hourglass = mock()
    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil, @hourglass)

    @frontend = mock('OpenShift::Runtime::FrontendHttpServer')
    OpenShift::Runtime::FrontendHttpServer.stubs(:new).returns(@frontend)

    @ident = OpenShift::Runtime::Ident.new('redhat', 'mock', '0.1')
  end

  def test_pre_receive_default_builder
    [nil, true].each do |init|
      @cartridge_model.expects(:builder_cartridge).returns(nil)

      @container.expects(:stop_gear).with(user_initiated: true,
                                          hot_deploy: false,
                                          exclude_web_proxy: true,
                                          init: init,
                                          out: $stdout,
                                          err: $stderr)
      @container.expects(:check_deployments_integrity).with(has_entry(out: $stdout))
      deployment_datetime = 'now'
      @container.expects(:create_deployment_dir).returns(deployment_datetime)

      gear_env = {a: 1}
      OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

      metadata = mock()
      @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)

      git_ref = 'ref'
      hot_deploy = false
      force_clean_build = true
      metadata.expects(:git_ref=).with(git_ref)
      metadata.expects(:hot_deploy=).with(hot_deploy)
      metadata.expects(:force_clean_build=).with(force_clean_build)
      metadata.expects(:save)


      @container.pre_receive(out: $stdout, err: $stderr, ref: git_ref, hot_deploy: hot_deploy, force_clean_build: force_clean_build, init: init)
    end
  end

  def test_pre_receive_default_builder_no_git_ref
    [nil, true].each do |init|
      @cartridge_model.expects(:builder_cartridge).returns(nil)

      @container.expects(:stop_gear).with(user_initiated: true,
                                          hot_deploy: false,
                                          exclude_web_proxy: true,
                                          init: init,
                                          out: $stdout,
                                          err: $stderr)
      @container.expects(:check_deployments_integrity).with(has_entry(out: $stdout))
      deployment_datetime = 'now'
      @container.expects(:create_deployment_dir).returns(deployment_datetime)

      gear_env = {a: 1}
      OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

      metadata = mock()
      @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)

      hot_deploy = false
      force_clean_build = true
      metadata.expects(:git_ref=).with('master')
      metadata.expects(:hot_deploy=).with(hot_deploy)
      metadata.expects(:force_clean_build=).with(force_clean_build)
      metadata.expects(:save)


      @container.pre_receive(out: $stdout, err: $stderr, hot_deploy: hot_deploy, force_clean_build: force_clean_build, init: init)
    end
  end

  def test_pre_receive_default_builder_deployment_branch_env_var
    [nil, true].each do |init|
      @cartridge_model.expects(:builder_cartridge).returns(nil)

      @container.expects(:stop_gear).with(user_initiated: true,
                                          hot_deploy: false,
                                          exclude_web_proxy: true,
                                          init: init,
                                          out: $stdout,
                                          err: $stderr)
      @container.expects(:check_deployments_integrity).with(has_entry(out: $stdout))
      deployment_datetime = 'now'
      @container.expects(:create_deployment_dir).returns(deployment_datetime)

      gear_env = {'OPENSHIFT_DEPLOYMENT_BRANCH' => 'foo'}
      OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

      metadata = mock()
      @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)

      hot_deploy = false
      force_clean_build = true
      metadata.expects(:git_ref=).with('foo')
      metadata.expects(:hot_deploy=).with(hot_deploy)
      metadata.expects(:force_clean_build=).with(force_clean_build)
      metadata.expects(:save)


      @container.pre_receive(out: $stdout, err: $stderr, hot_deploy: hot_deploy, force_clean_build: force_clean_build, init: init)
    end
  end

  def test_post_receive_default_builder_nonscaled
    @cartridge_model.expects(:web_proxy).returns(nil)
    @container.expects(:child_gear_ssh_urls).never
    @container.expects(:sync_git_repo).never
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

    deployment_datetime = "abc"
    @container.expects(:latest_deployment_datetime).returns(deployment_datetime)

    metadata = mock()
    @container.expects(:deployment_metadata_for).returns(metadata)

    git_ref = 'master'
    metadata.expects(:git_ref).returns(git_ref)
    git_sha1 = 'abcd1234'
    repository.expects(:get_sha1).with(git_ref).returns(git_sha1)
    metadata.expects(:git_sha1=).with(git_sha1)
    metadata.expects(:save)

    repository.expects(:archive).with(PathUtils.join(@container.container_dir, 'app-root', 'runtime', 'repo'), git_ref)
    deployment_datetime = "abc"

    options = {
      out: $stdout,
      err: $stderr,
      deployment_datetime: deployment_datetime,
      proxy_cart: nil
    }
    @container.expects(:build).with(options)
    @container.expects(:prepare).with(options)
    @container.expects(:distribute).with(options).returns(status: 'success')
    @container.expects(:activate).with(options).returns(status: 'success')

    @container.expects(:report_build_analytics)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_post_receive_default_builder_scaled
    proxy_cart = mock()
    @cartridge_model.expects(:web_proxy).returns(proxy_cart)
    gear_env = {a: 1, b: 2}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    proxy_ssh_urls = %w(uuid1@localhost uuid2@localhost uuid3@localhost)
    @container.expects(:child_gear_ssh_urls).with(:proxy).returns(proxy_ssh_urls)
    @container.expects(:sync_git_repo).with(proxy_ssh_urls, gear_env)

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

    deployment_datetime = "abc"
    @container.expects(:latest_deployment_datetime).returns(deployment_datetime)

    metadata = mock()
    @container.expects(:deployment_metadata_for).returns(metadata)

    git_ref = 'master'
    metadata.expects(:git_ref).returns(git_ref)
    git_sha1 = 'abcd1234'
    repository.expects(:get_sha1).with(git_ref).returns(git_sha1)
    metadata.expects(:git_sha1=).with(git_sha1)
    metadata.expects(:save)

    repository.expects(:archive).with(PathUtils.join(@container.container_dir, 'app-root', 'runtime', 'repo'), git_ref)

    options = {
      out: $stdout,
      err: $stderr,
      deployment_datetime: deployment_datetime,
      proxy_cart: proxy_cart
    }
    @container.expects(:build).with(options)
    @container.expects(:prepare).with(options)
    @container.expects(:distribute).with(options).returns(status: 'success')
    @container.expects(:activate).with(options).returns(status: 'success')

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
    @cartridge_model.expects(:web_proxy).returns(nil)

    builder = mock()
    @cartridge_model.expects(:builder_cartridge).returns(builder)

    @cartridge_model.expects(:do_control).with('post-receive', builder, out: $stdout, err: $stderr)

    @container.expects(:report_build_analytics)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_build_ci_builder_success
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    deployment_datetime = "abc"
    @container.expects(:latest_deployment_datetime).returns(deployment_datetime)

    repository = mock()

    git_ref = 'master'
    git_sha1 = 'abcd1234'
    repository.expects(:get_sha1).with('master').returns(git_sha1)

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:git_sha1=).with(git_sha1)
    metadata.expects(:git_ref=).with(git_ref)
    metadata.expects(:hot_deploy=).with(false)
    metadata.expects(:force_clean_build=).with(false)
    metadata.expects(:save)

    metadata.expects(:force_clean_build).returns(false)
    metadata.expects(:git_ref).returns(git_ref)
    metadata.expects(:git_sha1).returns(git_sha1)

    @container.expects(:deployments_to_keep).with(anything()).returns(2)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

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

    output = @container.build(out: $stdout,
                              err: $stderr,
                              ref: git_ref,
                              hot_deploy: false,
                              force_clean_build: false,
                              git_repo: repository)
  end

  def test_build_platform_builder_success
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    deployment_datetime = "abc"

    git_ref = 'master'
    git_sha1 = 'abcd1234'

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)

    metadata.expects(:force_clean_build).returns(false)
    metadata.expects(:git_ref).returns(git_ref)
    metadata.expects(:git_sha1).returns(git_sha1)

    @container.expects(:deployments_to_keep).with(anything()).returns(2)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

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

    output = @container.build(out: $stdout,
                              err: $stderr,
                              hot_deploy: false,
                              force_clean_build: false,
                              deployment_datetime: deployment_datetime)
  end

  def test_build_platform_builder_success_force_clean_build
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    deployment_datetime = "abc"

    git_ref = 'master'
    git_sha1 = 'abcd1234'

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)

    metadata.expects(:force_clean_build).returns(true)

    @container.expects(:clean_runtime_dirs).with(dependencies:true, build_dependencies:true)
    cart1 = mock()
    cart2 = mock()
    @cartridge_model.expects(:each_cartridge).multiple_yields(cart1, cart2)
    @cartridge_model.expects(:create_dependency_directories).with(cart1)
    @cartridge_model.expects(:create_dependency_directories).with(cart2)

    @container.expects(:deployments_to_keep).with(anything()).returns(2)
    metadata.expects(:git_ref).returns(git_ref)
    metadata.expects(:git_sha1).returns(git_sha1)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

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

    output = @container.build(out: $stdout,
                              err: $stderr,
                              hot_deploy: false,
                              force_clean_build: true,
                              deployment_datetime: deployment_datetime)
  end

  def test_build_failure_keep_one_deployment
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    deployment_datetime = "abc"

    git_ref = 'master'
    git_sha1 = 'abcd1234'

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:force_clean_build).returns(false)
    metadata.expects(:git_ref).returns(git_ref)
    metadata.expects(:git_sha1).returns(git_sha1)

    @container.expects(:deployments_to_keep).with(anything()).returns(1)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

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
                                          .raises(OpenShift::Runtime::Utils::ShellExecutionException.new('foo'))

    @cartridge_model.expects(:do_control).with('build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .never()

    assert_raises(OpenShift::Runtime::Utils::ShellExecutionException) { @container.build(out: $stdout, err: $stderr, deployment_datetime: deployment_datetime, ref: git_ref, hot_deploy: false, force_clean_build: false) }
  end

  def test_build_failure_keep_multiple_deployments
    @state.expects(:value=).with(OpenShift::Runtime::State::BUILDING)

    deployment_datetime = "abc"

    git_ref = 'master'
    git_sha1 = 'abcd1234'

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:force_clean_build).returns(false)
    metadata.expects(:git_ref).returns(git_ref)
    metadata.expects(:git_sha1).returns(git_sha1)

    @container.expects(:deployments_to_keep).with(anything()).returns(2)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

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
                                          .raises(OpenShift::Runtime::Utils::ShellExecutionException.new('foo'))

    @cartridge_model.expects(:do_control).with('build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .never()

    metadata.expects(:hot_deploy).returns(false)
    @container.expects(:start_gear).with(has_entries(user_initiated: true, hot_deploy: false, out: $stdout, err: $stderr)).returns("bar")

    assert_raises(OpenShift::Runtime::Utils::ShellExecutionException) { @container.build(out: $stdout, err: $stderr, deployment_datetime: deployment_datetime, ref: git_ref, hot_deploy: false, force_clean_build: false) }
  end

  def test_remote_deploy_success
    deployment_datetime = "now"

    options = {
      out: $stdout,
      err: $stderr,
      deployment_datetime: deployment_datetime
    }

    @container.expects(:prepare).with(options)

    distribute_results = {
      status: 'success'
    }
    @container.expects(:distribute).with(options).returns(distribute_results)

    activate_results = {
      status: 'success'
    }
    @container.expects(:activate).with(options).returns(activate_results)

    result = @container.remote_deploy(options)
    expected_result = {
      status: 'success',
      distribute_result: distribute_results,
      activate_result: activate_results
    }
    assert_equal expected_result, result
  end

  def test_deploy
    options = { a: 1 }
    @container.expects(:pre_receive).with(options)
    @container.expects(:post_receive).with(options)

    @container.deploy(options)
  end

  def test_configure_defaults
    @cartridge_model.expects(:configure).with(@ident, nil, nil)
    @container.configure(@ident)
  end

  def test_configure_with_args
    template_git_url = 'url'
    manifest = 'manifest'
    @cartridge_model.expects(:configure).with(@ident, template_git_url, manifest)
    @container.expects(:create_public_endpoints).with(@ident.to_name)
    @container.configure(@ident, template_git_url, manifest, true)
  end

  # new gear
  # no git template url specified
  # cartridge doesn't require build on install
  # not already DEPLOYED
  def test_post_configure_defaults
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(false)
    cartridge.expects(:deployable?).returns(true)
    latest_deployment_datetime = "now"
    @container.expects(:latest_deployment_datetime).returns(latest_deployment_datetime)
    metadata = mock()
    @container.expects(:deployment_metadata_for).with(latest_deployment_datetime).returns(metadata)
    metadata.expects(:activations).returns([])
    @container.expects(:prepare).with(deployment_datetime: latest_deployment_datetime)
    metadata.expects(:load)
    git_sha1 = 'abcd1234'
    repository = mock()
    ::OpenShift::Runtime::ApplicationRepository.expects(:new).with(@container).returns(repository)
    repository.expects(:get_sha1).with('master').returns(git_sha1)
    metadata.expects(:git_sha1=).with(git_sha1)
    metadata.expects(:git_ref=).with('master')

    @container.expects(:set_rw_permission_R).with(File.join(@container.container_dir, 'app-deployments'))
    @container.expects(:reset_permission_R).with(File.join(@container.container_dir, 'app-deployments'))

    metadata.expects(:record_activation)
    metadata.expects(:save)

    @container.expects(:update_current_deployment_datetime_symlink).with(latest_deployment_datetime)

    @cartridge_model.expects(:post_configure).with(cart_name).returns('')

    @container.post_configure(cart_name)
  end

  # new gear
  # empty git template url - should keep build from happening
  # not already DEPLOYED
  def test_post_configure_empty_clone_spec_prevents_build
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:deployable?).returns(true)
    latest_deployment_datetime = "now"
    @container.expects(:latest_deployment_datetime).returns(latest_deployment_datetime)
    metadata = mock()
    @container.expects(:deployment_metadata_for).with(latest_deployment_datetime).returns(metadata)
    metadata.expects(:activations).returns([])
    @container.expects(:prepare).with(deployment_datetime: latest_deployment_datetime)
    metadata.expects(:load)
    repository = mock()
    ::OpenShift::Runtime::ApplicationRepository.expects(:new).with(@container).returns(repository)
    git_sha1 = 'abcd1234'
    repository.expects(:get_sha1).with('master').returns(git_sha1)

    metadata.expects(:git_sha1=).with(git_sha1)
    metadata.expects(:git_ref=).with('master')

    @container.expects(:set_rw_permission_R).with(File.join(@container.container_dir, 'app-deployments'))
    @container.expects(:reset_permission_R).with(File.join(@container.container_dir, 'app-deployments'))

    metadata.expects(:record_activation)
    metadata.expects(:save)

    @container.expects(:update_current_deployment_datetime_symlink).with(latest_deployment_datetime)

    @cartridge_model.expects(:post_configure).with(cart_name).returns('')

    @container.post_configure(cart_name, 'empty')
  end

  # new gear
  # cartridge requires build on install
  def test_post_configure_cartridge_build_on_install_does_build
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(true)
    cartridge.expects(:buildable?).returns(true)
    gear_env = {a: 1, b: 2}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    cgroups = mock()
    OpenShift::Runtime::Utils::Cgroups.expects(:new).returns(cgroups)
    cgroups.expects(:boost).yields()
    @hourglass.expects(:remaining).times(3).returns(100, 50, 49)
    OpenShift::Runtime::Utils.expects(:oo_spawn).with("gear prereceive --init >> /tmp/initial-build.log 2>&1",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             100,
                                                      expected_exitstatus: 0)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with("gear postreceive --init >> /tmp/initial-build.log 2>&1",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             50,
                                                      expected_exitstatus: 0)

    @cartridge_model.expects(:post_configure).with(cart_name).returns('')
    pattern = OpenShift::Runtime::Utils::Sdk::CLIENT_OUTPUT_PREFIXES.join('|')
    OpenShift::Runtime::Utils.expects(:oo_spawn).with("grep -E '#{pattern}' /tmp/initial-build.log | head -c 10K",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             49)
                                                .returns("pattern output")

    @container.post_configure(cart_name)
  end

  # new gear
  # cartridge does NOT require build on install
  # template git url passed in
  def test_post_configure_template_build_url_does_build
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(false)
    cartridge.expects(:buildable?).returns(true)

    gear_env = {a: 1, b: 2}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    cgroups = mock()
    OpenShift::Runtime::Utils::Cgroups.expects(:new).returns(cgroups)
    cgroups.expects(:boost).yields()
    @hourglass.expects(:remaining).times(3).returns(100, 50, 49)
    OpenShift::Runtime::Utils.expects(:oo_spawn).with("gear prereceive --init >> /tmp/initial-build.log 2>&1",
                                                 env:                 gear_env,
                                                 chdir:               @container.container_dir,
                                                 uid:                 @container.uid,
                                                 timeout:             100,
                                                 expected_exitstatus: 0)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with("gear postreceive --init >> /tmp/initial-build.log 2>&1",
                                                 env:                 gear_env,
                                                 chdir:               @container.container_dir,
                                                 uid:                 @container.uid,
                                                 timeout:             50,
                                                 expected_exitstatus: 0)

    @cartridge_model.expects(:post_configure).with(cart_name).returns('')

    pattern = OpenShift::Runtime::Utils::Sdk::CLIENT_OUTPUT_PREFIXES.join('|')
    OpenShift::Runtime::Utils.expects(:oo_spawn).with("grep -E '#{pattern}' /tmp/initial-build.log | head -c 10K",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             49)
                                                .returns("pattern output")

    @container.post_configure(cart_name, 'url')
  end

  # new gear
  # cartridge does NOT require build on install
  # template git url passed in
  def test_post_configure_rescues_build_exception
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(false)
    cartridge.expects(:buildable?).returns(true)
    gear_env = {a: 1, b: 2}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    cgroups = mock()
    OpenShift::Runtime::Utils::Cgroups.expects(:new).returns(cgroups)
    cgroups.expects(:boost).yields()
    @hourglass.expects(:remaining).times(2).returns(100, 50)
    OpenShift::Runtime::Utils.expects(:oo_spawn).with("gear prereceive --init >> /tmp/initial-build.log 2>&1",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             100,
                                                      expected_exitstatus: 0)
                                                .raises(OpenShift::Runtime::Utils::ShellExecutionException.new('my error', 1))

    OpenShift::Runtime::Utils.expects(:oo_spawn).with("tail -c 10240 /tmp/initial-build.log 2>&1",
                                                      env:                 gear_env,
                                                      chdir:               @container.container_dir,
                                                      uid:                 @container.uid,
                                                      timeout:             50)
                                                .returns("some output")

    error = assert_raises(RuntimeError) { @container.post_configure(cart_name, 'url') }
    assert_equal error.message, "CLIENT_ERROR: The initial build for the application failed: my error\nCLIENT_ERROR: \nCLIENT_ERROR: .Last 10 kB of build output:\nCLIENT_ERROR: some output\n"
  end

  # new gear
  # no git template url specified
  # cartridge doesn't require build on install
  # already have at least 1 activation
  def test_post_configure_not_deployable
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(false)
    cartridge.expects(:deployable?).returns(false)
    @container.expects(:latest_deployment_datetime).never
    @container.expects(:deployment_metadata_for).never
    @container.expects(:prepare).never
    @container.expects(:update_repo_symlink).never
    @container.expects(:set_rw_permission_R).never
    @container.expects(:reset_permission_R).never
    @cartridge_model.expects(:post_configure).with(cart_name).returns('')

    @container.post_configure(cart_name)
  end

  # new gear
  # no git template url specified
  # cartridge doesn't require build on install
  # already have at least 1 activation
  def test_post_configure_already_deployed
    cart_name = 'mock-0.1'
    cartridge = mock()
    @cartridge_model.expects(:get_cartridge).with(cart_name).returns(cartridge)
    cartridge.expects(:install_build_required).returns(false)
    cartridge.expects(:deployable?).returns(true)
    latest_deployment_datetime = "now"
    @container.expects(:latest_deployment_datetime).returns(latest_deployment_datetime)
    metadata = mock()
    @container.expects(:deployment_metadata_for).with(latest_deployment_datetime).returns(metadata)
    metadata.expects(:activations).returns([1])
    @container.expects(:prepare).never
    @container.expects(:update_repo_symlink).never
    @container.expects(:set_rw_permission_R).never
    @container.expects(:reset_permission_R).never
    @cartridge_model.expects(:post_configure).with(cart_name).returns('')

    @container.post_configure(cart_name)
  end

  def test_prepare_without_file_success
    deployment_datetime = 'now'

    gear_env = {a:1}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @cartridge_model.expects(:do_action_hook).with('prepare',
                                                   gear_env,
                                                   {deployment_datetime: deployment_datetime})
                                             .returns("output from prepare hook\n")

    deployment_id = 'abcd1234'
    checksum = 'abcd'
    @container.expects(:calculate_deployment_id).with(deployment_datetime).returns(deployment_id)
    @container.stubs(:calculate_deployment_checksum).with(deployment_id).returns(checksum)
    @container.expects(:link_deployment_id).with(deployment_datetime, deployment_id)

    @container.expects(:sync_runtime_repo_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_dependencies_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_build_dependencies_dir_to_deployment).with(deployment_datetime)

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:id=).with(deployment_id)
    metadata.expects(:checksum=).with(checksum)
    metadata.expects(:save)

    prepare_options = {deployment_datetime: deployment_datetime}
    output = @container.prepare(prepare_options)

    assert_equal deployment_id, prepare_options[:deployment_id]
  end

  def test_prepare_without_file_failure
    gear_env = {a:1}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    deployment_datetime = 'now'
    @cartridge_model.expects(:do_action_hook).with('prepare',
                                                   gear_env,
                                                   {deployment_datetime: deployment_datetime})
                                             .returns("output from prepare hook\n")

    deployment_id = 'abcd1234'
    @container.expects(:calculate_deployment_id).with(deployment_datetime).returns(deployment_id)
    @container.expects(:link_deployment_id).with(deployment_datetime, deployment_id)

    @container.expects(:sync_runtime_repo_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_dependencies_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_build_dependencies_dir_to_deployment).with(deployment_datetime)

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:id=).with(deployment_id).raises(IOError.new('msg'))
    @container.expects(:unlink_deployment_id).with(deployment_id)

    prepare_options = {deployment_datetime: deployment_datetime}
    output = @container.prepare(prepare_options)

    assert_nil prepare_options[:deployment_id]
  end

  def test_prepare_with_valid_file
    deployment_datetime = 'now'
    filename = 'test.tar.gz'
    file_path = File.join(@container.container_dir, 'app-archives', filename)
    prepare_options = {deployment_datetime: deployment_datetime, file: filename}

    gear_env = {a:1}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.expects(:clean_runtime_dirs).with(dependencies:true, build_dependencies:true, repo:true)
    @container.expects(:extract_deployment_archive).with(gear_env, prepare_options)
    @cartridge_model.expects(:do_action_hook).with('prepare',
                                                   gear_env,
                                                   prepare_options)
                                             .returns("output from prepare hook\n")

    deployment_id = 'abcd1234'
    checksum = 'abcd'
    @container.expects(:calculate_deployment_id).with(deployment_datetime).returns(deployment_id)
    @container.stubs(:calculate_deployment_checksum).with(deployment_id).returns(checksum)

    link = PathUtils.join(@container.container_dir, 'app-deployments', 'by-id', deployment_id)
    FileUtils.expects(:ln_s).with(PathUtils.join('..', deployment_datetime), link)
    PathUtils.expects(:oo_lchown).with(@container.uid, @container.gid, link)
    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:id=).with(deployment_id)
    metadata.expects(:checksum=).with(checksum)
    metadata.expects(:save)

    @container.expects(:sync_runtime_repo_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_dependencies_dir_to_deployment).with(deployment_datetime)
    @container.expects(:sync_runtime_build_dependencies_dir_to_deployment).with(deployment_datetime)

    output = @container.prepare(prepare_options)

    assert_equal deployment_id, prepare_options[:deployment_id]
  end

  def test_prepare_no_datetime
    assert_raises(ArgumentError, 'deployment_datetime is required') { @container.prepare({}) }
  end

  def test_child_gear_ssh_urls_no_web_proxy
    @cartridge_model.expects(:web_proxy).returns(nil)
    assert_empty @container.child_gear_ssh_urls
  end

  def test_child_gear_ssh_urls_web_proxy
    @cartridge_model.expects(:web_proxy).returns(1)

    gear_registry = mock()
    @container.expects(:gear_registry).returns(gear_registry)

    self_entry = mock()

    other_entry = mock()
    other_entry.expects(:proxy_hostname).returns('localhost')

    other_entry2 = mock()
    other_entry2.expects(:proxy_hostname).returns('localhost')

    entries = {
      :web => {
        @container.uuid => self_entry,
        '5504' => other_entry,
        '5505' => other_entry2
      }
    }

    gear_registry.expects(:entries).returns(entries)

    urls = @container.child_gear_ssh_urls
    assert_equal 2, urls.size
    assert_includes urls, '5504@localhost'
    assert_includes urls, '5505@localhost'
  end

  def test_child_gear_ssh_urls_uses_specified_type
    @cartridge_model.expects(:web_proxy).returns(1)
    gear_registry = mock()
    @container.expects(:gear_registry).returns(gear_registry)

    self_entry = mock()

    other_entry = mock()

    other_entry2 = mock()
    other_entry2.expects(:proxy_hostname).returns('localhost')

    entries = {
      :proxy => {
        @container.uuid => self_entry,
        '5505' => other_entry2
      },
      :web => {
        @container.uuid => self_entry,
        '5504' => other_entry,
        '5505' => other_entry2
      }
    }

    gear_registry.expects(:entries).returns(entries)

    urls = @container.child_gear_ssh_urls(:proxy)
    assert_equal 1, urls.size
    assert_includes urls, '5505@localhost'
  end

  def test_distribute_no_child_gears
    @container.expects(:child_gear_ssh_urls).returns([])

    @container.expects(:get_deployment_datetime_for_deployment_id).never
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).never
    @container.expects(:run_in_container_context).never

    result = @container.distribute()

    assert_equal 'success', result[:status]
    assert_equal 0, result[:gear_results].size
  end

  def test_distribute_child_gears_success
    gears = %w(1234@localhost 2345@localhost)
    @container.expects(:child_gear_ssh_urls).returns(gears)

    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    gears.each do |g|
      @container.expects(:distribute_to_gear).with(g, gear_env).returns({ status: 'success', gear_uuid: g.split('@')[0], messages:[], errors:[] })
    end

    result = @container.distribute()

    assert_equal 'success', result[:status]
    assert_equal 2, result[:gear_results].size
    assert_equal 'success', result[:gear_results]['1234'][:status]
    assert_equal 'success', result[:gear_results]['2345'][:status]
  end

  def test_distribute_failure
    gears = %w(1234@localhost 2345@localhost)
    @container.expects(:child_gear_ssh_urls).returns(gears)

    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.expects(:distribute_to_gear).with('1234@localhost', gear_env).returns(gear_uuid: '1234', status: 'success', messages: [], errors: [])
    @container.expects(:distribute_to_gear).with('2345@localhost', gear_env).returns(gear_uuid: '2345', status: 'failure', messages: [], errors: [])

    result = @container.distribute()

    assert_equal 'failure', result[:status]
    assert_equal 2, result[:gear_results].size
    assert_equal 'success', result[:gear_results]['1234'][:status]
    assert_equal 'failure', result[:gear_results]['2345'][:status]
  end

  def test_distribute_specified_gears
    gears = %w(1234@localhost 2345@localhost)

    @container.expects(:child_gear_ssh_urls).never
    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)
    gears.each do |g|
      @container.expects(:distribute_to_gear).with(g, gear_env).returns({ status: 'success', gear_uuid: g.split('@')[0], messages:[], errors:[] })
    end

    result = @container.distribute(gears: gears)

    assert_equal 'success', result[:status]
    assert_equal 2, result[:gear_results].size
    assert_equal 'success', result[:gear_results]['1234'][:status]
    assert_equal 'success', result[:gear_results]['2345'][:status]
  end

  def test_distribute_to_gear_success
    gear = '1234@node1.example.com'
    gear_env = mock()
    deployment_dir = mock()
    deployment_datetime = mock()
    deployment_id = mock()

    expected_result = {
      gear_uuid: '1234',
      status: 'success',
      messages: [],
      errors: []
    }
    @container.expects(:attempt_distribute_to_gear).with(gear, gear_env).returns(expected_result)

    result = @container.distribute_to_gear(gear, gear_env)

    assert_equal expected_result, result
  end

  def test_distribute_to_gear_retry_success
    gear = '1234@node1.example.com'
    gear_env = mock()
    deployment_dir = mock()
    deployment_datetime = mock()
    deployment_id = mock()

    expected_result = {
      gear_uuid: '1234',
      status: 'success',
      messages: [],
      errors: []
    }

    @container.expects(:attempt_distribute_to_gear)
              .with(gear, gear_env)
              .times(2)
              .raises(::OpenShift::Runtime::Utils::ShellExecutionException.new('msg'))
              .then.returns(expected_result)

    result = @container.distribute_to_gear(gear, gear_env)

    assert_equal expected_result, result
  end

  def test_distribute_to_gear_retry_failure
    gear = '1234@node1.example.com'
    gear_env = mock()
    deployment_dir = mock()
    deployment_datetime = mock()
    deployment_id = mock()

    exception = ::OpenShift::Runtime::Utils::ShellExecutionException.new('msg')
    @container.expects(:attempt_distribute_to_gear).with(gear, gear_env).raises(exception).times(3)

    result = @container.distribute_to_gear(gear, gear_env)

    expected_result = {
      gear_uuid: '1234',
      status: 'failure',
      messages: [],
      errors: []
    }
    assert_equal expected_result, result
  end

  def test_activate_no_child_gears
    deployment_id = 'abcd1234'
    activate_options = { deployment_id: deployment_id, all: true }
    inner_options = { deployment_id: deployment_id, all: true, hot_deploy: false }

    gear_env = {'OPENSHIFT_APP_DNS' => 'app-ns.example.com', 'OPENSHIFT_GEAR_DNS' => 'app-ns.example.com'}
    deployment_datetime = 'now'
    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)
    deployment_metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(deployment_metadata)
    deployment_metadata.expects(:hot_deploy).returns(false)
    @container.cartridge_model.expects(:standalone_web_proxy?).returns(false)

    gear_result1 = { gear_uuid: @container.uuid, status: 'success', errors: [], messages: [] }
    @container.expects(:with_gear_rotation)
              .with(inner_options)
              .yields(@container.uuid, gear_env, inner_options)
              .returns([gear_result1])

    @container.expects(:activate_local_gear).with(inner_options)

    result = @container.activate(activate_options)

    assert_equal 'success', result[:status]
    assert_equal 1, result[:gear_results].size
    assert_equal gear_result1, result[:gear_results][@container.uuid]
  end

  def test_activate_success
    deployment_id = 'abcd1234'
    activate_options = { deployment_id: deployment_id, all: true }
    inner_options = { deployment_id: deployment_id, all: true, hot_deploy: false }

    gear_env = {'OPENSHIFT_APP_DNS' => 'app-ns.example.com', 'OPENSHIFT_GEAR_DNS' => 'app-ns.example.com'}

    gear_uuids = [@container.uuid, '1234', '2345']
    entry1 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[0], proxy_hostname: 'node1.example.com')
    entry2 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[1], proxy_hostname: 'node1.example.com')
    entry3 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[2], proxy_hostname: 'node1.example.com')

    deployment_datetime = 'now'
    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)
    deployment_metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(deployment_metadata)
    deployment_metadata.expects(:hot_deploy).returns(false)

    @container.cartridge_model.expects(:standalone_web_proxy?).returns(false)

    gear_result1 = { gear_uuid: gear_uuids[0], status: 'success', errors: [], messages: [] }
    gear_result2 = { gear_uuid: gear_uuids[1], status: 'success', errors: [], messages: [] }
    gear_result3 = { gear_uuid: gear_uuids[2], status: 'success', errors: [], messages: [] }
    @container.expects(:with_gear_rotation)
              .with(inner_options)
              .multiple_yields([entry1, gear_env, inner_options],
                               [entry2, gear_env, inner_options],
                               [entry3, gear_env, inner_options])
              .returns([gear_result1, gear_result2, gear_result3])

    @container.expects(:activate_local_gear).with(inner_options)
    @container.expects(:activate_remote_gear).with(entry2, gear_env, inner_options)
    @container.expects(:activate_remote_gear).with(entry3, gear_env, inner_options)

    result = @container.activate(activate_options)

    assert_equal 'success', result[:status]
    assert_equal 3, result[:gear_results].size
    assert_equal gear_result1, result[:gear_results][gear_uuids[0]]
    assert_equal gear_result2, result[:gear_results][gear_uuids[1]]
    assert_equal gear_result3, result[:gear_results][gear_uuids[2]]
  end

  def test_activate_failure
    deployment_id = 'abcd1234'
    activate_options = { deployment_id: deployment_id, all: true }
    inner_options = { deployment_id: deployment_id, all: true, hot_deploy: false }

    gear_env = {'OPENSHIFT_APP_DNS' => 'app-ns.example.com', 'OPENSHIFT_GEAR_DNS' => 'app-ns.example.com'}

    gear_uuids = [@container.uuid, '1234', '2345']
    entry1 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[0], proxy_hostname: 'node1.example.com')
    entry2 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[1], proxy_hostname: 'node1.example.com')
    entry3 = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: gear_uuids[2], proxy_hostname: 'node1.example.com')

    deployment_datetime = 'now'
    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)
    deployment_metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(deployment_metadata)
    deployment_metadata.expects(:hot_deploy).returns(false)

    @container.cartridge_model.expects(:standalone_web_proxy?).returns(false)

    gear_result1 = { gear_uuid: gear_uuids[0], status: 'success', errors: [], messages: [] }
    gear_result2 = { gear_uuid: gear_uuids[1], status: 'success', errors: [], messages: [] }
    gear_result3 = { gear_uuid: gear_uuids[2], status: 'failure', errors: [], messages: [] }
    @container.expects(:with_gear_rotation)
              .with(inner_options)
              .multiple_yields([entry1, gear_env, inner_options],
                               [entry2, gear_env, inner_options],
                               [entry3, gear_env, inner_options])
              .returns([gear_result1, gear_result2, gear_result3])

    @container.expects(:activate_local_gear).with(inner_options)
    @container.expects(:activate_remote_gear).with(entry2, gear_env, inner_options)
    @container.expects(:activate_remote_gear).with(entry3, gear_env, inner_options)

    result = @container.activate(activate_options)

    assert_equal 'failure', result[:status]
    assert_equal 3, result[:gear_results].size
    assert_equal gear_result1, result[:gear_results][gear_uuids[0]]
    assert_equal gear_result2, result[:gear_results][gear_uuids[1]]
    assert_equal gear_result3, result[:gear_results][gear_uuids[2]]
  end

  def test_activate_remote_gear_success
    deployment_id = 'abcd1234'
    g = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: '1234', proxy_hostname: 'node.example.com')
    gear_uuid = "1234"
    gear_env = {}
    options = { deployment_id: deployment_id }

    remote_result = {
      status: 'success',
      gear_uuid: gear_uuid,
      status: 'success',
      messages: [],
      errors: []
    }

    @container.expects(:run_in_container_context).with("/usr/bin/oo-ssh #{g.to_ssh_url} gear activate #{deployment_id} --as-json --no-rotation",
                                                       env: gear_env,
                                                       expected_exitstatus: 0)
                                                 .returns(JSON.dump(remote_result))

    result = @container.activate_remote_gear(g, gear_env, options)

    assert_equal 'success', result[:status]
  end


  def test_activate_remote_gear_activation_fails
    deployment_id = 'abcd1234'
    g = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: '1234', proxy_hostname: 'node.example.com')
    gear_uuid = "1234"
    gear_env = {}
    options = { deployment_id: deployment_id }

    @container.expects(:run_in_container_context).with("/usr/bin/oo-ssh #{g.to_ssh_url} gear activate #{deployment_id} --as-json --no-rotation",
                                                       env: gear_env,
                                                       expected_exitstatus: 0)
                                                 .raises(::OpenShift::Runtime::Utils::ShellExecutionException.new('msg'))

    result = @container.activate_remote_gear(g, gear_env, options)

    assert_equal 'failure', result[:status]
  end

  def test_activate_remote_gear_post_install
    deployment_id = 'abcd1234'
    g = ::OpenShift::Runtime::GearRegistry::Entry.new(uuid: '1234', proxy_hostname: 'node.example.com')
    gear_uuid = "1234"
    gear_env = {}
    options = { deployment_id: deployment_id, post_install: true }

    remote_result = {
      status: 'success',
      gear_uuid: gear_uuid,
      status: 'success',
      messages: [],
      errors: []
    }

    @container.expects(:run_in_container_context).with("/usr/bin/oo-ssh #{g.to_ssh_url} gear activate #{deployment_id} --as-json --post-install --no-rotation",
                                                       env: gear_env,
                                                       expected_exitstatus: 0)
                                                 .returns(JSON.dump(remote_result))

    result = @container.activate_remote_gear(g, gear_env, options)

    assert_equal 'success', result[:status]
  end

  def test_shell_execution_error
    deployment_id    = 'abcd1234'
    activate_options = {deployment_id: deployment_id}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)
    @container.expects(:get_deployment_datetime_for_deployment_id).
        with(deployment_id).
        raises(::OpenShift::Runtime::Utils::ShellExecutionException.new('unit test', -100, 'stdout', 'stderr'))

    results = @container.activate_local_gear(activate_options)

    assert_equal('failure', results[:status])
    assert_equal(1, results[:errors].size)
    assert_match(/stdout\nstderr/, results[:errors][0])
  end

  def test_activate_local_gear_deployment_doesnt_exist
    deployment_id = 'abcd1234'
    activate_options = {deployment_id: deployment_id}
    @container.expects(:deployment_exists?).with(deployment_id).returns(false)
    result = @container.activate_local_gear(activate_options)
    assert_equal 'failure', result[:status]
    assert_equal 1, result[:errors].size
    assert_equal "No deployment with id #{deployment_id} found on gear", result[:errors][0]
  end

  def test_activate_local_gear_stops_started_gear
    deployment_id = 'abcd1234'
    deployment_datetime = 'now'
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime)
    activate_options = {deployment_id: deployment_id, hot_deploy: true}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)

    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)

    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.state.expects(:value).returns(::OpenShift::Runtime::State::STARTED)
    @container.expects(:stop_gear).with(activate_options.merge(exclude_web_proxy: true)).returns("stop")

    @container.expects(:sync_deployment_repo_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_dependencies_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_build_dependencies_dir_to_runtime).with(deployment_datetime)

    @container.expects(:update_current_deployment_datetime_symlink).with(deployment_datetime)

    primary_cartridge = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary_cartridge)
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               post_action_hooks_enabled: false,
                                               out: nil,
                                               err: nil)

    @container.expects(:start_gear).with(secondary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start secondary")

    @container.state.expects(:value=).with(::OpenShift::Runtime::State::DEPLOYING)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("deploy")

    @container.expects(:start_gear).with(primary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start primary")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("post-deploy")

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:record_activation)
    metadata.expects(:save)

    result = @container.activate_local_gear(activate_options)
    assert_equal 'success', result[:status]
    assert_equal @container.uuid, result[:gear_uuid]
    assert_equal deployment_id, result[:deployment_id]
  end

  def test_activate_local_gear_doesnt_call_stop_if_already_stopped
    deployment_id = 'abcd1234'
    deployment_datetime = 'now'
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime)
    activate_options = {deployment_id: deployment_id, hot_deploy: true}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)

    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)

    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.state.expects(:value).returns(::OpenShift::Runtime::State::STOPPED)

    @container.expects(:sync_deployment_repo_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_dependencies_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_build_dependencies_dir_to_runtime).with(deployment_datetime)

    @container.expects(:update_current_deployment_datetime_symlink).with(deployment_datetime)

    primary_cartridge = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary_cartridge)
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               post_action_hooks_enabled: false,
                                               out: nil,
                                               err: nil)

    @container.expects(:start_gear).with(secondary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start secondary")

    @container.state.expects(:value=).with(::OpenShift::Runtime::State::DEPLOYING)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("deploy")

    @container.expects(:start_gear).with(primary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start primary")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("post-deploy")

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:record_activation)
    metadata.expects(:save)

    result = @container.activate_local_gear(activate_options)
    assert_equal 'success', result[:status]
    assert_equal @container.uuid, result[:gear_uuid]
    assert_equal deployment_id, result[:deployment_id]
  end

  def test_activate_local_gear_with_post_install_option
    deployment_id = 'abcd1234'
    deployment_datetime = 'now'
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime)
    activate_options = {deployment_id: deployment_id, hot_deploy: true, post_install: true}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)

    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)

    gear_env = {'key' => 'value'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.state.expects(:value).returns(::OpenShift::Runtime::State::STARTED)
    @container.expects(:stop_gear).with(activate_options.merge(exclude_web_proxy: true)).returns("stop")

    @container.expects(:sync_deployment_repo_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_dependencies_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_build_dependencies_dir_to_runtime).with(deployment_datetime)

    @container.expects(:update_current_deployment_datetime_symlink).with(deployment_datetime)

    primary_cartridge = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary_cartridge)
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               post_action_hooks_enabled: false,
                                               out: nil,
                                               err: nil)

    @container.expects(:start_gear).with(secondary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start secondary")

    @container.state.expects(:value=).with(::OpenShift::Runtime::State::DEPLOYING)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("deploy")

    @container.expects(:start_gear).with(primary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start primary")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("post-deploy")

    primary_cartridge_directory = 'primarycartdir'
    primary_cartridge.expects(:directory).returns(primary_cartridge_directory)
    primary_cart_env_dir = File.join(@container.container_dir, primary_cartridge_directory, 'env')
    primary_cart_env = {'OPENSHIFT_XYZ_IDENT' => 'redhat:mock:0.1:0.1'}
    ::OpenShift::Runtime::Utils::Environ.expects(:load).with(primary_cart_env_dir).returns(primary_cart_env)

    @cartridge_model.expects(:post_install).with(primary_cartridge, '0.1')

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:record_activation)
    metadata.expects(:save)

    result = @container.activate_local_gear(activate_options)
    assert_equal 'success', result[:status]
    assert_equal @container.uuid, result[:gear_uuid]
    assert_equal deployment_id, result[:deployment_id]
  end

  def test_activate_local_gear_report_deployments_head_gear
    deployment_id = 'abcd1234'
    deployment_datetime = 'now'
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime)
    activate_options = {deployment_id: deployment_id, hot_deploy: true, report_deployments: true}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)

    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)

    gear_env = {'OPENSHIFT_APP_DNS' => 'myapp-myns.openshift.com', 'OPENSHIFT_GEAR_DNS' => 'myapp-myns.openshift.com'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.state.expects(:value).returns(::OpenShift::Runtime::State::STARTED)
    @container.expects(:stop_gear).with(activate_options.merge(exclude_web_proxy: true)).returns("stop")

    @container.expects(:sync_deployment_repo_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_dependencies_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_build_dependencies_dir_to_runtime).with(deployment_datetime)

    @container.expects(:update_current_deployment_datetime_symlink).with(deployment_datetime)

    primary_cartridge = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary_cartridge)
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               post_action_hooks_enabled: false,
                                               out: nil,
                                               err: nil)

    @container.expects(:start_gear).with(secondary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start secondary")

    @container.state.expects(:value=).with(::OpenShift::Runtime::State::DEPLOYING)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("deploy")

    @container.expects(:start_gear).with(primary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start primary")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("post-deploy")

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:record_activation)
    metadata.expects(:save)

    @container.expects(:report_deployments).with(gear_env, out:nil)

    result = @container.activate_local_gear(activate_options)
    assert_equal 'success', result[:status]
    assert_equal @container.uuid, result[:gear_uuid]
    assert_equal deployment_id, result[:deployment_id]
  end

  def test_activate_local_gear_report_deployments_not_head_gear
    deployment_id = 'abcd1234'
    deployment_datetime = 'now'
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime)
    activate_options = {deployment_id: deployment_id, hot_deploy: true, report_deployments: true}

    @container.expects(:deployment_exists?).with(deployment_id).returns(true)

    @container.expects(:get_deployment_datetime_for_deployment_id).with(deployment_id).returns(deployment_datetime)

    gear_env = {'OPENSHIFT_APP_DNS' => 'myapp-myns.openshift.com', 'OPENSHIFT_GEAR_DNS' => 'gear123-myns.openshift.com'}
    OpenShift::Runtime::Utils::Environ.expects(:for_gear).with(@container.container_dir).returns(gear_env)

    @container.state.expects(:value).returns(::OpenShift::Runtime::State::STARTED)
    @container.expects(:stop_gear).with(activate_options.merge(exclude_web_proxy: true)).returns("stop")

    @container.expects(:sync_deployment_repo_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_dependencies_dir_to_runtime).with(deployment_datetime)
    @container.expects(:sync_deployment_build_dependencies_dir_to_runtime).with(deployment_datetime)

    @container.expects(:update_current_deployment_datetime_symlink).with(deployment_datetime)

    primary_cartridge = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary_cartridge)
    @cartridge_model.expects(:do_control).with('update-configuration',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               post_action_hooks_enabled: false,
                                               out: nil,
                                               err: nil)

    @container.expects(:start_gear).with(secondary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start secondary")

    @container.state.expects(:value=).with(::OpenShift::Runtime::State::DEPLOYING)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("deploy")

    @container.expects(:start_gear).with(primary_only: true,
                                         user_initiated: true,
                                         hot_deploy: true,
                                         out: nil,
                                         err: nil)
                                   .returns("start primary")

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary_cartridge,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks: false,
                                               out: nil,
                                               err:nil)
                                         .returns("post-deploy")

    metadata = mock()
    @container.expects(:deployment_metadata_for).with(deployment_datetime).returns(metadata)
    metadata.expects(:record_activation)
    metadata.expects(:save)

    @container.expects(:report_deployments).never

    result = @container.activate_local_gear(activate_options)
    assert_equal 'success', result[:status]
    assert_equal @container.uuid, result[:gear_uuid]
    assert_equal deployment_id, result[:deployment_id]
  end

end
