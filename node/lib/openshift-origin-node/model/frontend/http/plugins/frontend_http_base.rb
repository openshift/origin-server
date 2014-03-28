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

module OpenShift
  module Runtime
    module Frontend
      module Http

        module Plugins

          @@plugins=[]
          def self.add_plugin(subclass)
              @@plugins << subclass
              @@plugins.uniq!
          end

          def self.plugins
            @@plugins.clone.freeze
          end

          class PluginException < StandardError
            attr_accessor :container_uuid, :fqdn

            def initialize(msg=nil, container_uuid=nil, fqdn=nil)
              @container_uuid = container_uuid
              @fqdn = fqdn
              super(msg)
            end

            def to_s
              m = super
              m+= ": #{@container_uuid}" if not @container_uuid.nil?
              m+= ": #{@fqdn}" if not @fqdn.nil?
              m
            end
          end

          class PluginExecException < PluginException
            attr_accessor :rc, :stdout, :stderr
            def initialize(msg=nil, container_uuid=nil, fqdn=nil,  rc=-1, stdout=nil, stderr=nil)
              @rc = rc
              @stdout = stdout
              @stderr = stderr
              super(msg, container_uuid, fqdn)
            end

            def to_s
              m = super
              m+= ": #{@container_uuid}" if not @container_uuid.nil?
              m+= ": #{@fqdn}" if not @fqdn.nil?
              m
            end
          end

          class PluginBaseClass
            SERVER_HTTP_PORT = 80
            SERVER_HTTPS_PORT = 443
            SERVER_CONNECT_ADDR = '127.0.0.1'

            attr_reader :container_uuid, :container_name, :namespace, :application_uuid
            attr_accessor :fqdn

            def initialize(container_uuid, fqdn, container_name, namespace, application_uuid=nil)
              @container_uuid = container_uuid
              @fqdn = fqdn
              @container_name = container_name
              @namespace = namespace

              # app uuid is ONLY used by connect() for storing the value in the nodes db.
              # it may not be populated during other invocations
              @application_uuid = application_uuid
            end

            def unprivileged_unidle
              begin
                http = Net::HTTP.new(SERVER_CONNECT_ADDR, SERVER_HTTP_PORT)
                http.open_timeout = 5
                http.read_timeout = 60
                http.use_ssl = false
                http.start do |client|
                  resp = client.request_head('/', { 'Host' => @fqdn })
                  resp.code
                end
              rescue
              end
            end

            def self.inherited(subclass)
              ::OpenShift::Runtime::Frontend::Http::Plugins::add_plugin(subclass)
            end
          end

        end
      end
    end
  end
end
