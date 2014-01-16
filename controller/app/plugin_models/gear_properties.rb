class GearProperties
  attr_accessor :id, :name, :server, :district, :cartridges

  def initialize(gear)
    self.id = gear.uuid
    self.name = gear.name
    self.server = gear.server_identity
    self.cartridges = gear.component_instances.map {|ci| ci.cartridge_name}
    
    if Rails.configuration.msg_broker[:districts][:enabled]
      begin
        d = District.find_by({"server_identities.name" => gear.server_identity})
        self.district = d.name
      rescue Mongoid::Errors::DocumentNotFound
        Rails.logger.error "District not found for gear #{gear.uuid} with server_identity #{gear.server_identity}"
      end
    end
  end
end
