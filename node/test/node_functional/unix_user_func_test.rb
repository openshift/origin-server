#!/usr/bin/env oo-ruby
#--
# Copyright 2012-2013 Red Hat, Inc.
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
# Test the OpenShift unix_user model
#
require_relative '../test_helper'

class UnixUserModelFunctionalTest < OpenShift::NodeTestCase

  def assert_directory?(file)
    assert File.directory?(file), "Directory #{file} not found"
  end

  def assert_symlink?(link)
    assert File.symlink?(link), "Symlink #{link} not found"
  end

  def setup
    @gear_uuid = '5995'
    @user_uid = 5995
    @app_name = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @verbose = false

    # polyinstantiation makes creating the homedir a pain...
    @user_homedir = "/data/tests/#{@user_uid}"
    FileUtils.rm_r @user_homedir if File.exist?(@user_homedir)
    FileUtils.mkdir_p @user_homedir
    `useradd -u #{@user_uid} -d #{@user_homedir} #{@user_uid} 1>/dev/null 2>&1`

    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")
    @config.stubs(:get).with("CLOUD_DOMAIN").returns("rhcloud.com")
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns("/tmp")
    @config.stubs(:get_bool).with("TRAFFIC_CONTROL_ENABLED", "true").returns(true)
    
    @frontend = mock('OpenShift::Runtime::FrontendHttpServer')
    @frontend.stubs(:create)
    @frontend.stubs(:destroy)
    OpenShift::Runtime::FrontendHttpServer.stubs(:new).returns(@frontend)
  end

  def teardown
    `userdel #{@user_uid} 1>/dev/null`
  end

  def test_initialize
    FileUtils.rm_rf(@user_homedir, :verbose => @verbose) if File.directory?(@user_homedir)
    o = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid, @app_name, @gear_name, @namespace)
    refute_nil o

    o.initialize_homedir("/tmp/", "#{@user_homedir}/")
    assert_directory?(@user_homedir)
    assert !File.symlink?("#{@user_homedir}/data"), 'found deprecated data symlink'
    assert !File.directory?("#{@user_homedir}/app"), 'found deprecated app directory'
    assert_directory?("#{@user_homedir}/app-root")
    assert_directory?("#{@user_homedir}/app-root/runtime/")
    assert File.exist?("#{@user_homedir}/app-root/runtime/.state"), '.state file missing'
    assert_symlink?("#{@user_homedir}/app-root/repo")
    assert_directory?("#{@user_homedir}/.tmp")
    assert_directory?("#{@user_homedir}/.env")
    assert_directory?("#{@user_homedir}/.sandbox")
    assert !File.exist?("#{@user_homedir}/.env/OPENSHIFT_NAMESPACE"),
           'OPENSHIFT_NAMESPACE should be created in V2CartridgeModel'

  end
end
