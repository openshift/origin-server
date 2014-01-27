class TrackUsageOp < PendingAppOp

  field :user_id, type: Moped::BSON::ObjectId
  field :parent_user_id, type: Moped::BSON::ObjectId
  field :app_name, type: String
  field :gear_id, type: String
  field :event, type: String
  field :usage_type, type: String
  field :additional_filesystem_gb, type: Integer
  field :gear_size, type: String
  field :cart_name, type: String

  def initialize(*args)
    super
    raise "Invalid arguments" if usage_type == UsageRecord::USAGE_TYPES[:addtl_fs_gb] && additional_filesystem_gb.nil?
  end

  def execute
    unless parent_user_id
      storage_usage_type = ( usage_type == UsageRecord::USAGE_TYPES[:addtl_fs_gb] )
      tracked_storage = nil
      if storage_usage_type
        max_untracked_storage = application.domain.owner.max_untracked_additional_storage
        tracked_storage = additional_filesystem_gb - max_untracked_storage
      end
      if !storage_usage_type or (tracked_storage > 0)
        UsageRecord.track_usage(user_id, app_name, gear_id, event, usage_type, gear_size, 
                                tracked_storage, cart_name)
      end
    end
  end

  def rollback
    unless parent_user_id
      storage_usage_type = (usage_type == UsageRecord::USAGE_TYPES[:addtl_fs_gb])
      tracked_storage = nil
      if storage_usage_type
        max_untracked_storage = application.domain.owner.max_untracked_additional_storage
        tracked_storage = additional_filesystem_gb - max_untracked_storage
      end
      if !storage_usage_type or (tracked_storage > 0)
        UsageRecord.untrack_usage(user_id, gear_id, event, usage_type)
      end
    end
  end

end
