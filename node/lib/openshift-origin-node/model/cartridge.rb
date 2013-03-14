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
        attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name, :mappings

        class Mapping
          attr_accessor :frontend, :backend, :options
        end

        # :call-seq:
        #   Endpoint.parse(short_name, manifest) -> [Endpoint]
        #
        # Parse +Endpoint+ element and instantiate Endpoint objects to hold information
        #
        #   Endpoint.parse('PHP', manifest)  #=> [Endpoint]
        def self.parse(short_name, manifest)
          return [] unless manifest['Endpoints']

          tag       = short_name.upcase
          errors    = []
          endpoints = manifest['Endpoints'].each_with_object([]) do |entry, memo|
            unless entry.is_a? Hash
              errors << "Non-Hash endpoint entry: #{entry}"
              next
            end

            # TODO: validation
            begin
              endpoint = Endpoint.new
              endpoint.private_ip_name = build_name(tag, entry['Private-IP-Name'])
              endpoint.private_port_name = build_name(tag, entry['Private-Port-Name'])
              endpoint.private_port = entry['Private-Port'].to_i
              endpoint.public_port_name = build_name(tag, entry['Public-Port-Name'])

              if entry['Mappings'].respond_to?(:each)
                endpoint.mappings = entry['Mappings'].each_with_object([]) do |mapping_entry, mapping_memo|
                  mapping = Endpoint::Mapping.new
                  mapping.frontend = mapping_entry['Frontend']
                  mapping.backend = mapping_entry['Backend']
                  mapping.options = mapping_entry['Options']

                  mapping_memo << mapping
                end
              else
                endpoint.mappings = []
              end
            
              memo << endpoint
            rescue Exception => e
              errors << "Couldn't parse endpoint entry '#{entry}': #{e.message}"
            end
          end

          raise "Couldn't parse endpoints: #{errors.join("\n")}" if errors.length > 0

          endpoints
        end

        def self.build_name(tag, name)
          name ? "OPENSHIFT_#{tag}_#{name}" : nil
        end
      end

      attr_reader :cartridge_vendor,
                  :cartridge_version,
                  :directory,
                  :endpoints,
                  :manifest,
                  :name,
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
        @short_name        = manifest['Cartridge-Short-Name']
        @version           = manifest['Version'] && manifest['Version'].to_s

        #FIXME: reinstate code after manifests are updated
        #raise MissingElementError.new(nil, 'Cartridge-Vendor') unless @cartridge_vendor
        #raise InvalidElementError.new(nil, 'Cartridge-Vendor') if @cartridge_vendor.include?('-')
        #raise MissingElementError.new(nil, 'Cartridge-Version') unless @cartridge_version
        raise MissingElementError.new(nil, 'Cartridge-Short-Name') unless @short_name
        raise InvalidElementError.new(nil, 'Cartridge-Short-Name') if @short_name.include?('-')
        raise MissingElementError.new(nil, 'Name') unless @name
        #raise InvalidElementError.new(nil, 'Name') if @name.include?('-')
        raise MissingElementError.new(nil, 'Version') unless @version
        raise InvalidElementError.new(nil, 'Versions') if @manifest['Versions'] && !@manifest['Versions'].kind_of?(Array)

        @short_name.upcase!

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

