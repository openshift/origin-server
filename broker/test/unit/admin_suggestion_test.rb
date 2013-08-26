require 'unit/helpers/admin_stats_helper'
require 'pp'
require 'yaml'

class AdminSuggestionTest < ActiveSupport::TestCase

  # define shortcuts for class constants in these tests
  S = Admin::Suggestion
  C = S::Capacity

  def setup
    super

    # provide fake profiles from Rails conf
    @conf = Rails.application.config.openshift
    @real_profiles, @conf[:gear_sizes] = @conf[:gear_sizes], %w[prof1 prof2 prof3 prof4]

    # testable capacity conf values
    @params = {
      active_gear_pct: {
        default: 80,
        'prof1' => nil, # use the default default
        'prof2' => 110, # too big
        'prof3' => 0, # too small
        # prof4 will use above default
      },
      gear_up_threshold: {
        default: 100,
        'prof1' => nil, # disabled
        'prof2' => 100,
        'prof3' => -49, # bogus
        'prof4' => 18.3,
      },
      gear_up_size: {
        default: 100,
        'prof1' => nil, # default 200
        #'prof2' => 100, # use above default
        'prof3' => -49, # bogus
        'prof4' => 250,
      },
      gear_down_threshold: {
        'prof1' => 200,
        'prof2' => 100, # too low
        'prof3' => lambda { puts },  # really bogus
        'prof4' => nil, # disabled
      },
    }

    @nodes_hash = {}
    @districts = []
    @districts_for_profile = Hash.new {|h,k| h[k] = []}
  end

  def teardown
    super
    admin_stats_unstubber
    @conf[:gear_sizes] = @real_profiles
  end

  # convenience - 3 lines to 1
  def admin_stats_results(opts = {})
    # Actually use Admin::Stats but with canned inputs;
    # We could stub canned results, but we would actually
    # like tests to break if something about Admin::Stats
    # shifts out from underneath this code, so this veers
    # somewhat in the direction of integration testing.
    admin_stats_stubber(@nodes_hash, faux_db_with(@districts))
    stats = Admin::Stats.new(opts)
    stats.gather_statistics
    stats.results
  end

  def assert_ids_work(container)
    seen = Set.new
    container.each do |sug|
      assert !seen.include?(sug.id), "Suggestion id should be unique\n#{sug}"
      assert_equal sug.id, Marshal.load(Marshal.dump sug).id,
        "need ids stable across serialization\n#{sug}"
      seen.add sug.id
    end
  end

  test "instantiating and filtering leaf subclasses" do
    sugs = S::Container.new
    sugs << S::Config::FixVal.new(profile: "small", scope: "profile",
                                  name: :gear_up_threshold, value: -2 )
    sugs << S::Config::FixGearDown.new(profile: "small", scope: "profile",
                                       up: 100, down: 90 )
    add1 = C::Add::Node.new(profile: "small", scope: "district", threshold: 100,
                            district_uuid: "uuid", active_gear_pct: 90)
    add2 = C::Add::District.new(profile: "notsmall", scope: "profile",
                                threshold: 100, active_gear_pct: 90)
    add = C::Add.new(profile: "small", scope: "profile",
                     threshold: 100, active_gear_pct: 90,
                     contents: S::Container.new + [add1, add2])
    rm = C::Remove::Node.new(profile: "small", threshold: 100)
    rm2 = C::Remove::CompactDistrict.new(profile: "bogus", district_uuid: "whatever",
                                         scope: "district", active_gear_pct: 10)
    sugs += [ add, add1, add2, rm, rm2 ]

    assert_raises(RuntimeError, "invalid scope foo") { sugs.for_scope("foo") }
    assert_equal 0, sugs.for_scope("general").size, "no general suggestions"
    assert_equal 5, sugs.for_scope("profile").size, "profile suggestions"
    assert_equal 4, sugs.for_scope("profile", "small").size, "small profile suggestions"
    assert_equal 2, sugs.for_scope("district").size, "district suggestions"
    assert_equal 1, sugs.for_scope("district","whatever").size, "specific district sugs"
    assert add.important?, "Adding capacity is important"
    refute rm.important?, "Removing capacity is important"
    assert_equal 5, sugs.important.size, "important suggestions"
    assert_equal 2, sugs.important(false).size, "non-important suggestions"
    assert_ids_work(sugs)
  end

  test "test instances all deserialize with same ids" do
    sugs = S::Advisor.subclass_test_instances
    assert_ids_work(sugs)
  end

  test "params r/w" do
    assert_nil S::Params.new.gear_up_threshold, "empty conf works"
    assert_equal 50, S::Params.new.active_gear_pct(:any), "empty conf active pct"
    assert_kind_of Hash, S::Params.new(active_gear_pct: {}).active_gear_pct(),
      "requesting value without profile scope returns hash for all"
    assert_raises(RuntimeError, "create with no hash") {S::Params.new(nil)}
    assert_raises(RuntimeError, "create with bad threshold") do
      S::Params.new({gear_up_threshold: "bogus"}).gear_up_threshold(:any)
    end
    assert_raises(NoMethodError, "unknown attr") { S::Params.new({breakme:1}) }
    c = nil
    assert_nothing_raised("with params #{@params}") { c = S::Params.new(@params) }
    c.validate # clean out any bogus values
    assert_equal 18, c.gear_up_threshold("prof4"),
      "should convert float threshold to int"
    assert_equal 100, c.gear_up_threshold("bogus"),
      "should use default when none specified"
    assert_equal 200, c.gear_up_size("prof1"),
      "gear_up_size should use *default* default when nil specified"
    assert_equal 100, c.gear_up_size("prof2"),
      "gear_up_size should use default when none specified"
    assert_equal 200, c.gear_up_size("prof3"),
      "gear_up_size should use *default* default when bogus value specified"
  end

  test "test pathological confs" do
    assert_equal 0, S::Params.new({}).validate.size, "empty conf should pass"
    sug1 = S::Params.new({gear_up_threshold: "bogus"}).validate
    assert_equal 1, sug1.size, "non-hash threshold should fail"
    assert_kind_of S::Config::FixVal, sug1.first
    sug2 = S::Params.new({active_gear_pct: {default:0}}).validate
    assert_equal 1, sug2.size, "0 active pct should fail"
    sug3 = S::Params.new({active_gear_pct: {default:101}}).validate
    assert_equal 1, sug3.size, "101 active pct should fail"
    assert_ids_work(sug1 + sug2 + sug3)
  end

  class BreakMe < S::Advisor
    def self.query(*args); []; end
  end

  test "drive suggestion errors" do
    boring_install_2x4per
    admin_stats_stubber(@nodes_hash, faux_db_with(@districts))
    p = S::Params.new()
    p.stubs(:mcollective_timeout).raises(StandardError.new)
    sugs = nil
    sugs = S::Advisor.query(p)
    assert_kind_of S::Error, sugs[0], "should have an error #{sugs}"
    assert_ids_work(sugs)

    begin
      BreakMe.stubs(:query).raises(StandardError.new)
      sugs = S::Advisor.query({})
    ensure
      BreakMe.unstub(:query)
    end
    assert_kind_of S::Error, sugs[0], "should have an error #{sugs}"
    assert_ids_work(sugs)
  end

  test "Container methods" do
    c = S::Container.new + [S::Base.new({scope: "general"}),
      S::Base.new(profile: 'foo'), S::Base.new(profile: 'foo', district_uuid: 'bar')]
    assert_kind_of S::Container, c, "add an arr gives me a Container"
    assert_difference ->{ c.size }, 1, "<<ing an element" do
      c <<  S::Base.new(profile: 'foo2')
    end
    assert_difference ->{ c.size }, 1, "+ing an element" do
      c +=  S::Base.new(profile: 'foo2', district_uuid: 'bar2')
    end
    c = (c + nil).compact
    assert_kind_of S::Container, c, "add with element gives me a Container"
    assert_kind_of S::Container, c.for_general, "select gives me a Container"
    assert_equal 1, c.for_general.size
    assert_equal 2, c.for_profile('foo').size
    assert_equal 1, c.for_district('bar2').size
    assert_equal 3, c.group_by_profile.size, "2 profiles plus nil"
    assert_equal 3, c.group_by_district_uuid.size, "2 districts plus nil"
    assert c.group_by_class.has_key?(S::Base), "group by class"
    assert_equal 1, c.group_by_class.size, "group by class - only one"
    assert_ids_work(c)
  end

  test "check, fix, and suggest for conf anomalies" do
    p = S::Params.new(@params)
    #puts p.pretty_inspect
    sugs = p.validate
    assert sugs.size > 0, "should be some conf validation failures"
    assert_equal 5, sugs.select {|s| s.is_a? S::Config::FixVal }.size,
      "should get suggestions for invalid values #{sugs.pretty_inspect}"
    assert_equal 1, sugs.select {|s| s.is_a? S::Config::FixGearDown }.size,
      "should get a suggestion for prof2 up/down mismatch"
    assert_nil p.gear_up_threshold('prof3'), "prof3 up should be nilled"
    assert_nil p.gear_down_threshold('prof3'), "prof3 down should be nilled"
    assert_ids_work(sugs)
  end

  test "admin stats is what I think" do
    boring_install_2x4per
    results = admin_stats_results()
    #pp "All results:", results
    #pp "Profiles:", results[:profile_summaries_hash]
    #pp "Districts:", results[:district_summaries_hash]
    #pp "Nodes:", results[:node_entries_hash]
    #pp "Results keys:", results.keys
    #write_fake_dataset("boring-2x4.yaml")
  end

  test "Capacity::Add::Advisor calculation steps" do
    @params = { active_gear_pct: { default: 50 },
                gear_up_threshold: { default: 100 },
                gear_up_size: { default: 100 } }
    p = S::Params.new(@params)
    @conf[:gear_sizes] = [ profile = "test" ]
    duuid = "dist1"  # one node, active pct = 100%
      dist_nodes_hash = {}
      name = "dist1-100.example.com"
        @nodes_hash[name] = dist_nodes_hash[name] =
          faux_node_entry(profile, duuid, "true").merge(
            max_active_gears: 200, gears_total_count: 200, gears_active_count: 200)
      @districts << (dist1 = faux_mongo_district(dist_nodes_hash))
    duuid = "dist2"  # two unbalanced nodes, same active pct = 50%
      dist_nodes_hash = {}
      name = "dist2-large.example.com"
        @nodes_hash[name] = dist_nodes_hash[name] =
          faux_node_entry(profile, duuid, "true").merge(
            max_active_gears: 200, gears_total_count: 300, gears_active_count: 150)
      name = "dist2-small.example.com"
        @nodes_hash[name] = dist_nodes_hash[name] =
          faux_node_entry(profile, duuid, "true").merge(
            max_active_gears: 100, gears_total_count: 200, gears_active_count: 100)
      @districts << (dist2 = faux_mongo_district(dist_nodes_hash))
    duuid = "dist_empty"  # no nodes whatsoever
      @districts << (dist_empty = faux_mongo_district({}))
      dist_empty['uuid'] = duuid
    duuid = "dist_miss"  # one node, one more missing
      dist_nodes_hash = {}
      name = "distmiss-there.example.com"
        @nodes_hash[name] = dist_nodes_hash[name] =
          faux_node_entry(profile, duuid, "true").merge(
            max_active_gears: 200, gears_total_count: 300, gears_active_count: 150)
      @districts << (dist_miss = faux_mongo_district(dist_nodes_hash))
      dist_miss['server_identities'] << {'name' => 'distmiss-missing', 'active' => true}
      dist_miss['available_capacity'] = 5400
    #write_fake_dataset("profile-test-districts.yaml")

    # setup to test that our calculations work sanely
    stats = admin_stats_results()
    psums = stats.profile_summaries_hash
    #puts "Profile summary:", psums[profile].pretty_inspect
    dsums = stats.district_summaries_hash
    d1sum = dsums[dist1['uuid']]
    d2sum = dsums[dist2['uuid']]
    d_empty_sum = dsums[dist_empty['uuid']]
    d_miss_sum = dsums[dist_miss['uuid']]
    #puts "District summary: #{d_miss_sum}"
    #puts "District summary: #{d_empty_sum}"

    # test the individual calculation steps
    add = C::Add::Advisor

    assert_equal 200, add.node_capacity_in_profile(psums[profile]),
      "large nodes should dominate capacity"

    assert_equal 30, add.suggested_nodes_per_district(200, 100),
      "based on existing nodes and active pct, suggested nodes per district"
    assert_equal 3,  add.suggested_nodes_per_district(200, 10),
      "based on existing nodes and active pct, suggested nodes per district"
    assert_equal 2,  add.suggested_nodes_per_district(100, 1),
      "never fewer than 2 nodes in a district"

    assert_equal 50,  add.adjusted_active_pct(d2sum, 200, 100),
      "district with overly idle nodes gets adjusted"

    assert_equal 30, add.nodes_district_can_accept(d_empty_sum, 200, 100),
      "district with no nodes gets the suggested number"
    assert_equal 3,  add.nodes_district_can_accept(d_empty_sum, 200, 10),
      "district with no nodes gets the suggested number"
    assert_equal 29, add.nodes_district_can_accept(d1sum, 200, 100),
      "district with nodes gets the difference"
    assert_equal 2,  add.nodes_district_can_accept(d1sum, 200, 10),
      "district with nodes gets the difference"
    assert_equal 1,  add.nodes_district_can_accept(d2sum, 200, 10),
      "district with overly idle nodes accepts adjusted number of nodes"
    assert_equal 0, add.nodes_district_can_accept(d2sum, 200, 5),
      "district with as many nodes as suggested gets none"

    open_dists = add.districts_with_space(dsums.values, 200, 100)
    assert_equal 3, open_dists.size,
      "all districts have space except the one with missing node"
    assert_equal 2, add.districts_with_space(dsums.values, 200, 5).size,
      "districts with < 2 nodes have space"

    open_dists = add.districts_with_space(dsums.values, 200, 100)
    sugs = add.add_node({}, open_dists, 1)
    assert_ids_work(sugs)
    assert_equal 1, sugs.size, "suggest one node to add"
    assert_equal d_empty_sum.uuid, sugs[0].district_uuid,
      "first should be added to empty district"
    open_dists = add.districts_with_space(dsums.values, 200, 100)
    sugs = add.add_node({}, open_dists, 4)
    assert_ids_work(sugs)
    assert_equal 3, sugs.size, "nodes should go to all 3 districts:\n#{sugs}"
    d_empty_sug = sugs.select {|d| d_empty_sum.uuid == d.district_uuid}.first
    assert_not_nil d_empty_sug, "nodes added to empty district:\n#{sugs}"
    assert_equal 2, d_empty_sug.node_quantity,
      "empty district should get 2 of 4:\n#{sugs}"

    s = { profile: profile,
          active_gear_pct: 50,
          available_gears: 100,
          threshold: 200,
          max_active_gears: 100,
          gears_needed: 400,
          nodes_needed: 4,
          nodes_creatable: 3,
        }
    assert_not_nil (dist_sug = add.add_district(s)), "should get a suggestion"
    assert_kind_of C::Add::District, dist_sug, "should get a district suggestion"
    assert_equal 1, dist_sug.district_quantity, "suggest one district"
    assert_equal 4, dist_sug.node_quantity, "suggest district with 4 nodes"
    assert_equal 4, dist_sug.nodes_per_district, "suggest district with 4 nodes"
    s[:active_gear_pct] = 10
    assert_equal 6, add.suggested_nodes_per_district(100, 10), "lower district target"
    assert_not_nil (dist_sug = add.add_district(s)), "should get a suggestion"
    assert_equal 1, dist_sug.district_quantity, "suggest one district"
    assert_equal 3, dist_sug.node_quantity, "suggest district with 6/2=3 nodes"
    s[:active_gear_pct] = 5
    s[:nodes_needed] = 6
    assert_equal 3, add.suggested_nodes_per_district(100, 5), "lower district target"
    assert_not_nil (dist_sug = add.add_district(s)), "should get a suggestion"
    assert_equal 2, dist_sug.district_quantity, "suggest multiple districts"
    assert_equal 2, dist_sug.nodes_per_district, "suggest district with 3/2=2 nodes"
    assert_equal 4, dist_sug.node_quantity, "suggest 2 districts with 2 nodes"
  end

  test "when there's a need to add capacity" do
    boring_install_2x4per
    # set one district to have some space
    open = @districts_for_profile['prof1'][0]
    # make one oddball node with larger capacity
    @nodes_hash['prof2-d1-n1.example.com'][:max_active_gears] = 200
    stats = admin_stats_results()

    # setup to test that our calculations work sanely
    psums = stats[:profile_summaries_hash]
    dsums = stats[:district_summaries_hash]
    #puts "Profile summary:", psums['prof1'].pretty_inspect
    open_sum = dsums[open['uuid']]
    #puts "District summary:", open_sum.pretty_inspect

    # try to get a suggestion for more capacity
    params = S::Params.new(
      active_gear_pct: { default: 100 }, # nothing ever idles
      gear_up_threshold: { 'prof1' => 401 }, # 400 = 8 nodes * 50 available gears each
    )
    sugs = C::Add::Advisor.query(params, stats, nil)
    psugs = sugs.pretty_inspect
    refute sugs.any? {|s| s.is_a? S::Error}, "errors running suggestions:\n#{psugs}"
    refute sugs.any? {|s| s.is_a? S::Config}, "configuration suggestions:\n#{psugs}"
    assert_equal 1, sugs.for_profile('prof1').size,
      "should suggest adding capacity for profile 'prof1'\n#{psugs}"
    assert_kind_of C::Add, sugs.for_profile('prof1').first
    nodes = sugs.for_profile('prof1').first.contents
    assert_equal 2, nodes.size,
      "should suggest adding nodes in two districts for profile 'prof1'\n#{psugs}"
    assert_kind_of C::Add::Node, nodes.first
    assert_equal "district", nodes.first.scope
    assert_equal 1, nodes.for_district(open['uuid']).size,
      "should suggest adding a node for the district with capacity in 'prof1'\n#{psugs}"
    assert_ids_work(sugs)


    # this time we should require new districts
    params = S::Params.new({
      active_gear_pct: { default: 10 }, # 6 nodes per district
      gear_up_threshold: { 'prof1' => 4000 }, # 400 = 8 nodes * 50 available gears each
    })
    sugs = C::Add::Advisor.query(params, stats, nil)
    psugs = sugs.pretty_inspect
    refute sugs.any? {|s| s.is_a? S::Error}, "errors running suggestions:\n#{psugs}"
    assert_equal 1, sugs.for_profile('prof1').size,
      "should suggest adding capacity for profile 'prof1'\n#{psugs}"
    adds = sugs.for_profile('prof1').first.contents
    assert_equal 3, adds.size,
      "should suggest adding nodes in districts (one new) for profile 'prof1'\n#{psugs}"
    sugdist = adds.select {|s| s.district_uuid.nil?}
    assert_equal 1, sugdist.size, "suggest new districts in 'prof1'\n#{psugs}"
    assert_kind_of C::Add::District, sugdist.first,
      "suggest new districts in 'prof1'\n#{psugs}"
    assert_ids_work(sugs)
  end

  test "adding capacity with no district" do
    no_district_install
    stats = admin_stats_results()
    #puts stats.profile_summaries
    #write_fake_dataset 'no-districts.yaml'
    sugs = S::Advisor.query(gear_up_threshold: { default: 4000 })
    assert_ids_work(sugs)
    assert_equal 1, sugs.size, "one suggestion\n#{sugs}"
    assert_kind_of C::Add, sugs.first, "suggest adding capacity\n#{sugs}"
    sugs = sugs.first.contents
    assert_equal 1, sugs.size, "one rolled up suggestion\n#{sugs}"
    assert_kind_of C::Add::Node, sugs.first, "suggest adding nodes\n#{sugs}"
    assert_nil sugs.first.district_uuid, "add undistricted nodes\n#{sugs}"
    assert_ids_work(sugs)
  end

  def write_fake_dataset(file)
    file = File.join(File.dirname(__FILE__), '..', 'data', file)
    File.open(file, 'w') {|f| f.write(YAML.dump admin_stats_results()) }
  end

  def boring_install_2x4per
    # for each profile stub 2 districts w/ 4 nodes each
    # district uuids are like "prof1-d1" and "prof1-d2"
    # node names are like "prof1-d1-n1", "prof1-d1-n2",...
    # all created identical; tests manipulate these and thresholds.
    @conf[:gear_sizes].each do |profile|
      (1..2).each do |distnum|
        district_uuid = "#{profile}-d#{distnum}"
        dist_nodes_hash = {}
        (1..4).each do |nodenum|
          name = "#{district_uuid}-n#{nodenum}.example.com"
          node = faux_node_entry(profile, district_uuid, "true").merge({
            max_active_gears: 100,
            gears_active_count: 50,
          })
          @nodes_hash[name] = dist_nodes_hash[name] = node
        end
        @districts << (district = faux_mongo_district(dist_nodes_hash))
        @districts_for_profile[profile] << district
      end
    end
  end

  def no_district_install
    @conf[:gear_sizes] = %w[ small ]
    @nodes_hash = {}
      (1..10).each do |nodenum|
        node = faux_node_entry('small', 'NONE', "true").merge({
          max_active_gears: 100,
          gears_active_count: 5,
        })
        @nodes_hash["node#{nodenum}.example.com"] = node
      end
  end

  test "write mismanaged install" do
    mismanaged_install
    #write_fake_dataset 'mismanaged-install.yaml'
  end

  test "need to remove capacity" do
    mismanaged_install
    inactive_node = "too_empty-d1-n7.example.com"
    @nodes_hash[inactive_node][:district_active] = false
    stats = admin_stats_results()
    #puts stats.profile_summaries
    #write_fake_dataset 'mismanaged-install.yaml'
    # this should result in compacting some districts
    sugs = C::Remove::Advisor.compact_districts(S::Params.new, stats)
    assert_ids_work(sugs)
    psugs = "\n#{sugs.pretty_inspect}"
    assert_equal 1, sugs.size, "should get compacting suggestion#{psugs}"
    sug = sugs.last
    assert_kind_of C::Remove::CompactDistrict, sug, "suggest compacting district#{psugs}"
    assert_equal 3, sug.node_target, "node_target #{psugs}"
    assert_equal 250, sug.excess_gears, "excess gears#{psugs}" # 500 active - 250 dist
    assert_equal 4, sug.node_names.size, "remove nodes#{psugs}" # 4 * 75 > 250
    assert_includes sug.node_names, inactive_node, "inactive was removed"

    params = S::Params.new(gear_down_threshold: { "too_empty" => 200 })
    sugs = C::Remove::Advisor.remove_nodes_from_profile(params,
                                              stats.profile_summaries_hash["too_empty"])
    assert_ids_work(sugs)
    psugs = "\n#{sugs.pretty_inspect}"
    #puts stats.profile_summaries_hash["too_empty"].pretty_inspect
    #puts psugs
    assert_equal 1, sugs.size, "should get removal suggestions #{psugs}"
    assert_kind_of C::Remove::Node, sugs.last, "suggest node removal #{psugs}"

    sugs = S::Advisor.query(params)
    assert_ids_work(sugs)
    assert_equal 1, sugs.size, "should get compacting but no removal suggestion#{psugs}"
    assert_kind_of C::Remove::CompactDistrict, sugs.first
  end

  test "NONE district doesn't get compaction suggestion" do
    no_district_install
    stats = admin_stats_results()
    sugs = S::Advisor.query(active_gear_pct: {default: 1})
    psugs = "\n#{sugs.pretty_inspect}"
    assert_empty sugs, "nothing to suggest"
  end

  test "NONE district doesn't get add capacity suggestion" do
    skip
  end

  test "missing nodes are missed" do
    boring_install_2x4per
    @districts.each do |dist|
      dist['server_identities'] << {'name' => "missing-#{dist['uuid']}",
                                  'active' => true}
      dist['server_identities'] << {'name' => "missing2-#{dist['uuid']}",
                                  'active' => true}
    end
    sugs = S::Advisor.query(S::Params.new, admin_stats_results())
    assert_equal 1, sugs.for_general.size, "one overall list of missing nodes\n#{sugs}"
    assert_ids_work(sugs)

    all = sugs.for_general.first
    assert_kind_of S::MissingNodes, all, "general missing nodes\n#{sugs}"
    assert_equal @districts.size * 2, all.nodes.size, "two nodes missing per dist"
    assert_ids_work(sugs = all.contents)
    prof = sugs.for_scope 'profile', 'prof1'
    assert_equal 1, prof.size, "one profile-level per profile"
    assert_equal "profile", prof.first.scope
    assert_equal 4, sugs.for_scope("profile").size, "4 profiles"
    assert_equal 8, sugs.for_scope("district").size, "2 districts per profile"
    assert_equal 12, sugs.size, "4 profiles + 2 districts per"
  end

  def mismanaged_install
    @conf[:gear_sizes] = %w[ too_empty too_full needs_compacting ]
    profile = "too_empty"
      district_uuid = "#{profile}-d1"
        dist_nodes_hash = {}
        (1..10).each do |nodenum|
          name = "#{district_uuid}-n#{nodenum}.example.com"
          node = faux_node_entry(profile, district_uuid, "true").merge({
            max_active_gears: 75,
            gears_active_count: 25, # 50 free, x 10 nodes
            gears_total_count: 575, # active_pct < 5
          })
          @nodes_hash[name] = dist_nodes_hash[name] = node
        end
        @districts << (district = faux_mongo_district(dist_nodes_hash))
        @districts_for_profile[profile] << district
    profile = "too_full"
      (1..15).each do |distnum|
        district_uuid = "#{profile}-d#{distnum}"
        dist_nodes_hash = {}
        (1..(2+rand(6).round)).each do |nodenum|
          name = "#{district_uuid}-n#{nodenum}.example.com"
          node = faux_node_entry(profile, district_uuid, "true").merge({
            max_active_gears: 75,
            gears_active_count: 60 + rand(20).round,
            gears_total_count: 750 + rand(100).round,
          })
          @nodes_hash[name] = dist_nodes_hash[name] = node
        end
        @districts << (district = faux_mongo_district(dist_nodes_hash))
        @districts_for_profile[profile] << district
      end
  end
end
