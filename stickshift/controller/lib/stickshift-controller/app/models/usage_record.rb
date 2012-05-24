class UsageRecord < StickShift::UserModel
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }

  attr_accessor :uuid, :user_id, :event, :time, :sync_time, :user
  primary_key :uuid
  exclude_attributes :user

  def initialize(event=nil, user=nil, time=nil, uuid=nil)
    self.uuid = uuid ? uuid : StickShift::Model.gen_uuid
    self.event = event
    self.time = time ? time : Time.new
    self.user = user
    self.sync_time = nil
  end

  # Deletes the usage record from the datastore
  def delete
    super(user.login)
  end

  # Saves the usage record to the datastore
  def save
    super(user.login)
  end

end
