module OpenShift; end

module OpenShift::Runtime
	class Cartridge
		class Endpoint
			attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name
		end

		attr_reader :name, :namespace, :endpoints

    @@ENDPOINT_PATTERN = /([A-Z_0-9]+):([A-Z_0-9]+)\((\d+)\):?([A-Z_0-9]+)?/

		def initialize(manifest = {})
			@name = manifest["Name"]
			@namespace = manifest["Namespace"]
      endpoint_strings = manifest["Endpoints"] ||= []

      @endpoints = parse_endpoints(endpoint_strings)
		end

		# Convenience method which returns an array containing only
		# those Endpoints which have a public_port_name specified.
		def public_endpoints
			@endpoints.select {|e| e.public_port_name != nil}
		end

		def parse_endpoints(endpoint_strings=[])
			endpoints = []

			endpoint_strings.each do |entry|
        if m = @@ENDPOINT_PATTERN.match(entry)
          private_ip_name = m[1]
          private_port_name = m[2]
          private_port_number = m[3].to_i
          public_port_name = m[4]

          endpoint = Endpoint.new
          endpoint.private_ip_name = "OPENSHIFT_#{@namespace}_#{private_ip_name}"
          endpoint.private_port_name = "OPENSHIFT_#{@namespace}_#{private_port_name}"
          endpoint.private_port = private_port_number
          endpoint.public_port_name = public_port_name == nil ? nil : "OPENSHIFT_#{@namespace}_#{public_port_name}"

          endpoints << endpoint
        end
    	end

    	endpoints
    end
	end
end