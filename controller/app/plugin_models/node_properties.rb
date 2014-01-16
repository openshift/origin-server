class NodeProperties
  attr_accessor :name, :node_consumed_capacity, :district_id, :district_available_capacity

  def initialize(server, capacity=nil, district=nil)
    self.name = server
    self.node_consumed_capacity = capacity

    if district
      self.district_id = district._id.to_s
      self.district_available_capacity = district.available_capacity
    end
  end
end
