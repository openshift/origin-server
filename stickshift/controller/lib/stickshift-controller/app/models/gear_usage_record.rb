class GearUsageRecord < UsageRecord

  attr_accessor :gear_uuid, :gear_size

  def initialize(gear_uuid, gear_size, event, time=nil, uuid=nil)
    super(event, time, uuid)
    self.gear_uuid = gear_uuid
    self.gear_size = gear_size
  end

end
