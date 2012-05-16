class GearUsageRecord < UsageRecord

  attr_accessor :gear_uuid, :gear_type

  def initialize(gear_uuid, gear_type, event, time=nil, uuid=nil)
    super(event, time, uuid)
    self.gear_uuid = gear_uuid
    self.gear_type = gear_type
  end

end
