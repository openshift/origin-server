class Usage
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "usage"

  field :login, type: String
  field :gear_id, type: String
  field :begin_time, type: Time
  field :end_time, type: Time
  field :usage_type, type: String
  field :gear_size, type: String
  field :addtl_fs_gb, type: Integer

  def self.track_usage(data)
    gear_uuid = data[:gear_uuid]
    login = data[:login]
    event = data[:event]
    time = data[:time]
    uuid = data[:uuid]
    usage_type = data[:usage_type]
    gear_size = data[:gear_size]
    addtl_fs_gb = data[:addtl_fs_gb]
    usage = nil
    if event == UsageRecord::EVENTS[:begin]
      usage = Usage.new(login, gear_uuid, time, nil, uuid, usage_type)
      usage.gear_size = gear_size if gear_size
      usage.addtl_fs_gb = addtl_fs_gb if addtl_fs_gb
    elsif event == UsageRecord::EVENTS[:end]
      usage = Usage.find_latest_by_gear(gear_uuid, usage_type)
      if usage
        usage.end_time = time
      end
    end
    usage.save! if usage
  end
  
  def self.find_all
    get_list(self.each)
  end
 
  def self.find_by_user(login)
    get_list(where(:login => login))
  end

  def self.find_by_user_after_time(login, time)
    get_list(where(:login => login, :begin_time.gte => time))
  end

  def self.find_by_user_time_range(login, begin_time, end_time)
    get_list(where(:login => login).nor({:end_time.lt => begin_time}, {:begin_time.gt => end_time}))
  end

  def self.find_by_gear(gear_id, begin_time=nil)
    unless begin_time
      return get_list(where(:gear_id => gear_id))
    else
      return get_list(where(:gear_id => gear_id, :begin_time => begin_time))
    end
  end
  
  def self.find_latest_by_gear(gear_id, usage_type)
    where(:gear_id => gear_id, :usage_type => usage_type).sort(:begin_time.desc).first
  end

  def self.find_user_summary(login)
    usage_events = get_list(where(login: login))
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

  def self.delete_by_user(login)
    where(login: login).delete
  end

  def self.delete_by_gear(gear_id)
    where(gear_id: gear_id).delete
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
