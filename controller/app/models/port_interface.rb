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
  field :external_address, type: String, default: ""
  field :external_port, type: String, default: ""
  field :internal_address, type: String
  field :internal_port, type: String, default: ""
  field :port_type, type: String, default: "http"

  # Initializes the port interface
  def initialize(attrs = nil, options = nil)
    super(attrs, options)
  end

  def self.create_port_interface(gear, component_id, ep_name, pub_ip, public_port, internal_addr, internal_port)
    pi = gear.port_interfaces.find_by(external_port: public_port) rescue nil
    if pi
      Rails.logger.error("Duplicate entries for port interface - #{gear._id.to_s}") 
      # ignore the error for now.. just delete the old entry
      gear.port_interfaces.delete(pi)
    end

    comp = gear.app.component_instances.find_by(_id: component_id)
    port_type = (ep_name.downcase.include? "PROXY") ? "http" : "custom"
    PortInterface.new(cartridge_name: comp.cartridge_name, external_port: public_port.to_s, external_address: pub_ip, internal_port: internal_port.to_s, internal_address: internal_addr, port_type: port_type)
  end

  def self.remove_port_interface(gear, component_id, ep_name, pub_ip, public_port) 
    pi = gear.port_interfaces.find_by(external_port: public_port)
    gear.port_interfaces.delete(pi)
  end
end
