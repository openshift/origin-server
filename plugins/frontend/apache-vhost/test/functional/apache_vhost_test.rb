#--
# Copyright 2010 Red Hat, Inc.
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

require 'active_support/core_ext/class/attribute'

require 'openshift-origin-frontend-apache-vhost'
require 'test_helper'

require 'tmpdir'
require 'fileutils'

module OpenShift

  class ApacheVirtualHostsPluginTestCase < FrontendHttpPluginTestCase

    def setup
      @elements=[ ["", "1.2.3.4:5678", {"protocols" => [ "http" ]}],
                  ["/nosocket", "5.6.7.8:9012", {"protocols" => [ "http" ]}],
                  ["/gone", "", { "gone" => 1, "protocols" => [ "http" ] }],
                  ["/forbidden", "", { "forbidden" => 1, "protocols" => [ "http" ] }],
                  ["/noproxy", "", { "noproxy" => 1, "protocols" => [ "http" ] }],
                  ["/redirect", "/dest", { "redirect" => 1, "protocols" => [ "http" ] }],
                  ["/file", "/dest.html", { "file" => 1, "protocols" => [ "http" ] }],
                  ["/tohttps", "/dest", { "tohttps" => 1, "protocols" => [ "http" ] }],
                  ["/ssl_to_gear", "/dest", { "ssl_to_gear" => 1, "protocols" => [ "http", "https" ] }] ]

      @aliases=["foo.example.com", "bar.example.com"]
      @ssl_certs=[["SSL_CERT", "SSL_KEY", "bar.example.com"]]

      @basedir = Dir.mktmpdir
      FileUtils.cp(Dir.glob('httpd/*.erb'), @basedir)
      @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns(@basedir)

      @app_path = File.join(@basedir, "#{@container_uuid}_#{@namespace}_#{@container_name}")

      @plugin_class = ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheVirtualHosts
      @plugin = @plugin_class.new(@container_uuid, @fqdn, @container_name, @namespace)

      @plugin.stubs(:with_lock_and_reload).yields

      exercise_plugin_is_available

      @plugin.create
      assert File.exists?(@app_path), "App path must exist"
    end

    def test_connections
      app_cfg = File.join(@basedir, "#{@container_uuid}_#{@namespace}_0_#{@container_name}.conf")
      exercise_connections_api do |mode|
        case mode
        when :pre_set, :unset
          assert Dir.glob(File.join(@app_path, '5*_element-*.conf')).empty?, "There should not be any connection files"
        when :set, :pre_unset
          assert File.size?(app_cfg), "App configuration must exist"
          assert_equal @elements.length, Dir.glob(File.join(@app_path, '5*_element-*.conf')).length, "There should be a file for every connection"
        end
      end
    end

    def test_aliases
      exercise_aliases_api do |mode|
        @aliases.each do |server_alias|
          alias_path = File.join(@app_path, "888888_server_alias-#{server_alias}.conf")
          case mode
          when :pre_set, :unset
            assert (not File.exists?(alias_path)), "Alias file must not exist"
          when :set, :pre_unset
            assert File.size?(alias_path), "Alias file must exist and not be empty"
          end
        end
      end
    end

    def test_idle
      idle_path = File.join(@app_path, "000000_idler.conf")
      exercise_idle_api do |mode|
        case mode
        when :pre_set, :unset
          assert (not File.exists?(idle_path)), "Idler file should not exist"
        when :set, :pre_unset
          assert File.size?(idle_path), "Idler file should exist and be non-zero size"
        end
      end
    end

    def test_sts
      sts_path = File.join(@app_path, "000001_sts_header.conf")
      exercise_sts_api do |mode|
        case mode
        when :pre_set, :unset
          assert (not File.exists?(sts_path)), "STS file should not exist"
        when :set, :pre_unset
          assert File.size?(sts_path), "STS file should exist and be non-zero size"
        end
      end
    end

    def test_ssl
      exercise_ssl_api do |mode|
        @ssl_certs.each do |ssl_cert, ssl_key, server_alias|
          ssl_cfg = File.join(@basedir, "#{@container_uuid}_#{@namespace}_9_#{server_alias}.conf")
          alias_path = File.join(@app_path, "888888_server_alias-#{server_alias}.conf")
          case mode
          when :pre_set, :unset
            assert (not File.exists?(ssl_cfg)), "SSL conf file should not exist"
          when :set, :pre_unset
            assert File.size?(ssl_cfg), "SSL conf file should exist and not be empty"
            assert (not File.exists?(alias_path)), "Alias file must be replaced by SSL conf file"
            assert File.size?(File.join(@app_path, "#{server_alias}.crt")), "SSL cert file should exist and not be empty"
            assert File.size?(File.join(@app_path, "#{server_alias}.key")), "SSL key file should exist and not be empty"
            assert_equal ssl_cert, File.read(File.join(@app_path, "#{server_alias}.crt")).chomp, "Cert and saved cert should match"
            assert_equal ssl_key, File.read(File.join(@app_path, "#{server_alias}.key")).chomp, "Key and saved key should match"
          end
        end
      end
    end

    def teardown
      @plugin.destroy

      assert Dir.glob(File.join(@basedir, '#{@container_uuid}_*')).empty?, "There should be no files/dirs for the gear"

      FileUtils.rm_rf(@basedir)
    end

  end

end
