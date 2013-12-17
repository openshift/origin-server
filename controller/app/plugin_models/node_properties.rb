class NodeProperties
  attr_accessor :name, :node_consumed_capacity, :district_id, :district_available_capacity, :region_id, :zone_id

  def initialize(server, capacity=nil, district=nil, region_id=nil, zone_id=nil)
    self.name = server
    self.node_consumed_capacity = capacity

    if district
      self.district_id = district._id.to_s
      self.district_available_capacity = district.available_capacity
      self.region_id = region_id if region_id
      self.zone_id = zone_id if zone_id
    end
  end
end
