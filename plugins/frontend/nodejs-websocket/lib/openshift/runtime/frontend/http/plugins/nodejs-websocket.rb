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

            def self.purge_by_fqdn(fqdn)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                d.delete_if { |k, v| (k == fqdn) or (v["alias"] == fqdn) }
                d.delete_if { |k, v| k.split('/')[0] == fqdn }
              end
            end

            def destroy
              self.class.purge_by_fqdn(@fqdn)
            end

            def connect(*elements)
              reported_urls = []
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                elements.each do |path, uri, options|
                  # Check if the path supports websockets
                  next unless options["websocket"]

                  # Check if the endpoints support websockets
                  # next if options["protocols"] and ["ws"].select { |proto| options["protocols"].include?(proto) }.empty?

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

                  d.store(@fqdn + path, routes_ent)

                  d.select { |k, v| v["alias"] == @fqdn }.each do |k, v|
                    v.merge!(routes_ent)
                  end
                end
              end
              reported_urls
            end


            def connections
              begin
                NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                  routes_ent = d.fetch(@fqdn)
                  if routes_ent
                    path=""
                    uri = routes_ent["endpoints"].first
                    options={}
                    options.merge!(routes_ent["limits"])
                    options["websocket"]=1
                    options["protocols"]=[ "ws" ]
                    return [ [ path, uri, options ] ]
                  end
                end
              rescue
              end
              [ ]
            end


            def disconnect(*paths)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                paths.flatten.each do |p|
                  d.delete(@fqdn + p)
                end
              end
            end


            def idle
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                d.select { |k, v| ( k == @fqdn ) or (v["alias"] == @fqdn ) }.each do |k, entry|
                  entry["idle"]=@container_uuid
                end
              end
            end

            def unidle
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                d.select { |k, v| ( k == @fqdn ) or (v["alias"] == @fqdn ) }.each do |k, entry|
                  entry.delete("idle")
                end
              end
            end

            def idle?
              NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                if d[@fqdn]
                  return d[@fqdn]["idle"]
                end
              end
              nil
            end

            def aliases
              NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                return d.select { |k, v| v["alias"] == @fqdn }.map { |k, v| k }
              end
            end

            def add_alias(name)
              add_aliases([name])
            end

            def add_aliases(names)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                begin
                  routes_ent = d.fetch(@fqdn)
                  if not routes_ent.nil?
                    alias_ent = routes_ent.clone
                    alias_ent["alias"] = @fqdn
                    names.each do |name|
                      d.store(name, alias_ent)
                    end
                  end
                rescue KeyError
                end
              end
            end

            def remove_alias(name)
              remove_aliases([name])
            end

            def remove_aliases(names)
              NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
                names.each do |name|
                  d.delete(name)
                end
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
