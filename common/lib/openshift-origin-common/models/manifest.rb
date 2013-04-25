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

require 'openshift-origin-common/utils/path_utils'
require 'uri'
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

  module Runtime
    #
    # Manifest is a wrapper class for cartridge manifests.
    #
    # Wrapper speeds up access and provides fixed API
    class Manifest

      #
      # Class to support Manifest +Endpoint+ elements
      class Endpoint
        attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name,
                      :websocket_port_name, :websocket_port, :mappings

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
              endpoint                     = Endpoint.new
              endpoint.private_ip_name     = build_name(tag, entry['Private-IP-Name'])
              endpoint.private_port_name   = build_name(tag, entry['Private-Port-Name'])
              endpoint.private_port        = entry['Private-Port'].to_i
              endpoint.public_port_name    = build_name(tag, entry['Public-Port-Name'])
              endpoint.websocket_port_name = build_name(tag, entry['WebSocket-Port-Name'])
              endpoint.websocket_port = entry['WebSocket-Port'].to_i if entry['WebSocket-Port']

              if entry['Mappings'].respond_to?(:each)
                endpoint.mappings = entry['Mappings'].each_with_object([]) do |mapping_entry, mapping_memo|
                  mapping          = Endpoint::Mapping.new
                  mapping.frontend = mapping_entry['Frontend']
                  mapping.backend  = mapping_entry['Backend']
                  mapping.options  = mapping_entry['Options']

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
                  :categories,
                  :version,
                  :manifest_path,
                  :install_build_required,
                  :source_url,
                  :source_md5

      # :call-seq:
      #   Cartridge.new(manifest) -> Cartridge
      #   Cartridge.new(manifest, software_version) -> Cartridge
      #   Cartridge.new(manifest, software_version, repository_base_path) -> Cartridge
      #
      # Cartridge is a wrapper class for cartridge manifests
      #
      #   Cartridge.new('/var/lib/openshift/.cartridge_repository/php/1.0/metadata/manifest.yml', '3.5', '.../.cartridge_repository') -> Cartridge
      #   Cartridge.new('Name: ...', '3.5') -> Cartridge
      def initialize(manifest, version=nil, repository_base_path='')

        if File.exist? manifest
          @manifest      = YAML.load_file(manifest)
          @manifest_path = manifest
        else
          @manifest      = YAML.load(manifest)
          @manifest_path = :url
        end

        # Validate and use the provided version, defaulting to the manifest Version key
        raise MissingElementError.new(nil, 'Version') unless @manifest.has_key?('Version')
        raise InvalidElementError.new(nil, 'Versions') if @manifest.has_key?('Versions') && !@manifest['Versions'].kind_of?(Array)

        if version
          raise ArgumentError.new(
                    "Unsupported version #{version} from #{versions} for #{@manifest['Name']}"
                ) unless versions.include?(version.to_s)

          @version = version.to_s
        else
          @version = @manifest['Version'].to_s
        end

        # If version overrides are present, merge them on top of the manifest
        if @manifest.has_key?('Version-Overrides')
          vtree = @manifest['Version-Overrides'][@version]
          @manifest.merge!(vtree) if vtree
        end

        @cartridge_vendor       = @manifest['Cartridge-Vendor']
        @cartridge_version      = @manifest['Cartridge-Version'] && @manifest['Cartridge-Version'].to_s
        @name                   = @manifest['Name']
        @short_name             = @manifest['Cartridge-Short-Name']
        @categories             = @manifest['Categories'] || []
        @is_primary             = @categories.include?('web_framework')
        @is_web_proxy           = @categories.include?('web_proxy')
        @install_build_required = @manifest.has_key?('Install-Build-Required') ? @manifest['Install-Build-Required'] : true

        #FIXME: reinstate code after manifests are updated
        #raise MissingElementError.new(nil, 'Cartridge-Vendor') unless @cartridge_vendor
        #raise InvalidElementError.new(nil, 'Cartridge-Vendor') if @cartridge_vendor.include?('-')
        #raise MissingElementError.new(nil, 'Cartridge-Version') unless @cartridge_version
        raise MissingElementError.new(nil, 'Cartridge-Short-Name') unless @short_name
        raise InvalidElementError.new(nil, 'Cartridge-Short-Name') if @short_name.include?('-')
        raise MissingElementError.new(nil, 'Name') unless @name
        #raise InvalidElementError.new(nil, 'Name') if @name.include?('-')

        if @manifest.has_key?('Source-Url')
          raise InvalidElementError.new(nil, 'Source-Url') unless @manifest['Source-Url'] =~ URI::ABS_URI
          @source_url = @manifest['Source-Url']
          @source_md5 = @manifest['Source-Md5']
        else
          raise MissingElementError.new('Source-Url is required in manifest to obtain cartridge via URL',
                                        'Source-Url') if :url == @manifest_path
        end

        @short_name.upcase!

        if @cartridge_vendor && @name && @cartridge_version
          @directory           = @name.downcase
          repository_directory = "#{@cartridge_vendor.gsub(/\s+/, '').downcase}-#{@name}"
          @repository_path     = PathUtils.join(repository_base_path, repository_directory, @cartridge_version)
        end

        @endpoints = Endpoint.parse(@short_name, @manifest)
      end

      ## obtain all software versions covered in this manifest
      def versions
        seed = (@manifest['Versions'] || []).map { |v| v.to_s }
        seed << @manifest['Version'].to_s
        seed.uniq
      end

      # Convenience method which returns an array containing only
      # those Endpoints which have a public_port_name specified.
      def public_endpoints
        @endpoints.select { |e| e.public_port_name }
      end

      def primary?
        @is_primary
      end

      def web_proxy?
        @is_web_proxy
      end

      def self.build_ident(vendor, software, software_version, cartridge_version)
        vendor = vendor.gsub(/\s+/, '').downcase
        "#{vendor}:#{software}:#{software_version}:#{cartridge_version}"
      end

      def self.parse_ident(ident)
        cooked = ident.split(':')
        raise ArgumentError.new("'#{ident}' is not a legal cartridge identifier") if 4 != cooked.size
        cooked
      end

      def to_s
        instance_variables.each_with_object('<Cartridge: ') do |v, a|
          a << "#{v}: #{instance_variable_get(v)} "
        end << ' >'
      end
    end
  end
end
