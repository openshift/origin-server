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

require 'yaml'

module OpenShift

  # Manifest element in error
  class ElementError < KeyError
    attr_reader :element

    def initialize(message = nil, element = nil)
      super(message)
      @element = element
    end

    def to_s
      super + ": '#{@element}'"
    end
  end

  # Missing required  manifest element
  class MissingElementError < ElementError
    def initialize(message = 'Missing required element', element = nil)
      super(message)
      @element = element
    end
  end

  # Invalid required  manifest element
  class InvalidElementError < ElementError
    def initialize(message = 'Invalid value for required element', element = nil)
      super(message)
      @element = element
    end
  end

  # FIXME: Why is this class in it's own namespace?
  module Runtime
    #
    # Cartridge is a wrapper class for cartridge manifests.
    #
    # Wrapper speeds up access and provides fixed API
    class Cartridge

      #
      # Class to support Manifest +Endpoint+ elements
      class Endpoint
        @@ENDPOINT_PATTERN = /([A-Z_0-9]+):([A-Z_0-9]+)\((\d+)\):?([A-Z_0-9]+)?/

        attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name

        # :call-seq:
        #   Endpoint.parse(short_name, manifest) -> [Endpoint]
        #
        # Parse +Endpoint+ element and instantiate Endpoint objects to hold information
        #
        #   Endpoint.parse('PHP', manifest)  #=> [Endpoint]
        def self.parse(short_name, manifest)
          #FIXME: refactor for new Manifest Endpoint entries
          return [] unless manifest['Endpoints']

          tag       = short_name.upcase
          errors    = []
          endpoints = manifest['Endpoints'].each_with_object([]) do |entry, memo|
            unless entry.is_a? String
              errors << "Non-String endpoint entry: #{entry}"
              next
            end

            @@ENDPOINT_PATTERN.match(entry) do |m|
              begin
                private_ip_name     = m[1]
                private_port_name   = m[2]
                private_port_number = m[3].to_i
                public_port_name    = m[4]

                endpoint                   = Endpoint.new
                endpoint.private_ip_name   = "OPENSHIFT_#{tag}_#{private_ip_name}"
                endpoint.private_port_name = "OPENSHIFT_#{tag}_#{private_port_name}"
                endpoint.private_port      = private_port_number
                endpoint.public_port_name  = public_port_name ? "OPENSHIFT_#{tag}_#{public_port_name}" : nil
                endpoint.public_port_name  = public_port_name ? "OPENSHIFT_#{tag}_#{public_port_name}" : nil

                memo << endpoint
              rescue Exception => e
                errors << "Couldn't parse endpoint entry '#{entry}': #{e.message}"
              end
            end
          end
          raise "Couldn't parse endpoints: #{errors.join("\n")}" if errors.length > 0

          endpoints
        end
      end

      attr_reader :cartridge_vendor,
                  :cartridge_version,
                  :directory,
                  :endpoints,
                  :manifest,
                  :name,
                  :namespace,
                  :repository_path,
                  :short_name,
                  :version

      # :call-seq:
      #   Cartridge.new(manifest_path) -> Cartridge
      #
      # Cartridge is a wrapper class for cartridge manifests
      #
      #   Cartridge.new('/var/lib/openshift/.cartridge_repository/php/1.0/metadata/manifest.yml') -> Cartridge
      def initialize(manifest_path, repository_base_path='')
        manifest = YAML.load_file(manifest_path)

        @cartridge_vendor  = manifest['Cartridge-Vendor']
        @cartridge_version = manifest['Cartridge-Version'] && manifest['Cartridge-Version'].to_s
        @manifest          = manifest
        @name              = manifest['Name']
        @namespace         = manifest['Namespace'] || manifest['Cartridge-Short-Name']
        @short_name        = manifest['Cartridge-Short-Name'] || manifest['Namespace']
        @version           = manifest['Version'] && manifest['Version'].to_s

        #FIXME: reinstate code after manifests are updated
        #raise MissingElementError.new(nil, 'Cartridge-Vendor') unless @cartridge_vendor
        #raise InvalidElementError.new(nil, 'Cartridge-Vendor') if @cartridge_vendor.include?('-')
        #raise MissingElementError.new(nil, 'Cartridge-Version') unless @cartridge_version
        #raise MissingElementError.new(nil, 'Cartridge-Short-Name') unless @short_name
        #raise InvalidElementError.new(nil, 'Cartridge-Short-Name') if @short_name.include?('-')
        #raise MissingElementError.new(nil, 'Name') unless @name
        #raise InvalidElementError.new(nil, 'Name') if @name.include?('-')
        raise MissingElementError.new(nil, 'Version') unless @version
        raise InvalidElementError.new(nil, 'Versions') if @manifest['Versions'] && !@manifest['Versions'].kind_of?(Array)

        if @cartridge_vendor && @name
          @directory = "#{@cartridge_vendor.gsub(/\s+/, '')}-#{@name}"

          @repository_path = PathUtils.join(repository_base_path, @directory, @cartridge_version)
        end

        @endpoints = Endpoint.parse(@short_name, manifest)
      end

      ## obtain all software versions covered in this manifest
      def versions
        seed = (@manifest['Versions'] || []).map { |v| v.to_s }
        seed << @version
        seed.uniq
      end

      # Convenience method which returns an array containing only
      # those Endpoints which have a public_port_name specified.
      def public_endpoints
        @endpoints.select { |e| e.public_port_name }
      end

      def to_s
        instance_variables.each_with_object('<Cartridge: ') do |v, a|
          a << "#{v}: #{instance_variable_get(v)} "
        end << ' >'
      end
    end
  end
end

