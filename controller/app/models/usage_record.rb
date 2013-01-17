class UsageRecord
  include Mongoid::Document
  include Mongoid::Timestamps
  
  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }
             
  USAGE_TYPES = { :gear_usage => "GEAR_USAGE",
                  :addtl_fs_gb => "ADDTL_FS_GB" }

  field :login, type: String
  field :gear_id, type: Moped::BSON::ObjectId
  field :event, type: String
  field :time, type: Time
  field :sync_time, type: Time
  field :usage_type, type: String  
  field :gear_size, type: String  
  field :addtl_fs_gb, type: Integer

  validates_inclusion_of :event, in: UsageRecord::EVENTS.values
  validates_inclusion_of :usage_type, in: UsageRecord::USAGE_TYPES.values

  def self.track_usage(login, gear_id, event, usage_type,
                       gear_size=nil, addtl_fs_gb=nil)
    if Rails.configuration.usage_tracking[:datastore_enabled]
      now = Time.now.utc
      usage_record = UsageRecord.new(event: event, time: now, gear_id: gear_id,
                                     usage_type: usage_type, login: login)
      case usage_type
      when UsageRecord::USAGE_TYPES[:gear_usage]
        usage_record.gear_size = gear_size if gear_size
      when UsageRecord::USAGE_TYPES[:addtl_fs_gb]
        usage_record.addtl_fs_gb = addtl_fs_gb if addtl_fs_gb
      end
      usage_record.save!

      usage = nil
      if event == UsageRecord::EVENTS[:begin]
        usage = Usage.new(login: login, gear_id: gear_id,
                          begin_time: now, usage_type: usage_type)
        usage.gear_size = gear_size if gear_size
        usage.addtl_fs_gb = addtl_fs_gb if addtl_fs_gb
      elsif event == UsageRecord::EVENTS[:end]
        usage = Usage.find_latest_by_user_gear(login, gear_id, usage_type)
        if usage
          usage.end_time = now
        else
          Rails.logger.error "Can NOT find begin/continue usage record for login:#{login}, gear:#{gear_id}, usage_type:#{usage_type}. This can happen if gear was created with usage_tracking disabled and gear was destroyed with usage_tracking enabled or some bug in usage workflow."
        end
      end
      usage.save! if usage
    end

    if Rails.configuration.usage_tracking[:syslog_enabled]
      usage_string = "User: #{login}  Event: #{event}"
      case usage_type
      when UsageRecord::USAGE_TYPES[:gear_usage]
        usage_string += "   Gear: #{gear_id}   Gear Size: #{gear_size}"
      when UsageRecord::USAGE_TYPES[:addtl_fs_gb]
        usage_string += "   Gear: #{gear_id}   Addtl File System GB: #{addtl_fs_gb}"
      end
      begin
        Syslog.open('openshift_usage', Syslog::LOG_PID) { |s| s.notice usage_string }
      rescue Exception => e
        # Can't fail because of a secondary logging error
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
      end
    end
  end

  def self.untrack_usage(login, gear_id, event, usage_type)
    if Rails.configuration.usage_tracking[:datastore_enabled]
      usage_record = where(:login => login, :gear_id => gear_id, :event => event, :usage_type => usage_type).sort(:time.desc).first
      usage_record.delete if usage_record

      usage = Usage.find_latest_by_user_gear(login, gear_id, usage_type)
      if usage
        if event == UsageRecord::EVENTS[:begin]
          usage.delete
        elsif event == UsageRecord::EVENTS[:end]
          usage.end_time = nil
          usage.save!
        end
      end
    end

    if Rails.configuration.usage_tracking[:syslog_enabled]
      usage_string = "Rollback User: #{login} Event: #{event} Gear: #{gear_id} UsageType: #{usage_type}"
      begin
        Syslog.open('openshift_usage', Syslog::LOG_PID) { |s| s.notice usage_string }
      rescue Exception => e
        # Can't fail because of a secondary logging error
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
      end
    end
  end
end
