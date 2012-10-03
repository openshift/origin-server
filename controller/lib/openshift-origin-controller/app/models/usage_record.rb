class UsageRecord < OpenShift::UserModel
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }
             
  USAGE_TYPES = { :gear_usage => "GEAR_USAGE",
                  :addtl_fs_gb => "ADDTL_FS_GB" }

  attr_accessor :uuid, :event, :time, :sync_time, :user, :usage_type, :gear_uuid, :gear_size, :addtl_fs_gb
  primary_key :uuid
  exclude_attributes :user

  def initialize(event=nil, user=nil, time=nil, uuid=nil, usage_type=nil)
    self.uuid = uuid ? uuid : OpenShift::Model.gen_uuid
    self.event = event
    self.time = time ? time : Time.now.utc
    self.user = user
    self.usage_type = usage_type
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
  
  def delete_by_gear_uuid
    OpenShift::DataStore.instance.delete_usage_record_by_gear_uuid(user.login, gear_uuid, usage_type)
  end

end
