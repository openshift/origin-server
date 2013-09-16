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

require 'rubygems'
require 'openshift-origin-frontend-apachedb'
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'

$OpenShift_NodeJSDBRoutes_Lock = Mutex.new

module OpenShift
  module Runtime
    module Frontend
      module Http
        module Plugins

          class NodeJSWebsocket < PluginBaseClass

            SERVER_HTTP_PORT = 8000
            SERVER_HTTPS_PORT = 8443

            def destroy
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                d.delete_if { |k, v| (k == @fqdn) or (v["alias"] == @fqdn) }
              end
            end

            def connect(*elements)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                elements.each do |path, uri, options|

                  next unless path == ""
                  next unless options["websocket"]

                  conn = options["connections"]
                  if conn.nil?
                    conn = 5
                  end

                  bw = options["bandwidth"]
                  if bw.nil?
                    bw = 100
                  end

                  # Use the websocket port if it is passed as an option
                  port = options["websocket_port"]
                  if port
                    uri = uri.sub(/:(\d)+/, ":" + port.to_s)
                  end

                  routes_ent = {
                    "endpoints" => [ uri ],
                    "limits"    => {
                      "connections" => conn,
                      "bandwidth"   => bw
                    }
                  }

                  d.store(@fqdn, routes_ent)

                  d.select { |k, v| v["alias"] == @fqdn }.each do |k, v|
                    v.merge!(routes_ent)
                  end
                end
              end
            end


            def connections
              begin
                NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                  routes_ent = d.fetch(@fqdn)
                  path=""
                  uri = routes_ent["endpoints"].first
                  options={}
                  options.merge!(routes_ent["limits"])
                  options["websocket"]=1
                  return [ [ path, uri, options ] ]
                end
              rescue
              end
              [ ]
            end


            def disconnect(*paths)
              if paths.flatten.include?("")
                NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                  d.delete(@fqdn)
                end
              end
            end

            # Idler is not yet implemented for nodejs and this implementation
            # should change to reflect alias handling.
            #
            # def idle
            #  NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
            #    d[@fqdn]["idle"]=@container_uuid
            #  end
            # end

            # def unidle
            #  NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
            #    d[@fqdn].delete("idle")
            #  end
            # end

            # def idle?
            #  NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
            #    return d[@fqdn]["idle"]
            #  end
            # end

            def aliases
              NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                return d.select { |k, v| v["alias"] == @fqdn }.map { |k, v| k }
              end
            end

            def add_alias(name)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                begin
                  routes_ent = d.fetch(@fqdn)
                  if not routes_ent.nil?
                    alias_ent = routes_ent.clone
                    alias_ent["alias"] = @fqdn
                    d.store(name, alias_ent)
                  end
                rescue KeyError
                end
              end
            end

            def remove_alias(name)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                d.delete(name)
              end
            end

          end

          class NodeJSDB < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBJSON
            def callout
              childpidfile = "/var/run/openshift-node-web-proxy.pid"
              begin
                cpid = File.read(childpidfile).to_i
                if cpid != 0
                  Process.kill("HUP", cpid)
                end
              rescue Errno::ENOENT
                # No child PID file
              rescue Errno::ESRCH
                # No such process
              end
            end
          end

          class NodeJSDBRoutes < NodeJSDB
            self.MAPNAME = "routes"
            self.LOCK = $OpenShift_NodeJSDBRoutes_Lock
          end

        end
      end
    end
  end
end
