#--
# Copyright 2014 Red Hat, Inc.
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

    # Encapsulate the V2 Cartridge Identifier
    class Ident
      attr_reader :cartridge_vendor, :name, :software_version, :cartridge_version

      def initialize(cartridge_vendor, name, software_version, cartridge_version = nil)
        @cartridge_vendor  = cartridge_vendor.gsub(/\s+/, '').downcase if cartridge_vendor
        @name              = name
        @software_version  = software_version
        @cartridge_version = cartridge_version
      end

      def to_s
        "#{@cartridge_vendor}:#{@name}:#{@software_version}:#{@cartridge_version}"
      end

      def to_name
        "#{@name}-#{@software_version}"
      end

      def self.parse(ident)
        cooked = ident.split(':')
        raise ArgumentError.new("'#{ident}' is not a legal cartridge identifier") if 4 != cooked.size
        Ident.new(*cooked)
      end
    end
  end
end
