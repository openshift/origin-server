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
    class PubSubConnector
      attr_reader :name, :connection_type
      RESERVED = {
          "publish-gear-endpoint" => 'NET_TCP:gear-endpoint-info',
          "publish-http-url" =>  'NET_TCP:httpd-proxy-info',
          "set-gear-endpoints" => 'NET_TCP:gear-endpoint-info'
      }

      def initialize(connection_type, name)
        @name = name
        @connection_type = connection_type
      end

      alias_method :to_s, :name

      # returns true if and only if this connector's name is
      # reserved by the platform
      def reserved?
        RESERVED.keys.include?(name) and RESERVED[name] == connection_type
      end

      ## name of the method invoked by the cartridge
      # since cartridge manifest specifies with hyphens,
      # substitute them with underscores
      def action_name
        name.gsub('-', '_').to_sym
      end
    end
  end
end
