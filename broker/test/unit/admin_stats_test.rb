require 'test_helper'

class AdminStatsTest < ActiveSupport::TestCase
  def setup
    super
    @stats = Admin::Stats.new
    @dist_uuid = "1234"
    @node_details = {
      node_profile: "test",
      district_uuid: @dist_uuid,
      district_active: "true",
      max_active_gears: 10,
      gears_started_count: 7,
      gears_idle_count: 10,
      gears_stopped_count: 3,
      gears_deploying_count: 2,
      gears_unknown_count: 1,
      gears_total_count: 23,
      gears_active_count: 10,
      gears_usage_pct: 230,
      gears_active_usage_pct: 100,
    }
    @node_name = "test-node.example.com"
    @short_name = "test-node"
    OpenShift::ApplicationContainerProxy.stubs(:get_details_for_all).returns({
      @node_name => @node_details,
      "clone.example.com" => @node_details.merge(district_uuid: "NONE"),
    })

    @db = Class.new do # mock what :_with_each_record needs
      def collection(name, &block); @name = name; @block = block; self; end
      def find(*args, &block); block.call(self); end
      def each(&block)
        coll = {
          :districts => [{
                          'gear_size' => "test",
                          'name' => "1234_district",
                          'uuid' => '1234',
                          'server_identities' => [ {'name' => "test-node.example.com",
                                                    'active' => true },
                                                   {'name' => "missing.example.com",
                                                    'active' => true }
                                                 ],
                          'max_capacity' => 6000,
                          'available_capacity' => 3,
                          'available_uids' => [1,2,3,4,5],
                       }],
          # the other ones are too complex to stub...
          :cloud_users => [],
          :domains => [],
          :applications => [],
        }
        coll[@name].each {|hash| block.call(hash) }
      end
    end
    @db = @db.new
    OpenShift::DataStore.stubs(:db).returns(@db)
  end

  def teardown
    super
    OpenShift::ApplicationContainerProxy.unstub(:get_details_for_all)
    OpenShift::DataStore.unstub(:db)
  end

  test "fetch and return list of node details" do
    node_hash = @stats.get_node_entries
    assert node_hash.has_key?(@node_name),
      "expecting to see #{@node_name} in node hash"
    assert_equal @short_name, node_hash[@node_name][:name]
    assert_equal 2, node_hash.size
  end

  test "fetch a list of districts from the db" do
    dist_hash = @stats.get_district_entries
    assert_equal 1, dist_hash.size, "should be 1 district in db: #{dist_hash}"
    assert dist_hash.has_key?(@dist_uuid),
      "expecting to see #{@dist_uuid} in district hash"
    assert_equal 5, dist_hash[@dist_uuid][:dist_avail_uids]
    assert dist_hash[@dist_uuid][:nodes].has_key?(@node_name),
      "expecting to see #{@node_name} in the node list for district #{@dist_uuid}"
  end

  test "summarize district details" do
    sum_hash = @stats.summarize_districts(@stats.get_district_entries, @stats.get_node_entries)
    assert_equal 2, sum_hash.size, "number of districts to summarize (one is NONE)"
    assert sum_hash.has_key?(@dist_uuid), "expecting district #{@dist_uuid}"
    assert sum_hash.has_key?('NONE profile=test'), "expecting district NONE"
    assert_equal 0, sum_hash[@dist_uuid][:effective_available_gears]
    assert_equal 1, sum_hash[@dist_uuid][:missing_nodes].size,
      "missing.example.com should be missing"
  end

  test "getting db stats" do
    count_all, count_for_profile, count_for_user = @stats.get_db_stats
    # there won't be a lot but we can spot check the counts are there...
    assert count_all.has_key?(:apps), "count_all should have :apps"
    assert count_all.has_key?(:cartridges), "count_all should have :cartridges"
    assert_equal 0, count_all[:cartridges]['ruby'], "expecting cart counts 0"

    assert_empty count_for_profile, "count_for_profile not filled from db"
    assert_empty count_for_user, "Expecting no users in fake db"
  end

  test "clearing on clones of the results allows marshaling" do
    # first test on something ordinary
    h = Hash.new {|h,k| h[k] = 0}
    assert_raise(TypeError) {Marshal.dump(h)}
    @stats.deep_clear_default!(h)
    assert_nothing_raised {Marshal.dump(h)}

    # now test on stats we gathered
    @stats.gather_statistics
    results = @stats.results
    assert_raise(TypeError) {Marshal.dump(results)}
    @stats.deep_clear_default!(results)
    assert_nothing_raised { Marshal.dump(results) }
  end

  test "summarize profile details without db stats" do
    sum_hash = @stats.summarize_districts(@stats.get_district_entries, @stats.get_node_entries)
    pro_hash = @stats.summarize_profiles(sum_hash, nil)
    assert pro_hash.has_key?('test'), "should see profile 'test'"
    test_p = pro_hash['test']
    assert_includes test_p[:districts], sum_hash[@dist_uuid]
    assert_equal 2, test_p[:district_count], "district count"
    assert_equal 2, test_p[:nodes_count], "node count"
    assert_equal 2, test_p[:nodes_active], "active nodes (2 responding)"
    assert_equal 0, test_p[:nodes_inactive], "inactive nodes (according to selves)"
    assert_equal 1, test_p[:missing_nodes].size, "missing.example.com should be missing"
  end

  test "summarize profile details with db stats" do
    count_all, count_for_profile, count_for_user = @stats.get_db_stats
    dist_hash = @stats.summarize_districts(@stats.get_district_entries, @stats.get_node_entries)
    pro_hash = @stats.summarize_profiles(dist_hash, count_for_profile)
    test_d = dist_hash[@dist_uuid]
    assert pro_hash.has_key?('test'), "should see profile 'test'"
    test_p = pro_hash['test']
    # summed district stats
    assert_equal 6000, test_p[:district_capacity], "1 district's capacity"
    assert_equal 3, test_p[:dist_avail_capacity], "1 district's available capacity"
    assert test_p[:highest_dist_usage_pct] > 5996.0 / 6000,
      "our test district should supply the highest usage pct"
    assert_equal 0.0, test_p[:lowest_dist_usage_pct],
      "fake district should report 0 usage pct"
    # summed db stats
    assert_equal 0, test_p[:total_gears_in_db_records], "no gears in db"
    assert_equal 0, test_p[:total_apps], "no apps in db"
    assert_equal 0, test_p[:cartridges].size, "no cartridges in db"
    assert_equal 0, test_p[:cartridges_short].size, "no short cartridges in db"
    assert_equal -2 * @node_details[:gears_total_count],
                 test_p[:gear_count_db_minus_node],
                  "node gears are not in db"
  end

  test "db option appropriately influences stats gathering" do
    @stats.gather_statistics
    assert_nil @stats.results[:count_all][:apps],
      "expecting no db app counting to have occurred"
    @stats.set_option :db_stats => true
    @stats.gather_statistics
    assert_not_nil @stats.results[:count_all][:apps],
      "expecting db counting has occurred"
  end

end
