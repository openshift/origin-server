require 'test_helper'

# Make sure it's loaded - prevent mysterious test failures where Rails
# tries to find something in a sub-namespace first.
Admin::Stats::Maker

# produces a node facts entry for a node like mcollective
def faux_node_entry(profile=nil, district_uuid=nil, active=nil)
  Admin::Stats::NodeEntry.new(0).merge({
    node_profile: profile || "test",
    district_uuid: district_uuid || "test_dist",
    district_active: active || "true",
    max_active_gears: 100,
    gears_total_count: 150,
    gears_active_count: 50,
    gears_active_usage_pct: 50,
    # everything else defaults to 0
  })
end

# produces a mongo collection hash for a district, using node entries like above
def faux_mongo_district(nodes_hash={})
  profile = "test"
  uuid = profile
  used = 0
  servers = nodes_hash.map do |name,hash|
    used += hash[:gears_total_count]
    profile = hash[:node_profile] || profile
    uuid = hash[:district_uuid] || uuid
    { 'name' => name,
      'active' => ["true", true].include?(hash[:district_active]) }
  end
  {
    'gear_size' => profile,
    'uuid' => uuid,
    'name' => "#{uuid}_district",
    'servers' => servers,
    'max_capacity' => 6000,
    'available_capacity' => 6000-used,
    'available_uids' => [(used..5999).to_a],
  }
end

# produces a db object that mocks what Admin::Stats#_with_each_record needs
def faux_db_with(district_hashes)
  dbclass = Class.new do
    def collection(name, &block); @name = name; @block = block; self; end
    def find(*args, &block); block.call(self); end
    def each(&block)
      coll = {
        :districts => my_districts(),
        :cloud_users => [],
        :domains => [],
        :applications => [],
      }
      coll[@name].each {|hash| block.call(hash) }
    end
    def my_districts; []; end   # to stub as needed!
  end
  db = dbclass.new
  db.stubs(:my_districts).returns(district_hashes)
  db
end

def admin_stats_stubber(nodes_hash, db)
    OpenShift::ApplicationContainerProxy.stubs(:get_details_for_all).returns(nodes_hash)
    OpenShift::DataStore.stubs(:db).returns(db)
end

def admin_stats_unstubber
    OpenShift::ApplicationContainerProxy.unstub(:get_details_for_all)
    OpenShift::DataStore.unstub(:db)
end
