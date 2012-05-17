class UsageRecord < StickShift::Model
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }

  attr_accessor :uuid, :user_id, :event, :time

  def initialize(event, time=nil, uuid=nil)
    self.uuid = uuid ? uuid : StickShift::Model.gen_uuid unless uuid
    self.event = event
    self.time = time ? time : Time.new
  end

end
