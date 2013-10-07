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

require 'openshift-origin-frontend-nodejs-websocket'
require 'test_helper'

module OpenShift

  class NodeJsWebsocketPluginTestCase < FrontendHttpPluginTestCase

    def setup
      @db = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::NodeJSDBRoutes.stubs(:open).yields(@db)

      @elements=[["", "1.2.3.4:5678",
                   { "connections" => 3,
                     "bandwidth" => 2,
                     "websocket" => 1,
                     "protocols"=>["ws"] }]]

      @route_expected = {
        "endpoints" => [ "1.2.3.4:5678" ],
        "limits" => {
          "connections" => 3,
          "bandwidth" => 2
        }
      }

      @aliases=["foo.example.com", "bar.example.com"]
      @ssl_certs=[["SSL_CERT", "SSL_KEY", "bar.example.com"]]

      @plugin_class = ::OpenShift::Runtime::Frontend::Http::Plugins::NodeJSWebsocket
      @plugin = @plugin_class.new(@container_uuid, @fqdn, @container_name, @namespace)

      exercise_plugin_is_available
    end

    def test_connections
      exercise_connections_api do |mode|
        case mode
        when :pre_set, :unset
          assert @db.empty?, "Database should be empty."
        when :set, :pre_unset
          assert_equal @route_expected, @db[@fqdn]
        end
      end
    end

    def test_aliases
      @plugin.connect(*@elements)
      exercise_aliases_api do |mode|
        case mode
        when :pre_set, :unset
          assert (@aliases.select { |a| @db[a] }.empty?), "Database should not contain aliases."
        when :set, :pre_unset
          @aliases.each do |server_alias|
            assert_equal @route_expected.merge( { "alias" => @fqdn } ), @db[server_alias]
          end
        end
      end
    end

    def test_idle
      @plugin.connect(*@elements)
      exercise_idle_api do |mode|
        case mode
        when :pre_set, :unset
          assert (not @db[@fqdn]["idle"]), "Idle should be unset or false"
        when :set, :pre_unset
          assert_equal @container_uuid, @db[@fqdn]["idle"], "Idle should be set to the uuid"
        end
      end
    end

    def teardown
      @plugin.destroy
      assert @db.empty?, "Database should be empty."
    end

  end

end
