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

class UnixUserModelFunctionalTest < Test::Unit::TestCase

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
    @user_homedir = "/tmp/homedir-#{@user_uid}"
    `useradd -u #{@user_uid} -d #{@user_homedir} #{@user_uid} 1>/dev/null 2>&1`

    @config = mock('OpenShift::Config')
    @config.stubs(:get).returns(nil)
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")
    @config.stubs(:get).with("CLOUD_DOMAIN").returns("rhcloud.com")
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns("/tmp")
    OpenShift::Config.stubs(:new).returns(@config)

    @frontend = mock('OpenShift::FrontendHttpServer')
    @frontend.stubs(:create)
    @frontend.stubs(:destroy)
    OpenShift::FrontendHttpServer.stubs(:new).returns(@frontend)
  end

  def teardown
    `userdel #{@user_uid} 1>/dev/null`
  end

  def test_initialize
    FileUtils.rm_rf(@user_homedir, :verbose => @verbose) if File.directory?(@user_homedir)
    o = OpenShift::UnixUser.new(@gear_uuid, @gear_uuid, @user_uid, @app_name,
                                @gear_name, @namespace,
                                nil, nil, @verbose)
    assert_not_nil o

    o.initialize_homedir("/tmp/", "#{@user_homedir}/", "cartridges/openshift-origin-cartridge-abstract/")
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
