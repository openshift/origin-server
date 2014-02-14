# Record Usage of gear and additional storage for each user
# @!attribute [r] user_id
#   @return [String] User ID.
# @!attribute [r] app_name
#   @return [String] Application name that belongs to the user.
# @!attribute [r] gear_id
#   @return [String] Gear identifier
# @!attribute [r] usage_type
#   @return [String] Represents type of usage, either gear or additional storage
# @!attribute [r] event
#   @return [String] Denotes begin/continue/end of given usage_type
# @!attribute [r] sync_time
#   @return [Time] When is the last time it synced this Usage record with billing vendor
# @!attribute [rw] gear_size
#   @return [String] Gear size
# @!attribute [rw] addtl_fs_gb
#   @return [Integer] Additional filesystem storage in GB.
# @!attribute [rw] cart_name
#   @return [String] Premium cartridge name
class UsageRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  EVENTS = { :begin => "begin",
             :end => "end",
             :continue => "continue" }

  USAGE_TYPES = { :gear_usage => "GEAR_USAGE",
                  :addtl_fs_gb => "ADDTL_FS_GB",
                  :premium_cart => "PREMIUM_CART" }

  field :user_id, type: Moped::BSON::ObjectId
  field :app_name, type: String
  field :gear_id, type: Moped::BSON::ObjectId
  field :event, type: String
  field :time, type: Time
  field :sync_time, type: Time
  field :usage_type, type: String
  field :gear_size, type: String
  field :addtl_fs_gb, type: Integer
  field :cart_name, type: String

  validates :user_id, :presence => true
  validates :app_name, :presence => true
  validates :gear_id, :presence => true
  validates :time, :presence => true
  validates_inclusion_of :event, in: UsageRecord::EVENTS.values
  validates_inclusion_of :usage_type, in: UsageRecord::USAGE_TYPES.values
  validates :gear_size, :presence => true, :if => :validate_gear_size?
  validates :addtl_fs_gb, :presence => true, :if => :validate_addtl_fs_gb?
  validates :cart_name, :presence => true, :if => :validate_cart_name?

  index({'gear_id' => 1, 'usage_type' => 1, 'created_at' => 1})
  create_indexes

  def validate_gear_size?
    (self.usage_type == UsageRecord::USAGE_TYPES[:gear_usage] && self.event != UsageRecord::EVENTS[:end]) ? true : false
  end

  def validate_addtl_fs_gb?
    (self.usage_type == UsageRecord::USAGE_TYPES[:addtl_fs_gb]) ? true : false
  end

  def validate_cart_name?
    (self.usage_type == UsageRecord::USAGE_TYPES[:premium_cart]) ? true : false
  end

  def self.find_latest_by_user_gear(user_id, gear_id, usage_type)
    where(:user_id => user_id, :gear_id => gear_id, :usage_type => usage_type).desc(:time).first
  end

  def self.find_latest_by_gear(gear_id, usage_type)
    where(:gear_id => gear_id, :usage_type => usage_type).desc(:time).first
  end

  def self.track_usage(user_id, app_name, gear_id, event, usage_type,
                       gear_size=nil, addtl_fs_gb=nil, cart_name=nil, time=nil)
    UsageRecord.log_usage(user_id, gear_id, event, usage_type, gear_size, addtl_fs_gb, cart_name)

    if Rails.configuration.usage_tracking[:datastore_enabled]
      time = Time.now.utc unless time
      if event == UsageRecord::EVENTS[:begin]
        usage = Usage.new(user_id: user_id, app_name: app_name, gear_id: gear_id,
                          begin_time: time, created_at: time, usage_type: usage_type)
        usage.gear_size = gear_size if gear_size
        usage.addtl_fs_gb = addtl_fs_gb if addtl_fs_gb
        usage.cart_name = cart_name if cart_name
        usage.save!
      elsif event == UsageRecord::EVENTS[:end]
        usage = Usage.find_latest_by_user_gear(user_id, gear_id, usage_type)
        if usage
          usage.end_time = time
          usage.save!
          old_usage_rec = UsageRecord.find_latest_by_user_gear(user_id, gear_id, usage_type)
          # If we don't find begin/continue usage records for the 'end' event
          # then recreate the usage_record using usage.
          if !old_usage_rec or (old_usage_rec.event == UsageRecord::EVENTS[:end])
            old_usage_rec.delete if old_usage_rec
            usage_record = UsageRecord.new(event: UsageRecord::EVENTS[:begin], time: usage.begin_time,
                                           usage_type: usage_type, user_id: user_id, gear_id: gear_id,
                                           app_name: app_name, created_at: usage.created_at)
            usage_record.gear_size = usage.gear_size if usage.gear_size
            usage_record.addtl_fs_gb = usage.addtl_fs_gb if usage.addtl_fs_gb
            usage_record.cart_name = usage.cart_name if usage.cart_name
            usage_record.save!
          end
        else
          Rails.logger.error "Can NOT find begin/continue usage_record for user_id:#{user_id}, gear:#{gear_id}, usage_type:#{usage_type}. This can happen if gear was created with usage_tracking disabled and gear was deleted with usage_tracking enabled or some bug in usage workflow."
          return
        end
      end

      # Keep created time in sync for UsageRecord and Usage mongo record.
      usage_record = UsageRecord.new(event: event, time: time, created_at: time, gear_id: gear_id,
                                     usage_type: usage_type, user_id: user_id, app_name: app_name)
      case usage_type
      when UsageRecord::USAGE_TYPES[:gear_usage]
        usage_record.gear_size = gear_size
      when UsageRecord::USAGE_TYPES[:addtl_fs_gb]
        usage_record.addtl_fs_gb = addtl_fs_gb
      when UsageRecord::USAGE_TYPES[:premium_cart]
        usage_record.cart_name = cart_name
      end
      usage_record.save!
    end
  end

  def self.untrack_usage(user_id, gear_id, event, usage_type)
    UsageRecord.log_usage(user_id, gear_id, event, usage_type, nil, nil, nil, true)

    if Rails.configuration.usage_tracking[:datastore_enabled]
      usage_record = where(:user_id => user_id, :gear_id => gear_id, :event => event, :usage_type => usage_type).desc(:time).first
      usage_record.delete if usage_record

      usage = Usage.find_latest_by_user_gear(user_id, gear_id, usage_type)
      if usage
        if event == UsageRecord::EVENTS[:begin]
          usage.delete
        elsif event == UsageRecord::EVENTS[:end]
          usage.end_time = nil
          usage.save!
        end
      end
    end
  end

  def self.log_usage(user_id, gear_id, event, usage_type,
                     gear_size=nil, addtl_fs_gb=nil, cart_name=nil, rollback=false)
    if OpenShift::UsageAuditLog.is_enabled?
      usage_string = ""
      usage_string += "Rollback " if rollback
      usage_string += "User ID: #{user_id} Event: #{event} Gear: #{gear_id} UsageType: #{usage_type}"
      case usage_type
      when UsageRecord::USAGE_TYPES[:gear_usage]
        usage_string += " GearSize: #{gear_size}" if gear_size
      when UsageRecord::USAGE_TYPES[:addtl_fs_gb]
        usage_string += " AddtlStorageGB: #{addtl_fs_gb}" if addtl_fs_gb
      when UsageRecord::USAGE_TYPES[:premium_cart]
        usage_string += " Catridge: #{cart_name}" if cart_name
      end
      begin
        OpenShift::UsageAuditLog.log(usage_string)
      rescue Exception => e
        # Can't fail because of a secondary logging error
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
      end
    end
  end
end
