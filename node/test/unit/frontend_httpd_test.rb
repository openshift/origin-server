#!/usr/bin/env oo-ruby
#--
# Copyright 2012 Red Hat, Inc.
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
# Test the OpenShift frontend_httpd model
#
require 'openshift-origin-node/model/frontend_httpd'
require 'test/unit'
require 'fileutils'
require 'mocha'


# Run unit test manually
# ruby -Iopenshift/node/lib/:openshift/common/lib/ openshift/node/test/unit/frontend_httpd_test.rb 
class TestFrontendHttpServerModel < Test::Unit::TestCase

  def setup
    @container_uuid = '0123456789abcdef'
    @container_name = 'frontendtest'
    @namespace = 'frontendtest'
    
    @token = "#{@container_uuid}_#{@namespace}_#{@container_name}"

    @gear_base_dir = "/tmp/frontend_httpd_test"

    @cloud_domain = "example.com"

    @path = File.join(@gear_base_dir, ".httpd.d", @token)

    @test_alias = "foo.example.com"
    @alias_token = "#{@container_uuid}_#{@namespace}_#{@test_alias}"
    @alias_conf_path = File.join(@gear_base_dir, ".httpd.d", "#{@alias_token}.conf")

    syslog_mock = mock('Syslog') do
      stubs(:opened?).returns(true)
      stubs(:open).returns(nil)
      stubs(:alert).returns(nil)
    end
    Syslog.stubs(:new).returns(syslog_mock)

    config_mock = mock('OpenShift::Config')
    config_mock.stubs(:get).with("GEAR_BASE_DIR").returns(@gear_base_dir)
    config_mock.stubs(:get).with("CLOUD_DOMAIN").returns(@cloud_domain)
    OpenShift::Config.stubs(:new).returns(config_mock)
  end


  def test_create
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.stubs(:shellCmd).returns(["", "", 0]).never
    File.stubs(:exist?).returns(false)
    FileUtils.stubs(:rm_rf).returns(nil)
    FileUtils.stubs(:mkdir_p).with(@path).returns(nil).once
    frontend.create
  end

  def test_destroy
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.stubs(:shellCmd).returns(["", "", 0]).twice
    FileUtils.stubs(:rm_rf).returns(nil).once
    frontend.destroy
  end


  def test_clean_server_name
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    
    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}")
    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}".upcase)
    assert_raise OpenShift::FrontendHttpServerNameException do
      frontend.clean_server_name("../../../../../../../etc/passwd")
    end
  end

  def test_server_alias_path
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)

    assert_equal File.join(@path, "server_alias-#{@test_alias}.conf"), frontend.server_alias_path("#{@test_alias}")
  end

  def test_server_alias_search
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)

    srch_path = File.join(@path, "server_alias-#{@test_alias}.conf")
    Dir.stubs(:glob).returns([srch_path])

    existing = frontend.server_alias_search("#{@test_alias}")
    assert_equal existing.length, 1
    assert_equal existing[0], srch_path
  end


  def test_add_alias
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)

    frontend.stubs(:shellCmd).returns(["", "", 0]).twice
    Dir.stubs(:glob).returns([])
    
    File.stubs(:open).with(File.join(@path, "server_alias-#{@test_alias}.conf"), 'w').returns(mock('File')).once

    File.stubs(:open).with(File.join(@path, "routes.json"),'r').returns(mock('File')).once

    frontend.add_alias("#{@test_alias}")
  end

  def test_add_duplicate_alias
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)

    frontend.stubs(:shellCmd).returns(["", "", 0]).never
    Dir.stubs(:glob).returns([File.join(@path, "server_alias-#{@test_alias}.conf")])

    File.stubs(:open).returns(mock('File')).never

    assert_raise OpenShift::FrontendHttpServerAliasException do
      frontend.add_alias("#{@test_alias}")
    end
  end

  def test_remove_alias
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)

    frontend.stubs(:shellCmd).returns(["", "", 0]).twice

    File.stubs(:exist?).with(File.join(@path, "routes_alias-#{@test_alias}.json")).returns(true).once
    Dir.stubs(:glob).returns([File.join(@path, "server_alias-#{@test_alias}.conf")])
    FileUtils.stubs(:rm_f).with(File.join(@path, "server_alias-#{@test_alias}.conf")).returns(true).once
    FileUtils.stubs(:rm_f).with(File.join(@path, "routes_alias-#{@test_alias}.json")).returns(true).once
    FileUtils.stubs(:rm_f).with(@alias_conf_path).returns(true).once

    frontend.remove_alias("#{@test_alias}")
  end

end

