class UsageRecord
  include Mongoid::Document
  include Mongoid::Timestamps  
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }
             
  USAGE_TYPES = { :gear_usage => "GEAR_USAGE",
                  :addtl_fs_gb => "ADDTL_FS_GB" }

  field :event, type: String
  field :sync_time, type: DateTime
  embedded_in :application
  field :usage_type, type: String  
  field :gear_uuid, type: Moped::BSON::ObjectId
  field :gear_size, type: String  
  field  :addtl_fs_gb, type: Integer
  
  def delete_by_gear_uuid
    UsageRecord.where(user: user, gear_uuid: gear_uuid, usage_type: usage_type).delete
  end
end