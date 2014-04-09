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

  # FIXME, exceptions should be changed to be a subclass of a generic 
  #   InvalidManifestError

  # Manifest is invalid
  class InvalidManifest < KeyError; end

  # Manifest element in error
  class ElementError < KeyError
    attr_reader :element

    def initialize(message = nil, element = nil)
      super(message)
      @element = element
    end

    def to_s
      "#{@element} #{super}"
    end
  end

  # Missing required  manifest element
  class MissingElementError < ElementError
    def initialize(element, message = 'is a required element')
      super(message)
      @element = element
    end
  end

  # Invalid required  manifest element
  class InvalidElementError < ElementError
    def initialize(element, message = 'is not valid')
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
        YAML.safe_load(yaml_str) or {}
      rescue Psych::SyntaxError => e
        raise InvalidManifest, "Unable to load the provided manifest: #{e.message} (#{e.class})", e.backtrace
      end

      def self.manifests_from_yaml(str)
        projected_manifests(manifest_from_yaml(str))
      end

      #
      # Class to support Manifest +Endpoint+ elements
      class Endpoint
        attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name,
                      :websocket_port_name, :websocket_port, :mappings, :protocols, :options,
                      :description

        class Mapping
          attr_accessor :frontend, :backend, :options

          def from_json_hash(json_hash={})
            self.frontend = json_hash['frontend']
            self.backend  = json_hash['backend']
            self.options  = json_hash['options']
            self
          end
        end

        def from_json_hash(json_hash = {})
          self.private_ip_name     = json_hash['private_ip_name']
          self.private_port_name   = json_hash['private_port_name']
          self.private_port        = json_hash['private_port']
          self.public_port_name    = json_hash['public_port_name']
          self.websocket_port_name = json_hash['websocket_port_name']
          self.websocket_port      = json_hash['websocket_port']
          self.options             = json_hash['options']
          self.protocols           = json_hash['protocols']
          self.description         = json_hash['description']

          self.mappings = []
          if json_hash.has_key?('mappings') and json_hash['mappings'].respond_to?(:each)
            json_hash['mappings'].each do |m|
              self.mappings << Endpoint::Mapping.new.from_json_hash(m)
            end
          end

          self
        end

        # :call-seq:
        #   Endpoint.parse(short_name, manifest, categories) -> [Endpoint]
        #
        # Parse +Endpoint+ element and instantiate Endpoint objects to hold information
        #
        #   Endpoint.parse('PHP', manifest)  #=> [Endpoint]
        def self.parse(short_name, manifest, categories)
          return [] unless manifest['Endpoints']

          tag       = short_name.upcase
          errors    = []
          endpoint_index =0
          endpoints = manifest['Endpoints'].each_with_object([]) do |entry, memo|
            unless entry.is_a? Hash
              errors << "Non-Hash endpoint entry: #{entry}"
              next
            end
            endpoint_index += 1

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
              endpoint.description         = entry['Description']

              if entry['Protocols']
                endpoint.protocols = entry['Protocols']
              elsif entry['Mappings']
                endpoint.protocols = ['http']
              else
                endpoint.protocols = ['tcp']
              end

              if entry['Mappings'].respond_to?(:each)
                endpoint.mappings = entry['Mappings'].each_with_object([]) do |mapping_entry, mapping_memo|
                  mapping          = Endpoint::Mapping.new
                  if not (endpoint.protocols - [ 'http', 'https', 'ws', 'wss' ]).empty?
                    mapping.frontend = mapping_entry['Frontend']
                    mapping.backend  = mapping_entry['Backend']
                  else
                    mapping.frontend = prepend_slash mapping_entry['Frontend']
                    mapping.backend  = prepend_slash mapping_entry['Backend']
                  end
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
                  :versions,
                  :manifest_path,
                  :install_build_required,
                  :source_url,
                  :source_md5,
                  :metrics

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

      # these are the system categories and each cartridge much specify at least one of these
      SYSTEM_CATEGORIES = ['web_framework', 'plugin', 'service', 'embedded', 'web_proxy', 'ci_builder', 'external']

      # :call-seq:
      #   Cartridge.new(manifest) -> Cartridge
      #   Cartridge.new(manifest, software_version) -> Cartridge
      #   Cartridge.new(manifest, software_version, repository_base_path) -> Cartridge
      #
      # Cartridge is a wrapper class for cartridge manifests
      #
      #   Cartridge.new('/var/lib/openshift/.cartridge_repository/php/1.0/metadata/manifest.yml', '3.5', '.../.cartridge_repository') -> Cartridge
      #   Cartridge.new('Name: ...', '3.5') -> Cartridge
      def initialize(manifest, version=nil, type=:url, repository_base_path='', check_names=true)
        if manifest.is_a?(Hash)
          @manifest = manifest
        elsif type == :url
          @manifest = YAML.safe_load(manifest) || {}
          @manifest_path = :url
        else
          @manifest = YAML.safe_load_file(manifest) || {}
          @manifest_path = manifest
        end
        @repository_base_path = repository_base_path

        # Validate and use the provided version, defaulting to the manifest Version key
        raise MissingElementError.new('Version') unless @manifest.has_key?('Version')
        raise InvalidElementError.new('Versions') if @manifest.has_key?('Versions') && !@manifest['Versions'].kind_of?(Array)

        if @manifest.has_key?('Compatible-Versions') && !@manifest['Compatible-Versions'].kind_of?(Array)
          raise InvalidElementError.new('Compatible-Versions')
        end

        @versions = self.class.raw_versions(@manifest).collect do |v|
          valid_version_number(v) ? v : '0.0.0'
        end

        @cartridge_version =  @manifest['Cartridge-Version'].to_s
        unless valid_version_number(@cartridge_version)
          @cartridge_version = '0.0.0'
        end

        @compatible_versions = (@manifest['Compatible-Versions'] || []).collect do |v|
          valid_version_number(v.to_s) ? v.to_s : '0.0.0'
        end

        if version
          raise ArgumentError.new(
                    "Unsupported version #{version} from #{versions} for #{@manifest['Name']}"
                ) unless versions.include?(version.to_s)

          @version = version.to_s
        else
          @version = @manifest['Version'].to_s
        end

        unless valid_version_number(@version)
          @version = '0.0.0'
        end

        # If version overrides are present, merge them on top of the manifest
        if @manifest.has_key?('Version-Overrides')
          vtree = @manifest['Version-Overrides'][@version]

          if vtree
            copy_manifest_if_equal(manifest)
            @manifest.merge!(vtree)
          end
        end

        # Ensure that the manifest version is accurate
        if @manifest['Version'] != @version
          copy_manifest_if_equal(manifest)
          @manifest['Version'] = @version
        end

        # validate the scaling limits specified
        if @manifest['Scaling'].kind_of?(Hash)
          min = (@manifest['Scaling']['Min'] || 1).to_i
          max = (@manifest['Scaling']['Max'] || -1).to_i
          if (@manifest['Categories'] || []).include?('external') and (min != 0 || max != 0)
            raise InvalidElementError.new("Scaling", "should either not be specified or have 0 for 'Min' and 'Max' in case of an 'external' cartridge.")
          elsif !(@manifest['Categories'] || []).include?('external') and (min == 0 || max == 0)
            raise InvalidElementError.new("Scaling", "'Min' and 'Max' cannot be 0 unless its an 'external' cartridge.")
          end
        end

        @cartridge_vendor       = @manifest['Cartridge-Vendor']
        @name                   = @manifest['Name']
        @short_name             = @manifest['Cartridge-Short-Name']
        @categories             = @manifest['Categories'] || []
        @is_deployable          = @categories.include?('web_framework')
        @is_web_proxy           = @categories.include?('web_proxy')
        @install_build_required = @manifest.has_key?('Install-Build-Required') ? @manifest['Install-Build-Required'] : false


        #FIXME: reinstate code after manifests are updated
        #raise MissingElementError.new(nil, 'Cartridge-Vendor') unless @cartridge_vendor
        #raise MissingElementError.new(nil, 'Cartridge-Version') unless @cartridge_version
        raise MissingElementError.new('Cartridge-Short-Name') unless @short_name
        raise InvalidElementError.new('Cartridge-Short-Name') if @short_name.include?('-')
        raise MissingElementError.new('Name') unless @name

        if check_names
          validate_vendor_name
          validate_cartridge_name
          check_reserved_cartridge_name
        end

        if @manifest.has_key?('Source-Url')
          raise InvalidElementError.new('Source-Url') unless @manifest['Source-Url'] =~ URI::ABS_URI
          @source_url = @manifest['Source-Url']
          @source_md5 = @manifest['Source-Md5']
        elsif :url == @manifest_path and !(@manifest['Categories'] || []).include?('external')
          raise MissingElementError.new('Source-Url', 'is required in manifest to obtain cartridge via URL')
        end

        @short_name.upcase!

        if @cartridge_vendor && @name && @cartridge_version
          @directory           = @name.downcase
          repository_directory = "#{@cartridge_vendor.gsub(/\s+/, '').downcase}-#{@name}"
          @repository_path     = PathUtils.join(repository_base_path, repository_directory, @cartridge_version)
        end

        @endpoints = Endpoint.parse(@short_name, @manifest, @categories)

        @metrics = @manifest['Metrics']
      end

      ## obtain all software versions covered in this manifest
      def self.raw_versions(manifest)
        return [] if manifest.nil?
        ((manifest['Versions'] || []).map(&:to_s) << manifest['Version'].to_s).uniq
      end

      # Convenience method which returns an array containing only
      # those Endpoints which have a public_port_name specified.
      def public_endpoints
        @endpoints.select { |e| e.public_port_name }
      end

      def deployable?
        @is_deployable
      end

      alias_method :web_framework?, :deployable?

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
            'Cartridge-Vendor',
            "'#{cartridge_vendor}' does not match pattern #{VALID_VENDOR_NAME_PATTERN.inspect}."
          )
        end

        if cartridge_vendor.length > MAX_VENDOR_NAME
          raise InvalidElementError.new(
            'Cartridge-Vendor',
            "'#{cartridge_vendor}' must be no longer than #{MAX_VENDOR_NAME} characters."
          )
        end
      end

      def validate_cartridge_name
        if name !~ VALID_CARTRIDGE_NAME_PATTERN
          raise InvalidElementError.new(
            'Name',
            "'#{name}' does not match pattern #{VALID_CARTRIDGE_NAME_PATTERN.inspect}."
          )
        end

        if name.length > MAX_CARTRIDGE_NAME
          raise InvalidElementError.new('Name', "'#{name}' must be no longer than #{MAX_VENDOR_NAME} characters.")
        end
      end

      def self.valid_cartridge_name?(name)
        name =~ VALID_CARTRIDGE_NAME_PATTERN
      end

      def check_reserved_vendor_name
        if cartridge_vendor =~ RESERVED_VENDOR_NAME_PATTERN
          raise InvalidElementError.new('Cartridge-Vendor', "'#{cartridge_vendor}' is reserved.")
        end
      end

      def check_reserved_cartridge_name
        raise MissingElementError.new('Name') if name.nil? || name.empty?
        if name =~ RESERVED_CARTRIDGE_NAME_PATTERN
          raise InvalidElementError.new('Name', "'#{name}' is reserved.")
        end
      end

      def valid_version_number(version)
        version =~ /^\A(\d+\.*)+\Z/
      end

      def project_version_overrides(version, repository_base_path)
        self.class.new(manifest_path, version, :file, repository_base_path)
      end

      def validate_categories
        # Validate the categories specified
        raise MissingElementError.new('Categories') unless @manifest.has_key?('Categories')
        raise InvalidElementError.new('Categories') unless @manifest['Categories'].kind_of?(Array)
        unless @manifest['Categories'].any?{|c| SYSTEM_CATEGORIES.include? c}
          raise InvalidElementError.new("Categories", "should contain at least one of '#{SYSTEM_CATEGORIES.inspect}'.")
        end
        if @manifest['Categories'].include? 'web_framework' and @manifest['Categories'].include? 'external'
          raise InvalidElementError.new("Categories", "'web_framework' and 'external' cannot be specified for the same cartridge.")
        end
      end

      #
      # More efficient version extraction.  If returning all the versions of a
      # cartridge, the "default" version will be in the head position (index 0).
      #
      def self.projected_manifests(raw_manifest, version=nil, repository_base_path='')
        if version
          return new(Marshal.load(Marshal.dump(raw_manifest)), version, nil, repository_base_path)
        end

        preferred_version = raw_manifest['Version'].to_s if raw_manifest
        raw_versions(raw_manifest).map do |v|
          new(raw_manifest, v, nil, repository_base_path)
        end.sort_by{ |m| preferred_version == m.version ? 0 : 1 }
      end

      #
      # Name-Version or Vendor-Name-Version
      #
      def full_identifier
        if cartridge_vendor.nil? || cartridge_vendor.empty?
          "#{name}-#{version}"
        else
          "#{cartridge_vendor}-#{name}-#{version}"
        end
      end

      #
      # Name-Version or Vendor-Name-Version
      #
      def global_identifier
        if cartridge_vendor.nil? || cartridge_vendor.empty? or cartridge_vendor == "redhat"
          "#{name}-#{version}"
        else
          "#{cartridge_vendor}-#{name}-#{version}"
        end
      end

      # Sort an array of "string" version numbers
      def self.sort_versions(array)
        results = []

        copy = Marshal.load(Marshal.dump(array))
        copy.delete_if {|v| v == '_'}
        copy.collect {|v| Gem::Version.new(v)}.sort.each do |version|
          results << version.to_s
        end

        results
      end
      protected
        attr_writer :manifest_path
        attr_reader :repository_base_path

        def copy_manifest_if_equal(to)
          if @manifest.equal?(to)
            @manifest = Marshal.load(Marshal.dump(@manifest)) 
          end
        end
    end
  end
end
