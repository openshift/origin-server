class GearUsageRecord < UsageRecord

  attr_accessor :gear_uuid, :gear_size

  def initialize(gear_uuid=nil, gear_size=nil, event=nil, user=nil, time=nil, uuid=nil)
    super(event, user, time, uuid)
    self.gear_uuid = gear_uuid
    self.gear_size = gear_size
  end
  
  def delete_by_gear_uuid
    StickShift::DataStore.instance.delete_gear_usage_record_by_gear_uuid(user.login, gear_uuid)
  end

end
