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
# Test the OpenShift frontend_httpd model
#
require_relative '../test_helper'
require 'fileutils'

class FrontendHttpServerModelTest < OpenShift::NodeTestCase

  def setup
    @container_uuid = '0123456789abcdef'
    @application_uuid = '0123456789abcdef'
    @container_name = 'frontendtest'
    @namespace = 'frontendtest'

    @container = mock('OpenShift::Runtime::ApplicationContainer')
    @container.stubs(:uuid).returns(@container_uuid)
    @container.stubs(:application_uuid).returns(@application_uuid)
    @container.stubs(:name).returns(@container_name)
    @container.stubs(:namespace).returns(@namespace)

    @cartridge_model = mock('OpenShift::Runtime::V2CartridgeModel')
    @cartridge_model.stubs(:standalone_web_proxy?).returns(false)
    @container.stubs(:cartridge_model).returns(@cartridge_model)

    OpenShift::Runtime::ApplicationContainer.stubs(:from_uuid).with(@container_uuid).returns(@container)

    @cloud_domain = "example.com"
    @fqdn = "#{@container_name}-#{@namespace}.#{@cloud_domain}"


    @ip = "127.0.0.1"
    @port = 8080

    @sts_max_age = 15768000

    @test_alias = "foo.example.com"

    @test_ssl_path = "#{@http_conf_dir}/#{@container_uuid}_#{@namespace}_#{@test_alias}"

    @test_ssl_key_passphrase = "test passphrase"
    @test_ssl_cert = "SSL Cert\n-----END\n"
    @test_ssl_key = "SSL Key"
    @test_ssl_key_decrypted = "SSL Key Decrypted"

    @config.stubs(:get).with("OPENSHIFT_FRONTEND_HTTP_PLUGINS",anything).returns('')
    @config.stubs(:get).with("CLOUD_DOMAIN").returns(@cloud_domain)

    ::OpenShift::Runtime::Frontend::Http::Plugins.stubs(:plugins).returns([])

    @frontend = OpenShift::Runtime::FrontendHttpServer.new(@container)

    @connections = [ ["", "#{@ip}:#{@port}", { "websocket" => 1, "connections" => 1, "bandwidth" => 2 }],
                     ["/nosocket", "#{@ip}:#{@port}",{}],
                     ["/gone", "", { "gone" => 1 }],
                     ["/forbidden", "", { "forbidden" => 1 }],
                     ["/noproxy", "", { "noproxy" => 1 }],
                     ["/redirect", "/dest", { "redirect" => 1 }],
                     ["/file", "/dest.html", { "file" => 1 }],
                     ["/tohttps", "/dest", { "tohttps" => 1 }] ]
    @connection_paths = @connections.map { |ent| ent[0] }
  end


  def test_clean_server_name
    frontend = OpenShift::Runtime::FrontendHttpServer.new(@container)

    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}")
    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}".upcase)
    assert_raise OpenShift::Runtime::FrontendHttpServerNameException do
      frontend.clean_server_name("../../../../../../../etc/passwd")
    end
  end

  def test_create
    @frontend.expects(:call_plugins).with(:create)
    @frontend.create
  end


  def test_destroy
    @frontend.expects(:call_plugins).with(:destroy)
    @frontend.destroy
  end


  def test_connect
    @frontend.expects(:call_plugins).with(:connect, *@connections)
    @frontend.connect(*(@connections.flatten(1)))
  end

  def test_connections
    @frontend.expects(:call_plugins).with(:connections).returns([@connections, @connections, @connections].flatten(1))
    assert_equal @connections, @frontend.connections
  end

  def test_disconnect
    @frontend.expects(:call_plugins).with(:disconnect, *@connection_paths)
    @frontend.disconnect(*@connection_paths)
  end


  def test_idle
    @frontend.expects(:call_plugins).with(:idle)
    @frontend.idle
  end

  def test_unidle
    @frontend.expects(:call_plugins).with(:unidle)
    @frontend.unidle
  end

  def test_unprivileged_unidle
    @frontend.expects(:call_plugins).with(:unprivileged_unidle)
    @frontend.unprivileged_unidle
  end

  def test_idle?
    @frontend.expects(:call_plugins).with(:idle?).returns([false, @container_uuid, false])
    assert_equal @container_uuid, @frontend.idle?
  end

  def test_idle_nil?
    @frontend.expects(:call_plugins).with(:idle?).returns([])
    assert_equal nil, @frontend.idle?
  end

  def test_sts
    @frontend.expects(:call_plugins).with(:sts, @sts_max_age)
    @frontend.sts(@sts_max_age)
  end

  def test_no_sts
    @frontend.expects(:call_plugins).with(:no_sts)
    @frontend.no_sts
  end

  def test_get_sts
    @frontend.expects(:call_plugins).with(:get_sts).returns([nil, @sts_max_age, nil])
    assert_equal @sts_max_age, @frontend.get_sts
  end

  def test_get_sts_nil?
    @frontend.expects(:call_plugins).with(:get_sts).returns([])
    assert_equal nil, @frontend.get_sts
  end


  def test_aliases
    @frontend.expects(:call_plugins).with(:aliases).returns([@test_alias])
    assert_equal [@test_alias], @frontend.aliases
  end

  def test_aliases_nil?
    @frontend.expects(:call_plugins).with(:aliases).returns([])
    assert_equal [], @frontend.aliases
  end

  def test_add_alias
    @frontend.expects(:clean_server_name).with(@test_alias).returns(@test_alias)
    @frontend.expects(:call_plugins).with(:add_alias, @test_alias)
    @frontend.add_alias(@test_alias)
  end

  def test_remove_alias
    @frontend.expects(:clean_server_name).with(@test_alias).returns(@test_alias)
    @frontend.expects(:call_plugins).with(:remove_alias, @test_alias)
    @frontend.remove_alias(@test_alias)
  end

  def test_ssl_certs
    @frontend.expects(:call_plugins).with(:ssl_certs).returns([@test_ssl_cert, @test_ssl_key_decrypted, @test_alias])
    assert_equal [@test_ssl_cert, @test_ssl_key_decrypted, @test_alias], @frontend.ssl_certs
  end

  def test_add_ssl_cert
    openssl_pkey = mock('OpenSSL::PKey')
    openssl_pkey.stubs(:to_pem).returns(@test_ssl_key_decrypted)
    openssl_pkey.stubs(:class).returns(OpenSSL::PKey::RSA)
    OpenSSL::PKey.stubs(:read).returns(openssl_pkey)

    openssl_cert = mock('OpenSSL::X509::Certificate')
    openssl_cert.stubs(:to_pem).returns(@test_ssl_cert)
    openssl_cert.stubs(:check_private_key).returns(true).then.returns(false)
    OpenSSL::X509::Certificate.stubs(:new).returns(openssl_cert)


    @frontend.expects(:call_plugins).with(:add_ssl_cert, @test_ssl_cert, @test_ssl_key_decrypted, @test_alias)
    @frontend.add_ssl_cert(@test_ssl_cert, @test_ssl_key, @test_alias, @test_ssl_key_passphrase)
  end

  def test_remove_ssl_cert
    @frontend.expects(:call_plugins).with(:remove_ssl_cert, @test_alias)
    @frontend.remove_ssl_cert(@test_alias)
  end

end
