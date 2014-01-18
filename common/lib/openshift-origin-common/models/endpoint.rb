module OpenShift
  class Endpoint < OpenShift::Model

    class Mapping < OpenShift::Model
      attr_accessor :frontend, :backend, :options

      def from_descriptor(spec_hash={})
        self.frontend = spec_hash['Frontend']
        self.backend  = spec_hash['Backend']
        self.options  = spec_hash['Options']
        self
      end

      def to_descriptor
        h = {}
        h['Frontend'] = self.frontend if self.frontend
        h['Backend']  = self.backend  if self.backend
        h['Options']  = self.options  if self.options
        h
      end

    end

    attr_accessor :private_ip_name, :private_port_name, :private_port, :public_port_name
    attr_accessor :websocket_port_name, :websocket_port, :mappings, :options
    attr_accessor :description

    def from_descriptor(spec_hash = {})
      self.private_ip_name     = spec_hash['Private-IP-Name']
      self.private_port_name   = spec_hash['Private-Port-Name']
      self.private_port        = spec_hash['Private-Port']
      self.public_port_name    = spec_hash['Public-Port-Name']
      self.websocket_port_name = spec_hash['WebSocket-Port-Name']
      self.websocket_port      = spec_hash['WebSocket-Port']
      self.options             = spec_hash['Options']
      self.description         = spec_hash['Description']

      self.mappings = []
      if (mappings = spec_hash['Mappings']).respond_to?(:each)
        mappings.each do |m|
          self.mappings << Endpoint::Mapping.new.from_descriptor(m)
        end
      end

      self
    end

    def to_descriptor
      h = {}
      h['Private-IP-Name']     = self.private_ip_name     if self.private_ip_name
      h['Private-Port-Name']   = self.private_port_name   if self.private_port_name
      h['Private-Port']        = self.private_port        if self.private_port
      h['Public-Port-Name']    = self.public_port_name    if self.public_port_name
      h['WebSocket-Port-Name'] = self.websocket_port_name if self.websocket_port_name
      h['WebSocket-Port']      = self.websocket_port      if self.websocket_port
      h['Options']             = self.options             if self.options
      h['Description']         = self.description         if self.description

      if self.mappings.length > 0
        h['Mappings'] = self.mappings.map { |m| m.to_descriptor }
      end

      h
    end

  end
end
