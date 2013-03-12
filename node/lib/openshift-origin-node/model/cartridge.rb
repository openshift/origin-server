module OpenShift; end

module OpenShift::Runtime
	class Cartridge
		class Endpoint
      @@ENDPOINT_PATTERN = /([A-Za-z_0-9]+):([A-Za-z_0-9]+)\((\d+)\):?([A-Za-z_0-9]+)?/

			attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name

      def self.parse_endpoints(namespace, endpoint_strings=[])
        raise "Namespace is required to parse endpoints" if namespace == nil

        endpoints = []
        errors = []

        endpoint_strings.each do |entry|
          unless entry.is_a? String
            errors << "Non-String endpoint entry: #{entry}"
            next
          end

          @@ENDPOINT_PATTERN.match(entry) do |m|
            begin
              private_ip_name = m[1]
              private_port_name = m[2]
              private_port_number = m[3].to_i
              public_port_name = m[4]

              endpoint = Endpoint.new
              endpoint.private_ip_name = "OPENSHIFT_#{namespace}_#{private_ip_name.upcase}"
              endpoint.private_port_name = "OPENSHIFT_#{namespace}_#{private_port_name.upcase}"
              endpoint.private_port = private_port_number
              endpoint.public_port_name = public_port_name == nil ? nil : "OPENSHIFT_#{namespace}_#{public_port_name.upcase}"

              endpoints << endpoint
            rescue => e
              errors << "Couldn't parse endpoint entry '#{entry}': #{e.message}"
            end
          end
        end

        raise "Couldn't parse endpoints: #{errors}" if errors.length > 0

        endpoints
      end
		end

		attr_reader :name, :namespace, :endpoints, :short_name, :vendor, :version

		def initialize(manifest = {})
			@name = manifest["Name"]
      # FIXME: remove after element is renamed to CartridgeShortName
			@namespace = manifest["Namespace"]
			@short_name = manifest["CartridgeShortName"] ||= manifest["Namespace"]

      @namespace.upcase!
      @short_name.upcase!

      @vendor = manifest['CartridgeVendor'] ||= "not_provided"
      @version = manifest['CartridgeVersion']

      endpoint_strings = manifest["Endpoints"] ||= []
      @endpoints = Endpoint.parse_endpoints(@namespace, endpoint_strings)
		end

		# Convenience method which returns an array containing only
		# those Endpoints which have a public_port_name specified.
		def public_endpoints
			@endpoints.select {|e| e.public_port_name != nil}
		end
	end
end
