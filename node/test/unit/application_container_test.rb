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
module OpenShift; end

require 'openshift-origin-node/model/application_container'
require 'test/unit'
require 'fileutils'
require 'mocha'

# Run unit test manually
# ruby -I node/lib:common/lib node/test/unit/application_container_test.rb
class TestApplicationContainer < Test::Unit::TestCase

  def setup
    # Set up the config
    config = mock('OpenShift::Config')

    @ports_begin = 35531
    @ports_per_user = 5
    @uid_begin = 500

    config.stubs(:get).with("PORT_BEGIN").returns(@ports_begin.to_s)
    config.stubs(:get).with("PORTS_PER_USER").returns(@ports_per_user.to_s)
    config.stubs(:get).with("UID_BEGIN").returns(@uid_begin.to_s)

    script_dir = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

    config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

    OpenShift::Config.stubs(:new).returns(config)

    # Set up the container
    @gear_uuid = Process.euid.to_s
    @user_uid = Process.euid.to_s
    @app_name = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip = "127.0.0.1"

    @container = OpenShift::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil, nil)   
  end

  def test_endpoint_create_php
    cart = "openshift-origin-cartridge-php-5.3"
    cart_ns = OpenShift::ApplicationContainer.cart_name_to_namespace(cart)
    @container.stubs(:load_env).returns({"OPENSHIFT_#{cart_ns}_IP".to_sym => @gear_ip})

    proxy = mock('OpenShift::FrontendProxyServer')
    OpenShift::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:add).with(@user_uid, @gear_ip, 8080).returns(@ports_begin).once

    @container.user.expects(:add_env_var).returns(nil).once
    
    @container.create_endpoints(cart)
  end

  def test_endpoint_create_jbossas7
    cart = "openshift-origin-cartridge-jbossas-7"
    cart_ns = OpenShift::ApplicationContainer.cart_name_to_namespace(cart)
    @container.stubs(:load_env).returns({"OPENSHIFT_#{cart_ns}_IP".to_sym => @gear_ip})

    proxy = mock('OpenShift::FrontendProxyServer')
    OpenShift::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:add).with(@user_uid, @gear_ip, 8080).returns(@ports_begin).once
    proxy.expects(:add).with(@user_uid, @gear_ip, 7600).returns(@ports_begin+1).once
    proxy.expects(:add).with(@user_uid, @gear_ip, 5445).returns(@ports_begin+2).once
    proxy.expects(:add).with(@user_uid, @gear_ip, 5455).returns(@ports_begin+3).once
    proxy.expects(:add).with(@user_uid, @gear_ip, 4447).returns(@ports_begin+4).once

    @container.user.expects(:add_env_var).returns(nil).times(5)

    @container.create_endpoints(cart)
  end

  def test_endpoint_delete_jbossas7
    cart = "openshift-origin-cartridge-jbossas-7"
    cart_ns = OpenShift::ApplicationContainer.cart_name_to_namespace(cart)
    @container.stubs(:load_env).returns({"OPENSHIFT_#{cart_ns}_IP".to_sym => @gear_ip})

    proxy = mock('OpenShift::FrontendProxyServer')
    OpenShift::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:find_mapped_proxy_port).with(@user_uid, @gear_ip, 8080).returns(@ports_begin).once
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, @gear_ip, 7600).returns(@ports_begin+1).once
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, @gear_ip, 5445).returns(@ports_begin+2).once
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, @gear_ip, 5455).returns(@ports_begin+3).once
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, @gear_ip, 4447).returns(@ports_begin+4).once

    delete_all_args = [@ports_begin, @ports_begin+1, @ports_begin+2, @ports_begin+3, @ports_begin+4]
    proxy.expects(:delete_all).with(delete_all_args, true).returns(nil)

    @container.user.expects(:remove_env_var).returns(nil).times(5)

    @container.delete_endpoints(cart)
  end

end
