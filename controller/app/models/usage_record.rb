# Class to record usage of gears and filesystem usage for accounting purposes.
# @!attribute [rw] usage_type 
#   @return [String] Indicates the record type. One of UsageRecord.USAGE_TYPES
# @!attribute [rw] event
#   @return [String] Indicates the record event type. One of UsageRecord.EVENTS
# @!attribute [rw] sync_time
#   @return [Time] Time when record was last recorded in accounting backend.
# @!attribute [rw] gear_uuid
#   @return [Moped::BSON::ObjectId] The GUID of the gear this event took place on.
# @!attribute [rw] gear_size
#   @return [String] The size of the gear.
# @!attribute [rw] addtl_fs_gb
#   @return [Integer] The amount of additional storage (in GB) allocated on the gear
class UsageRecord
  include Mongoid::Document
  include Mongoid::Timestamps  
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }
             
  USAGE_TYPES = { :gear_usage => "GEAR_USAGE",
                  :addtl_fs_gb => "ADDTL_FS_GB" }

  field :event, type: String
  field :sync_time, type: Time
  embedded_in :application
  field :usage_type, type: String  
  field :gear_uuid, type: Moped::BSON::ObjectId
  field :gear_size, type: String  
  field  :addtl_fs_gb, type: Integer
  
  # Deletes all usage records of the specified type for a particular gear.
  #
  # == Parameters:
  # gear_uuid::
  #   The GUID of the gear
  #
  # usage_type::
  #   The record type to delete. One of UsageRecord.USAGE_TYPES
  def delete_by_gear_uuid(gear_uuid, usage_type)
    UsageRecord.where(gear_uuid: gear_uuid, usage_type: usage_type).delete
  end
end
