# Usage Summary 
# @!attribute [r] user_id
#   @return [String] User ID
# @!attribute [r] app_name
#   @return [String] Application name that belongs to the user.
# @!attribute [r] gear_id
#   @return [String] Gear identifier
# @!attribute [r] usage_type
#   @return [String] Represents type of usage, either gear or additional storage
# @!attribute [r] begin_time
#   @return [Time] Denotes start time of given usage_type
# @!attribute [r] end_time
#   @return [Time] Denotes stop time of given usage_type
# @!attribute [rw] gear_size
#   @return [String] Gear size
# @!attribute [rw] addtl_fs_gb
#   @return [Integer] Additional filesystem storage in GB.
# @!attribute [rw] cart_name
#   @return [String] Premium cartridge name
class Usage
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "usage"

  field :user_id, type: Moped::BSON::ObjectId
  field :app_name, type: String
  field :gear_id, type: Moped::BSON::ObjectId
  field :begin_time, type: Time
  field :end_time, type: Time
  field :usage_type, type: String
  field :gear_size, type: String
  field :addtl_fs_gb, type: Integer
  field :cart_name, type: String

  validates :user_id, :presence => true
  validates :app_name, :presence => true
  validates :gear_id, :presence => true
  validates :begin_time, :presence => true
  validates_inclusion_of :usage_type, in: UsageRecord::USAGE_TYPES.values
  validates :gear_size, :presence => true, :if => :validate_gear_size?
  validates :addtl_fs_gb, :presence => true, :if => :validate_addtl_fs_gb?
  validates :cart_name, :presence => true, :if => :validate_cart_name?

  index({'gear_id' => 1})
  create_indexes

  def validate_gear_size?
    (self.usage_type == UsageRecord::USAGE_TYPES[:gear_usage]) ? true : false
  end

  def validate_addtl_fs_gb?
    (self.usage_type == UsageRecord::USAGE_TYPES[:addtl_fs_gb]) ? true : false
  end

  def validate_cart_name?
    (self.usage_type == UsageRecord::USAGE_TYPES[:premium_cart]) ? true : false
  end

  def self.find_all
    get_list(self.each)
  end

  def self.find_by_user(user_id)
    get_list(where(:user_id => user_id))
  end

  def self.find_by_user_after_time(user_id, time)
    get_list(where(:user_id => user_id, :begin_time.gte => time))
  end

  def self.find_by_user_time_range(user_id, begin_time, end_time)
    get_list(where(:user_id => user_id).nor({:end_time.lt => begin_time}, {:begin_time.gt => end_time}))
  end

  def self.find_by_user_gear(user_id, gear_id, begin_time=nil)
    unless begin_time
      return get_list(where(:user_id => user_id, :gear_id => gear_id))
    else
      return get_list(where(:user_id => user_id, :gear_id => gear_id, :begin_time => begin_time))
    end
  end

  def self.find_by_filter(user_id, filter = {})
    # Construct the query criteria
    condition = where(user_id: user_id)
    condition = condition.where(gear_id: filter["gear_id"]) unless filter["gear_id"].nil?
    condition = condition.where(app_name: filter["app_name"]) unless filter["app_name"].nil?
    condition = condition.where("$or" => [{:end_time => nil}, {:end_time => {"$gte" => filter["begin_time"]}}]) unless filter["begin_time"].nil?
    condition = condition.where(:begin_time.lte => filter["end_time"]) unless filter["end_time"].nil?

    return get_list(condition)
  end

  def self.find_latest_by_user_gear(user_id, gear_id, usage_type)
    where(:user_id => user_id, :gear_id => gear_id, :usage_type => usage_type).desc(:begin_time).first
  end

  def self.find_user_summary(user_id)
    usage_events = get_list(where(user_id: user_id))
    res = {}
    usage_events.each do |e|
      res[e.gear_size] = {} unless res[e.gear_size]
      res[e.gear_size]['num_gears'] = 0 unless res[e.gear_size]['num_gears']
      res[e.gear_size]['num_gears'] += 1
      res[e.gear_size]['consumed_time'] = 0 unless res[e.gear_size]['consumed_time']
      unless e.end_time
        res[e.gear_size]['consumed_time'] += Time.now.utc - e.begin_time
      else
        res[e.gear_size]['consumed_time'] += e.end_time - e.begin_time
      end
    end
    res
  end

  def self.delete_by_user(user_id)
    where(user_id: user_id).delete
  end

  def self.delete_by_gear(gear_id)
    where(gear_id: gear_id).delete
  end

  def self.get_usage_rate(plan_id, usage_type, gear_size, cart_name)
    nil
  end

  private

  def self.get_list(cond)
    recs = []
    cond.each do |r|
      recs.push(r)
    end
    recs
  end
end
