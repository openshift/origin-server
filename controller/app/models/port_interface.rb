# Represents a gear's exposed port interface
# as created on an OpenShift Origin Node.
# @!attribute [r] Gear
#   @return [Gear] The {Gear} that this interface is part of.
# @!attribute [r] external_port
#   @return [Integer] Exposed external port on the node
# @!attribute [r] internal_port
#   @return [Integer] The internal port that the exposed one points to
# @!attribute [r] cartridge_name
#   @return [String] The cartridge that created this interface
# @!attribute [r] port_type
#   @return [String] The type of port indicated by a string (e.g. http)
class PortInterface
  include Mongoid::Document
  embedded_in :gear, class_name: Gear.name
  field :cartridge_name, type: String, default: ""
  field :external_port, type: String, default: ""
  field :internal_address, type: String
  field :internal_port, type: String, default: ""
  field :protocols, type: Array, default: []
  field :type, type: Array, default: []
  attr :external_address

  # Initializes the port interface
  def initialize(attrs = nil, options = nil)
    super(attrs, options)
  end

  def self.create_port_interface(gear, component_id, endpoint_hash)
    # ep_name, pub_ip, public_port, internal_addr, internal_port)
    public_ip = endpoint_hash["external_address"]
    public_port = endpoint_hash["external_port"]
    internal_ip = endpoint_hash["internal_address"]
    internal_port = endpoint_hash["internal_port"]
    protocols = endpoint_hash["protocols"]
    types = endpoint_hash["type"]

    pi = gear.port_interfaces.find_by(external_port: public_port) rescue nil
    if pi
      Rails.logger.error("Duplicate entries for port interface - #{gear._id.to_s}") 
      # ignore the error for now.. just delete the old entry
      gear.port_interfaces.delete(pi)
    end

    comp = gear.app.component_instances.find_by(_id: component_id)
    PortInterface.new(cartridge_name: comp.cartridge_name, external_port: public_port.to_s, internal_port: internal_port.to_s, internal_address: internal_ip, protocols: protocols, type: types)
  end

  def self.remove_port_interface(gear, component_id, pub_ip, public_port) 
    pi = gear.port_interfaces.find_by(external_port: public_port)
    gear.port_interfaces.delete(pi)
  end

  def publish_endpoint(app)
    OpenShift::RoutingService.notify_create_public_endpoint(app, self.cartridge_name, self.external_address, self.external_port, self.internal_address, self.internal_port, self.protocols, self.type)
  end

  def external_address
    @external_address = self.gear.get_public_ip_address if @external_address.nil?
    @external_address
  end

  def to_hash
    { 
      "external_address" => self.external_address,
      "external_port" => self.external_port,
      "internal_address" => self.internal_address,
      "internal_port" => self.internal_port,
      "protocols" => self.protocols,
      "types" => self.type
    }
  end
end
