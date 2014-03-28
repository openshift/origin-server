class GearProperties
  attr_accessor :id, :name, :server, :district, :cartridges, :region, :zone

  def initialize(gear)
    self.id = gear.uuid
    self.name = gear.name
    self.server = gear.server_identity
    self.cartridges = gear.component_instances.map {|ci| ci.cartridge_name}

    if Rails.configuration.msg_broker[:districts][:enabled]
      begin
        d = District.find_by({"servers.name" => gear.server_identity})
        self.district = d.name
        if Rails.configuration.msg_broker[:regions][:enabled]
          server = d.servers.find_by(name: gear.server_identity)
          if server.region_id
            self.region = server.region_name
            self.zone = server.zone_name
          end
        end
      rescue Mongoid::Errors::DocumentNotFound
        Rails.logger.error "District not found for gear #{gear.uuid} with server_identity #{gear.server_identity}"
      end
    end
  end
end
