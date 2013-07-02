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
require 'rubygems/version'
require 'uri'
require 'safe_yaml'

SafeYAML::OPTIONS[:default_mode] = :unsafe

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

      def self.manifest_from_yaml(yaml_str)
        YAML.load(yaml_str, :safe => true)
      end

      #
      # Class to support Manifest +Endpoint+ elements
      class Endpoint
        attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name,
                      :websocket_port_name, :websocket_port, :mappings, :options

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
              endpoint.websocket_port      = entry['WebSocket-Port'].to_i if entry['WebSocket-Port']
              endpoint.options             = entry['Options']

              if entry['Mappings'].respond_to?(:each)
                endpoint.mappings = entry['Mappings'].each_with_object([]) do |mapping_entry, mapping_memo|
                  mapping          = Endpoint::Mapping.new
                  mapping.frontend = prepend_slash mapping_entry['Frontend']
                  mapping.backend  = prepend_slash mapping_entry['Backend']
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

        def self.prepend_slash(string)
          return string unless string
          return string if string.empty?
          string.start_with?('/') ? string : string.prepend('/')
        end

        def self.build_name(tag, name)
          name ? "OPENSHIFT_#{tag}_#{name}" : nil
        end
      end

      attr_reader :cartridge_vendor,
                  :cartridge_version,
                  :compatible_versions,
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

      # When a cartridge is installed from a URL, we validate the
      # vendor name by matching against VALID_VENDOR_NAME_PATTERN,
      # and the cartridge name agasint VALID_CARTRIDGE_NAME_PATTERN.
      # If it does not match the respective pattern, the cartridge will be rejected.
      VALID_VENDOR_NAME_PATTERN    = /\A[a-z0-9](?:[a-z0-9_]*[a-z0-9]|)\z/
      VALID_CARTRIDGE_NAME_PATTERN = /\A[a-z0-9](?:[-\.a-z0-9_]*[a-z0-9]|)\z/

      # Furthermore, we validate the vendor name by matching against
      # RESERVED_VENDOR_NAME_PATTERN.
      # If it matches the pattern, it will be rejected.
      ## TODO:
      # Add ability to configure reserved vendor names
      reserved_vendor_names = %w(
        redhat
      )

      reserved_cartridge_names = %w(
        app-root
        git
      )

      RESERVED_VENDOR_NAME_PATTERN    = Regexp.new("\\A(?:#{reserved_vendor_names.join('|')})\\z")
      RESERVED_CARTRIDGE_NAME_PATTERN = Regexp.new("\\A(?:#{reserved_cartridge_names.join('|')})\\z")

      ## TODO:
      # these should be configurable
      MAX_VENDOR_NAME    = 32
      MAX_CARTRIDGE_NAME = 32

      # :call-seq:
      #   Cartridge.new(manifest) -> Cartridge
      #   Cartridge.new(manifest, software_version) -> Cartridge
      #   Cartridge.new(manifest, software_version, repository_base_path) -> Cartridge
      #
      # Cartridge is a wrapper class for cartridge manifests
      #
      #   Cartridge.new('/var/lib/openshift/.cartridge_repository/php/1.0/metadata/manifest.yml', '3.5', '.../.cartridge_repository') -> Cartridge
      #   Cartridge.new('Name: ...', '3.5') -> Cartridge
      def initialize(manifest, version=nil, repository_base_path='', check_names=true)

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

        if @manifest.has_key?('Compatible-Versions') && !@manifest['Compatible-Versions'].kind_of?(Array)
          raise InvalidElementError.new(nil, 'Compatible-Versions')
        end

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
        @is_deployable          = @categories.include?('web_framework')
        @is_web_proxy           = @categories.include?('web_proxy')
        @install_build_required = @manifest.has_key?('Install-Build-Required') ? @manifest['Install-Build-Required'] : false

        @compatible_versions = (@manifest['Compatible-Versions'] || []).map { |v| v.to_s }

        #FIXME: reinstate code after manifests are updated
        #raise MissingElementError.new(nil, 'Cartridge-Vendor') unless @cartridge_vendor
        #raise MissingElementError.new(nil, 'Cartridge-Version') unless @cartridge_version
        raise MissingElementError.new(nil, 'Cartridge-Short-Name') unless @short_name
        raise InvalidElementError.new(nil, 'Cartridge-Short-Name') if @short_name.include?('-')
        raise MissingElementError.new(nil, 'Name') unless @name

        if check_names
          validate_vendor_name
          validate_cartridge_name
          check_reserved_cartridge_name
        end

        raise InvalidElementError.new("Version number #{@version} is invalid", 'Version') unless validate_version_number(@version)
        versions.each do |v|
          raise InvalidElementError.new("Version number #{v} is invalid", 'Versions') unless validate_version_number(v)
        end

        raise InvalidElementError.new("Cartridge-Version number #{@cartridge_version} is invalid", 'Version') unless validate_version_number(@cartridge_version)
        compatible_versions.each do |v|
          raise InvalidElementError.new("Compatible-Version number #{v} is invalid", 'Compatible-Versions') unless validate_version_number(v)
        end

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

      def deployable?
        @is_deployable
      end

      # For now, these are synonyms
      alias :buildable? :deployable?

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

      def validate_vendor_name(check_reserved_name = false)
        if cartridge_vendor !~ VALID_VENDOR_NAME_PATTERN
          raise InvalidElementError.new(
            "'#{cartridge_vendor}' does not match pattern #{VALID_VENDOR_NAME_PATTERN.inspect}.",
            'Cartridge-Vendor'
          )
        end

        if cartridge_vendor.length > MAX_VENDOR_NAME
          raise InvalidElementError.new(
            "'#{cartridge_vendor}' must be no longer than #{MAX_VENDOR_NAME} characters.",
            'Cartridge-Vendor'
          )
        end
      end

      def validate_cartridge_name
        if name !~ VALID_CARTRIDGE_NAME_PATTERN
          raise InvalidElementError.new(
            "'#{name}' does not match pattern #{VALID_CARTRIDGE_NAME_PATTERN.inspect}.",
            'Name'
          )
        end

        if name.length > MAX_CARTRIDGE_NAME
          raise InvalidElementError.new("'#{name}' must be no longer than #{MAX_VENDOR_NAME} characters.", 'Name')
        end
      end

      def check_reserved_vendor_name
        if cartridge_vendor =~ RESERVED_VENDOR_NAME_PATTERN
          raise InvalidElementError.new("'#{cartridge_vendor}' is reserved.", 'Cartridge-Vendor')
        end
      end

      def check_reserved_cartridge_name
        if name =~ RESERVED_CARTRIDGE_NAME_PATTERN
          raise InvalidElementError.new("'#{name}' is reserved.", 'Name')
        end
      end

      def validate_version_number(version)
        version =~ /^\A(\d+\.*)+\Z/
      end

      # Sort an array of "string" version numbers
      def self.sort_versions(array)
        copy = Marshal.load(Marshal.dump(array))
        copy.delete_if {|v| v == '_'}
        copy.collect {|v| Gem::Version.new(v)}.sort
      end

    end
  end
end
