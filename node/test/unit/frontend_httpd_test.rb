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

  class HashWithBlock < Hash
    def update_block
      deletions = []
      updates = {}
      self.each do |k, v|
        yield(deletions, updates, k, v)
      end
      self.delete_if { |k, v| deletions.include?(k) }
      self.update(updates)
    end
  end

  def setup
    @container_uuid = '0123456789abcdef'
    @container_name = 'frontendtest'
    @namespace = 'frontendtest'
    
    @gear_base_dir = "/tmp/frontend_httpd_test"

    @http_conf_dir = "/tmp/frontend_httpd_test/.httpd.d"

    @cloud_domain = "example.com"

    @ip = "127.0.0.1"
    @port = 8080


    @fqdn = "#{@container_name}-#{@namespace}.#{@cloud_domain}"

    @test_alias = "foo.example.com"

    @test_ssl_path = "#{@http_conf_dir}/#{@container_uuid}_#{@namespace}_#{@test_alias}"
    
    @test_ssl_key_passphrase = "test"

    # openssl genrsa -des3 -out server.key 1024
    @test_ssl_key  = <<-ENDKEY
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,82BE784ABB45BDA2

8NPPoBj+YVK5G1XCmcKj1v45RQqivO3Ckiehk7bnfWvkGYIPwoFWfliDHyXtAyZh
ErfEPzZMDMR7/3/GPuGyHya+KSLj0pIyFUfmgBW+c4MqjsdizuNXCO9ArUTPIznE
nMcvmtUkIAwa6ApfbNtjokuUR1xIY+Jp72FLFYQudG0/yHyzGpc1usRCo6yXFKlb
lJGPsojFVZucriPxV7XeD1W3MN3dZtCZwxH8GpmRShc1zMUlRYNz0gkrub3Q3ZNb
/iZf90QWwuVGb7u8TaJllF9za0ZGsyh3B5pH7tn6hRWj67e7zuvBN36s/W4vYnYt
mZhC0gkZv5x1YBdJLh9fPxhJU5i//4i0rBtCIvVF60fjUwK+2Vr4unfR6NWRuBFW
bUDIUbEWKwfDufH6/wOWSuVxNUU8c0OaU8OyLQc9iKhXXRgtLHWtQBWPJ2Ifpp7t
C/VAo0jgf3NyyK00BwTo17YNEBBEZ5mhwto5bnOwZZmRmfb+QjpVsu1XPLCVICwO
l7FSFuZnQJyI+nk9CF0NVBOERUlLzgwlWFMIGRcjHIvsMIyrTdYXiD19ps4RrN3K
K1dTmSIW+XhVPKZle60Nm6XMiYE4uSCIafmPRNnp09Q+2pDT4YN2vf4Q4fML5WWs
1d2q6bBoOHeeFN+I7+SjC5nDe1s7z4jHNXFEaZYvB4mPHqjTpOYUsrCNRjMhUFCU
m+uvN+spwMl+/n/Jgo+FrD34i+y43b/q52llEZ52RIytEMwOp52J+pDgucqsvgDe
TCUTshnh8NaHiRmqoxNgrhAqBn7ZfL5CqUkFeCbd2vmWq0Pm9agVEQ==
-----END RSA PRIVATE KEY-----
      ENDKEY

    # openssl req -new -key server.key -out server.csr
    # openssl x509 -req -days 6000 -in server.csr -signkey server.key -out server.crt
    @test_ssl_cert = <<-ENDCERT
