class NodeProperties
  attr_accessor :name, :node_consumed_capacity, :district_id, :district_available_capacity, :region_id, :zone_id

  def initialize(server_identity, capacity=nil, district=nil, server=nil)
    self.name = server_identity
    self.node_consumed_capacity = capacity

    if district
      self.district_id = district._id.to_s
      self.district_available_capacity = district.available_capacity
    end
    if server
      self.region_id = server.region_id
      self.zone_id = server.zone_id
    end
  end
end
