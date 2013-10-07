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

require 'active_support/core_ext/class/attribute'

require 'openshift-origin-frontend-haproxy-sni-proxy'
require 'test_helper'

module OpenShift

  class HaproxySNIProxyPluginTestCase < FrontendHttpPluginTestCase

    def setup
      @db = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::HaproxySNIProxyDB.stubs(:open).yields(@db)

      @sni_ports = [2303, 2304, 2305, 2306, 2307, 2308]
      ::OpenShift::Runtime::Frontend::Http::Plugins::HaproxySNIProxyDB.stubs(:get_ports).returns(@sni_ports)

      @aliases=["foo.example.com", "bar.example.com"]

      @elements=[ [ "TLS_PORT_1", "1.2.3.4:5678", { "protocols"=>["tls"] } ],
                  [ "TLS_PORT_2", "5.6.7.8:9012", { "protocols"=>["tls"] } ] ]

      @blank_entry = { "aliases" => [], "connections" => {} }
      @full_entry = { "aliases" => [], "connections" => {} }
      @full_entry["connections"][2303]="1.2.3.4:5678"
      @full_entry["connections"][2304]="5.6.7.8:9012"

      @reported_urls = [ "tls:#{@fqdn}:2303", "tls:#{@fqdn}:2304" ]

      @plugin_class = ::OpenShift::Runtime::Frontend::Http::Plugins::HaproxySNIProxy
      @plugin = @plugin_class.new(@container_uuid, @fqdn, @container_name, @namespace)

      exercise_plugin_is_available

      @plugin.create
      assert_equal @blank_entry, @db[@fqdn]
    end

    def test_connections
      exercise_connections_api do |mode|
        case mode
        when :pre_set, :unset
          assert_equal @blank_entry, @db[@fqdn], "Database entry should be pristine"
        when :set, :pre_unset
          assert_equal @full_entry, @db[@fqdn], "Database entry should be populated"
        end
      end
    end

    def test_connect_pick_port
      assert_equal @blank_entry, @db[@fqdn]
      @plugin.connect([ "", "1.2.3.4:5678", { "protocols"=>["tls"] } ], [ "TLS_PORT_2", "5.6.7.8:9012", { "protocols"=>["tls"] } ] )

      assert_equal @full_entry, @db[@fqdn], "Automatic port selection failed."
    end

    def test_aliases
      exercise_aliases_api do |mode|
        case mode
        when :pre_set, :unset
          assert @db[@fqdn]["aliases"].empty?, "Database should not contain aliases."
        when :set, :pre_unset
          assert_equal @aliases.sort, @db[@fqdn]["aliases"].sort
        end
      end
    end

    def teardown
      @plugin.destroy
      assert @db.empty?, "Database should be empty."
    end

  end

end