-----BEGIN CERTIFICATE-----
MIICzTCCAjYCCQCiAy/+JlyDsTANBgkqhkiG9w0BAQUFADCBqjELMAkGA1UEBhMC
VVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcMDU1vdW50YWluIFZpZXcx
FjAUBgNVBAoMDVJlZCBIYXQsIEluYy4xGTAXBgNVBAsMEE9wZW5TaGlmdCBPcmln
aW4xGDAWBgNVBAMMD2Zvby5leGFtcGxlLmNvbTEhMB8GCSqGSIb3DQEJARYSc3Vw
cG9ydEByZWRoYXQuY29tMB4XDTEzMDIwNzIwNTg0MloXDTI5MDcxMzIwNTg0Mlow
gaoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1N
b3VudGFpbiBWaWV3MRYwFAYDVQQKDA1SZWQgSGF0LCBJbmMuMRkwFwYDVQQLDBBP
cGVuU2hpZnQgT3JpZ2luMRgwFgYDVQQDDA9mb28uZXhhbXBsZS5jb20xITAfBgkq
hkiG9w0BCQEWEnN1cHBvcnRAcmVkaGF0LmNvbTCBnzANBgkqhkiG9w0BAQEFAAOB
jQAwgYkCgYEAz21+FdR0xgqxuUIlBZA9DXO8h2lCwv8jyEe2HtmTlpXyA/e7fwR2
DbCDWCUXmLepF1gueDfZVcYmtWmTfRSmitlZO02EJoDXLE1kS7Q96k4QTxRWf92N
+T5bgRq3RO5LHUc6x8zjCglh7oloEji7THYgI1MNdenjIQ7wCTJHpQkCAwEAATAN
BgkqhkiG9w0BAQUFAAOBgQDAMijfZS1abyIRT9CjCV8mBuCkJLOikFTrOlHZ9MtS
GLZ5zXzsIp3CdXEVb3K9SkHcADgrbwW1EyQ0XvERvRskIpSiOFVlNler6oETTtWb
wfAWcha1nq0zdqHmkkY1jC+1RBY7J3Z7TQ/eS0Q5hjBwCa2wSUcxdLboGUQOujr0
og==
-----END CERTIFICATE-----
    ENDCERT

    # 
    @test_ssl_key_decrypted = <<-ENDUNENC
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDPbX4V1HTGCrG5QiUFkD0Nc7yHaULC/yPIR7Ye2ZOWlfID97t/
BHYNsINYJReYt6kXWC54N9lVxia1aZN9FKaK2Vk7TYQmgNcsTWRLtD3qThBPFFZ/
3Y35PluBGrdE7ksdRzrHzOMKCWHuiWgSOLtMdiAjUw116eMhDvAJMkelCQIDAQAB
AoGBALVkW9F9REz3hymp1TRDSZCc+G42N6LMeZ8oTvQ1cuJJ6CVeG8Hcxdv80y9e
6H6thZobjC+nL1DaAnm8hLTqPSQ2Ew1aN8hflWG2/3c08gNWtVcHHeOAqFu1PHp8
tduhdeER1v1NGSMSKNhpPQMH3DMsPMZYqsoX3hoLhx0HzAhtAkEA6Vp83HToJsF3
R/j2wuosfwJZ3+X8FcdQg7e/YwoF9jWB+2gvGmAWe3SmUYaUbdaIdcdoE8bAmZDH
hj9XOH2XFwJBAOOO5XnuHDk1txwmeWvyID8EiLCAmgOR6a71QFNBfGsPGuAU8Srf
nHDBFHuXjgVuRMrSDHPglosJolmOJD9MON8CQDZudAecgXZg1GkGatDmfMCXlM1E
QTv3RRGkb9EzSla2/n3dPHeDiFr9x7nmkYLZcvU+MUnDp7NqcRAggEDeErsCQQC9
vEPyKms1+Ge4/Qt4yeXBJZKjOFcyatMhojQENzH6QhnyhQOg79mM2jCt7Gvqc0rA
oeroI3bibyIC8dWfQXqZAkAJ2am/2bABeg4eo79V0Bu2IsxQ77dUfz+TGai5Hu4R
ytYgLyNNmHGLkwPPD37TltmpbSZubmnOJ+VyHBTupibe
-----END RSA PRIVATE KEY-----
    ENDUNENC

    syslog_mock = mock('Syslog') do
      stubs(:opened?).returns(true)
      stubs(:open).returns(nil)
      stubs(:alert).returns(nil)
      stubs(:debug).returns(nil)
    end
    Syslog.stubs(:new).returns(syslog_mock)

    config_mock = mock('OpenShift::Config') do
      stubs(:get).with("GEAR_BASE_DIR").returns(@gear_base_dir)
      stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns(@http_conf_dir)
      stubs(:get).with("CLOUD_DOMAIN").returns(@cloud_domain)
    end
    OpenShift::Config.stubs(:new).returns(config_mock)

    @container_info_db = HashWithBlock.new
    @container_info_db_full = { @container_uuid => { "container_name" => @container_name, "namespace" => @namespace } }
    ContainerInfoDB.stubs(:open).yields(@container_info_db)

    @apache_db_nodes = HashWithBlock.new
    @apache_db_nodes_full = { @fqdn => "#{@ip}:#{@port}" }
    ApacheDBNodes.stubs(:open).yields(@apache_db_nodes)

    @apache_db_aliases = HashWithBlock.new
    @apache_db_aliases_full = { @test_alias => @fqdn }
    ApacheDBAliases.stubs(:open).yields(@apache_db_aliases)

    @apache_db_idler = HashWithBlock.new
    @apache_db_idler_full = { @fqdn => @container_uuid }
    ApacheDBIdler.stubs(:open).yields(@apache_db_idler)

    @nodejs_db_routes = HashWithBlock.new
    @nodejs_db_routes_full = {
      @fqdn => {
        "endpoints" => [ "#{@ip}:#{@port}" ],
        "limits"    => {
          "connections" => 5,
          "bandwidth"   => 100
        }
      },
      @test_alias => {
        "endpoints" => [ "#{@ip}:#{@port}" ],
        "alias" => @fqdn,
        "limits"    => {
          "connections" => 5,
          "bandwidth"   => 100
        }
      }
    }
    NodeJSDBRoutes.stubs(:open).yields(@nodejs_db_routes)
  end

  def set_dbs_empty
    @container_info_db.replace({})
    @apache_db_nodes.replace({})
    @apache_db_aliases.replace({})
    @apache_db_idler.replace({})
    @nodejs_db_routes.replace({})
  end

  def check_dbs_empty
    assert @container_info_db.empty?, "ContainerInfoDB not empty"
    assert @apache_db_nodes.empty?, "ApacheDBNodes not empty"
    assert @apache_db_aliases.empty?, "ApacheDBAliases not empty"
    assert @apache_db_idler.empty?, "ApacheDBIdler not empty"
    assert @nodejs_db_routes.empty?, "NodeJSDBRoutes not empty"
  end

  def check_dbs_not_empty
    assert (not @container_info_db.empty?), "ContainerInfoDB empty"
    assert (not @apache_db_nodes.empty?), "ApacheDBNodes empty"
    assert (not @apache_db_aliases.empty?), "ApacheDBAliases empty"
    assert (not @apache_db_idler.empty?), "ApacheDBIdler empty"
    assert (not @nodejs_db_routes.empty?), "NodeJSDBRoutes empty"
  end

  def set_dbs_full
    @container_info_db.replace(@container_info_db_full)
    @apache_db_nodes.replace(@apache_db_nodes_full)
    @apache_db_aliases.replace(@apache_db_aliases_full)
    @apache_db_idler.replace(@apache_db_idler_full)
    @nodejs_db_routes.replace(@nodejs_db_routes_full)
  end

  def check_dbs_full
    assert_equal @container_info_db, @container_info_db_full, "ContainerInfoDB not properly set"
    assert_equal @apache_db_nodes, @apache_db_nodes_full, "ApacheDBNodes not properly set"
    assert_equal @apache_db_aliases, @apache_db_aliases_full, "ApacheDBAliases not properly set"
    assert_equal @apache_db_idler, @apache_db_idler_full, "ApacheDBIdler not properly set"
    assert_equal @nodejs_db_routes, @nodejs_db_routes_full, "NodeJSDBRoutes not properly set"
  end

  def test_clean_server_name
    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    
    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}")
    assert_equal "#{@test_alias}", frontend.clean_server_name("#{@test_alias}".upcase)
    assert_raise OpenShift::FrontendHttpServerNameException do
      frontend.clean_server_name("../../../../../../../etc/passwd")
    end
  end

  def test_create
    set_dbs_empty

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create

    assert_equal @container_info_db, @container_info_db_full, "Failed to populate ContainerInfoDB"
  end

  def test_create_initialized
    set_dbs_full

    assert_nothing_raised do
      frontend = OpenShift::FrontendHttpServer.new(@container_uuid)
    end

    assert_equal frontend.container_name, @container_name
    assert_equal frontend.namespace, @namespace
  end

  def test_initialize_uncreated
    set_dbs_empty

    assert_raise Openshift::FrontendHttpServerException do
      frontend = OpenShift::FrontendHttpServer.new(@container_uuid)
    end
  end


  def test_destroy
    set_dbs_full

    Dir.stubs(:glob).returns(["foo.conf"]).once
    FileUtils.stubs(:rm_rf).once
    frontend.stubs(:shellCmd).returns(["", "", 0]).once

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.destroy

    check_dbs_empty
  end


  def test_update
    set_dbs_full

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.update_name("new_name")
    frontend.update_namespace("new_namespace")

    new_fqdn = "new_name-new_namespace.#{@cloud_domain}"

    assert_equal frontend.container_name, "new_name"
    assert_equal frontend.namespace, "new_namespace"
    assert_equal frontend.fqdn, new_fqdn

    check_dbs_not_empty

    assert_equal @container_info_db[@container_uuid]["container_name"], "new_name"
    assert_equal @container_info_db[@container_uuid]["namespace"], "new_namespace"

    assert_equal @apache_db_nodes[new_fqdn], @apache_db_nodes_full[@fqdn]

    assert_equal @apache_db_aliases[@test_alias], new_fqdn

    assert_equal @apache_db_idler[new_fqdn], @container_uuid

    assert_equal @nodejs_db_routes[new_fqdn], @nodejs_db_routes_full[@fqdn]
  end

  def test_connections
    set_dbs_empty

    connections = [ ["", "#{@ip}:#{@port}", { "websocket" => 1}],
                    ["/nosocket", "#{@ip}:#{@port}",{}],
                    ["/gone", "", { "gone" => 1 }],
                    ["/forbidden", "", { "forbidden" => 1 }],
                    ["/noproxy", "", { "noproxy" => 1 }],
                    ["/redirect", "/dest", { "redirect" => 1 }],
                    ["/file", "/dest.html", { "file" => 1 }],
                    ["/tohttps", "/dest", { "tohttps" => 1 }] ]

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create
    frontend.connect(connections)

    assert (not @container_info_db.empty?), "ContainerInfoDB empty"
    assert (not @apache_db_nodes.empty?), "ApacheDBNodes empty"
    assert (not @nodejs_db_routes.empty?), "NodeJSDBRoutes empty"

    assert_equal @apache_db_nodes[@fqdn], "#{@ip}:#{@port}"
    assert_equal @apache_db_nodes[@fqdn +"/nosocket"], "#{@ip}:#{@port}"
    assert_equal @apache_db_nodes[@fqdn +"/gone"], "GONE"
    assert_equal @apache_db_nodes[@fqdn +"/forbidden"], "FORBIDDEN"
    assert_equal @apache_db_nodes[@fqdn +"/noproxy"], "NOPROXY"
    assert_equal @apache_db_nodes[@fqdn +"/redirect"], "REDIRECT:/dest"
    assert_equal @apache_db_nodes[@fqdn +"/file"], "FILE:/dest,html"
    assert_equal @apache_db_nodes[@fqdn +"/tohttps"], "TOHTTPS:/dest"

    assert_equal @nodejs_db_routes[@fqdn], @nodejs_db_routes_full[@fqdn]


    returned_connections = frontend.connections
    assert_equal returned_connections, connections


    frontend.disconnect("", "/nosocket", "/gone", "/forbidden", "/noproxy", "/redirect", "/file", "/tohttps")
    assert @apache_db_nodes.empty?
    assert @nodejs_db_routes.empty?
  end

  def test_idle
    set_dbs_empty

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create

    frontend.idle
    assert_equal @apache_db_idler[@fqdn], @container_uuid

    assert frontend.idle?

    frontend.undidle
    assert @apache_db_idler.empty?
  end

  def test_aliases
    set_dbs_empty

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create
    frontend.connect("", "#{@ip}:#{@port}", { "websocket" => 1})
    frontend.add_alias("#{@test_alias}")

    assert (not @apache_db_aliases.empty?)
    assert (not @nodejs_db_routes.empty?)
    assert (not @nodejs_db_routes[@test_alias].nil?)

    assert_equal @apache_db_aliases[@test_alias], @fqdn

    assert_equal @nodejs_db_routes[@test_alias], @nodejs_db_routes[@fqdn]

    assert_equal frontend.aliases, [@test_alias]

    frontend.remove_alias(@test_alias)

    assert @apache_db_aliases.empty?
    assert (not @nodejs_db_routes.has_key?(@test_alias))
  end

  def test_ssl_certs
    set_dbs_empty

    openssl_pkey = Mock('OpenSSL::PKey') do
      stubs(:to_pem).returns(@test_ssl_key_decrypted).once
      stubs(:check_private_key).returns(true).then.returns(false)
      stubs(:class).returns(OpenSSL::PKey::RSA).once
    end
    OpenSSL::PKey.stubs(:read).with(@test_ssl_key, @test_ssl_key_passphrase).returns(openssl_pkey)

    openssl_cert = Mock('OpenSSL::X509::Certificate') do
      stubs(:to_pem).returns(@test_ssl_cert).once
    end
    OpenSSL::X509::Certificate.stubs(:new).with(@test_ssl_cert).returns(openssl_cert)


    FileUtils.stubs(:mkdir_p).with(@test_ssl_path).once
    File.stubs(:open).with("#{@test_ssl_path}/#{@test_alias}.crt", 'w').once
    File.stubs(:open).with("#{@test_ssl_path}/#{@test_alias}.key", 'w').once
    File.stubs(:open).with("#{@test_ssl_path}.conf", 'w').once

    File.stubs(:read).with("#{@test_ssl_path}/#{@test_alias}.crt").returns(@test_ssl_cert).once
    File.stubs(:read).with("#{@test_ssl_path}/#{@test_alias}.key").returns(@test_ssl_key_decrypted).once

    File.stubs(:exists?).with(@test_ssl_path).returns(true).once
    File.stubs(:exists?).with("#{@test_ssl_path}.conf").returns(true).once
    FileUtils.stubs(:rm_rf).with(@test_ssl_path).once
    FileUtils.stubs(:rm_rf).with("#{@test_ssl_path}.conf").once

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create
    frontend.connect("", "#{@ip}:#{@port}", { "websocket" => 1})
    frontend.add_alias("#{@test_alias}")

    frontend.stubs(:shellCmd).returns(["", "", 0]).twice


    frontend.add_ssl_cert(@test_ssl_cert, @test_ssl_key, @test_alias, @test_ssl_key_passphrase)

    assert_equal frontend.ssl_certs, [@test_ssl_cert, @test_ssl_key, @test_alias]

    frontend.remove_ssl_cert(@test_alias)

    # check_private_key returns false
    assert_raise FrontendHttpServerException do
      frontend.add_ssl_cert(@test_ssl_cert, @test_ssl_key, @test_alias)
    end

    # bad alias
    assert_raise FrontendHttpServerException do
      frontend.add_ssl_cert(@test_ssl_cert, @test_ssl_key, @test_alias.reverse)
    end
  end


  def test_serialization
    set_dbs_empty

    frontend = OpenShift::FrontendHttpServer.new(@container_uuid, @container_name, @namespace)
    frontend.create
    frontend.connect("", "#{@ip}:#{@port}", { "websocket" => 1})
    frontend.add_alias("#{@test_alias}")

    fehash = frontend.to_hash

    set_dbs_empty

    new_frontend = OpenShift::FrontendHttpServer.json_create( { 'data' => fehash } )

    assert_equal new_frontend.container_uuid, @container_uuid
    assert_equal new_frontend.container_name, @container_name
    assert_equal new_frontend.namespace, @namespace

    assert @apache_db_route.has_key?(@fqdn)
    assert_equal @apache_db_route[@fqdn], "#{@ip}:#{@port}"

    assert @nodejs_db_routes.has_key?(@fqdn)
    assert @nodejs_db_routes.has_key?(@test_alias)
    assert (not @nodejs_db_routes[@fqdn].nil?)
    assert_equal @nodejs_db_routes[@test_alias], @nodejs_db_routes[@fqdn]
  end

end

class TestApacheDB < Test::Unit::TestCase
end
