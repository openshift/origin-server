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

require 'openshift-origin-frontend-apache-mod-rewrite'
require 'test_helper'

require 'tmpdir'
require 'fileutils'

module OpenShift

  class ApacheModRewritePluginTestCase < FrontendHttpPluginTestCase

    def setup
      @apachedb_nodes = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBNodes.stubs(:open).yields(@apachedb_nodes)

      @apachedb_aliases = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBAliases.stubs(:open).yields(@apachedb_aliases)

      @apachedb_idler = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBIdler.stubs(:open).yields(@apachedb_idler)

      @apachedb_sts = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBSTS.stubs(:open).yields(@apachedb_sts)

      @basedir = Dir.mktmpdir
      FileUtils.cp(Dir.glob('httpd/*.erb'), @basedir)
      @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns(@basedir)

      ::OpenShift::Runtime::Frontend::Http::Plugins.stubs(:reload_httpd)

      @elements=[ ["", "1.2.3.4:5678", { "protocols" => [ "http" ]}],
                  ["/nosocket", "5.6.7.8:9012", {"protocols" => [ "http" ]}],
                  ["/gone", "", { "gone" => 1, "protocols" => [ "http" ] }],
                  ["/forbidden", "", { "forbidden" => 1, "protocols" => [ "http" ] }],
                  ["/noproxy", "", { "noproxy" => 1, "protocols" => [ "http" ] }],
                  ["/redirect", "/dest", { "redirect" => 1, "protocols" => [ "http" ] }],
                  ["/file", "/dest.html", { "file" => 1, "protocols" => [ "http" ] }],
                  ["/tohttps", "/dest", { "tohttps" => 1, "protocols" => [ "http" ] }],
                  ["/ssl_to_gear", "/dest", { "ssl_to_gear" => 1, "protocols" => [ "http", "https" ] }] ]

      @nodes_expected = {
        "#{@fqdn}" => "1.2.3.4:5678",
        "#{@fqdn}/nosocket" => "5.6.7.8:9012",
        "#{@fqdn}/gone" => "GONE",
        "#{@fqdn}/forbidden" => "FORBIDDEN",
        "#{@fqdn}/noproxy" => "NOPROXY",
        "#{@fqdn}/redirect" => "REDIRECT:/dest",
        "#{@fqdn}/file" => "FILE:/dest.html",
        "#{@fqdn}/tohttps" => "TOHTTPS:/dest",
        "#{@fqdn}/ssl_to_gear" => "SSL_TO_GEAR:/dest"
      }


      @aliases=["foo.example.com", "bar.example.com"]
      @ssl_certs=[["SSL_CERT", "SSL_KEY", "bar.example.com"]]

      @plugin_class = ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheModRewrite
      @plugin = @plugin_class.new(@container_uuid, @fqdn, @container_name, @namespace)

      exercise_plugin_is_available
    end

    def test_connections
      exercise_connections_api do |mode|
        case mode
        when :pre_set, :unset
          assert @apachedb_nodes.empty?, "Nodes should be empty"
        when :set, :pre_unset
          assert_equal @nodes_expected, @apachedb_nodes
        end
      end
    end

    def test_aliases
      exercise_aliases_api do |mode|
        case mode
        when :pre_set, :unset
          assert @apachedb_aliases.empty?, "Aliases should be empty"
        when :set, :pre_unset
          @aliases.each do |server_alias|
            assert_equal @fqdn, @apachedb_aliases[server_alias]
          end
        end
      end
    end

    def test_idle
      exercise_idle_api do |mode|
        case mode
        when :pre_set, :unset
          assert @apachedb_idler.empty?, "Idler should be empty"
        when :set, :pre_unset
          assert_equal @container_uuid, @apachedb_idler[@fqdn]
        end
      end
    end

    def test_sts
      exercise_sts_api do |mode|
        case mode
        when :pre_set, :unset
          assert @apachedb_sts.empty?, "STS should be empty"
        when :set, :pre_unset
          assert @apachedb_sts.has_key?(@fqdn), "STS should have an entry"
        end
      end
    end

    def test_ssl
      exercise_ssl_api do |mode|
        @ssl_certs.each do |ssl_cert, ssl_key, server_alias|
          confdir = File.join(@basedir, "#{@container_uuid}_#{@namespace}_#{server_alias}")
          conffile = confdir + ".conf"

          case mode
          when :pre_set, :unset
            assert (not File.exists?(conffile)), "SSL conf file should not exist"
            assert (not File.exists?(confdir)), "SSL config dir should not exist"
          when :set, :pre_unset
            assert File.exists?(conffile), "SSL conf file should exist"
            assert File.exists?(confdir), "SSL conf dir should exist"
            assert File.exists?(File.join(confdir, "#{server_alias}.crt")), "SSL cert file should exist"
            assert File.exists?(File.join(confdir, "#{server_alias}.key")), "SSL key file should exist"
            assert_equal ssl_cert, File.read(File.join(confdir, "#{server_alias}.crt")).chomp
            assert_equal ssl_key, File.read(File.join(confdir, "#{server_alias}.key")).chomp
          end
        end
      end
    end

    def teardown
      @plugin.destroy

      assert @apachedb_nodes.empty?, "Nodes should be empty"
      assert @apachedb_aliases.empty?, "ALiases should be empty"
      assert @apachedb_idler.empty?, "Idler should be empty"
      assert @apachedb_sts.empty?, "STS should be empty"

      assert Dir.glob(File.join(@basedir, '#{@container_uuid}_*')).empty?, "There should be no files/dirs for the gear"

      FileUtils.rm_rf(@basedir)
    end

  end

end
