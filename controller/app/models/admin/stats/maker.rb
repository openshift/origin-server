
require 'time'
require 'openshift/data_store'
require 'admin/stats/results'

class Admin::Stats::Maker

  def initialize(options = nil)
    @options = options || {}
    @time = {}
  end

  # e.g. set_option :db_stats => true
  # Current options:
  #   :db_stats - table scans the DB and is kind of expensive
  #   :read_file - read results from a file instead of generating
  #   :wait - time (in seconds, can be float) to wait for all of
  #           the nodes to respond to MCollective.
  def set_option(options)
    @options.merge! options
  end


  # use to time an operation in milliseconds
  def time_msecs
    start_time = (Time.now.to_f * 1000).to_i
    yield
    return (Time.now.to_f * 1000).to_i - start_time
  end

  # gather all statistics and analyze
  def gather_statistics
    return self.load_from_file if @options[:read_file]
    rpc_opts = Rails.configuration.msg_broker[:rpc_options]
    prev_timeout = rpc_opts[:disctimeout]
    rpc_opts[:disctimeout] = @options[:wait] || prev_timeout
    begin
      # read method comments about the structures they return
      @time['get_node_entries'] = time_msecs { @entry_for_node = get_node_entries }
      @time['get_district_entries'] = time_msecs { @entry_for_district = get_district_entries }
      @time['get_region_entries'] = time_msecs { @entry_for_region = get_region_entries }
      if @options[:db_stats] # don't gather this data unless requested with --db
        @time['get_db_stats'] = time_msecs do
          @count_all, @count_for_profile, @count_for_user = get_db_stats
        end
      end
      @time['summarize_districts'] = time_msecs do
        @summary_for_district = summarize_districts(@entry_for_district, @entry_for_node)
      end
      @time['summarize_profiles'] = time_msecs do
        @summary_for_profile = summarize_profiles(@summary_for_district, @count_for_profile)
      end
      @time['summarize_regions'] = time_msecs do
        @summary_for_region = summarize_regions(@summary_for_district, @entry_for_region, @entry_for_node)
      end
      @count_all ||= {} # db count may not have occurred
      @count_all['nodes'] = @entry_for_node.size
      @count_all['districts'] = @entry_for_district.size
      @count_all['profiles'] = @summary_for_profile.size
      @count_all['regions'] = @summary_for_region.size
    ensure
      rpc_opts[:disctimeout] = prev_timeout
    end
    return @time
  end

  # alternative to gather_statistics - "gathers" from a file instead
  def load_from_file(file = nil)
    case file ||= @options[:read_file]
    when nil
      raise "No file given"
    when /(yaml|yml)$/
      unless (@file_results = YAML.load_file file).is_a? Admin::Stats::HashWithReaders
        @file_results = Admin::Stats::HashWithReaders.deep_convert_hashes(@file_results)
      end
    when /(json|jsn|js)$/
      @file_results = JSON.parse( IO.read(file) )
      @file_results = Admin::Stats::HashWithReaders.deep_convert_hashes(@file_results)
    else
      raise "Don't know how to load file '#{file}'\n" +
            "Please use a file with .yaml or .json extension."
    end
    return @file_results[:timings_msecs] || {}
  end

  # Bundle up the statistics results in a hash
  def results
    @file_results || Admin::Stats::Results.new.merge({
      'timings_msecs' => @time,                             #timing hash
      'node_entries' => @entry_for_node.values,             #array of node hashes from mcollective
      'node_entries_hash' => @entry_for_node,               #hash of identity => node hashes from mcollective
      'district_entries' => @entry_for_district.values,     #array of district hashes from DB
      'district_entries_hash' => @entry_for_district,       #hash of name => district hashes from DB
      'district_summaries' => @summary_for_district.values, #array of district summary hashes
      'district_summaries_hash' => @summary_for_district,   #hash of name => district summary hashes
      'profile_summaries' => @summary_for_profile.values,   #array of profile summary hashes
      'profile_summaries_hash' => @summary_for_profile,     #hash of name => profile summary hashes
      'region_summaries' => @summary_for_region.values,
      'region_summaries_hash' => @summary_for_region,
      # remember, unless --db option is present, the db is not scanned for apps/gears/carts
      # in that case, only data from the nodes and districts are included
      'count_all' => @count_all,                            #overall summary hash
      # if db counts were gathered, hash of app/gear/cart counts per profile
      'db_count_for_profile' => @count_for_profile,
      # if db counts were gathered, array of users with app/gear counts
      'db_count_per_user' => @count_for_user ? @count_for_user.values : nil,
    }).deep_clear_default!
  end

  # get the node statistics by querying the facts on every node
  def get_node_entries
    entry_for_node = {}
    # Which comes out looking like:
    # {
    #   "node1.example.com" => {  # a NodeEntry, actually
    #      'id'              => "node1.example.com", # hostname
    #      'name'            => "node1", # for short
    #      'node_profile'    => "small", # node/gear profile
    #      'district_uuid'   => "2dfca730b863428da9af176160138651",
    #                       # or "NONE" if not in a district
    #      'district_active' => true, # node marked as active in district?
    #       # gear-based limits and usage, according to node facts
    #      'max_active_gears'    => 50,
    #      'gears_usage_pct'     => 200.0, # percentage of max_active_gears consumed
    #      'gears_active_usage_pct' => 40.0, # percentage of max_active_gears consumed
    #        # gear-based counts by state, according to node facts
    #      'gears_started_count' => 20,
    #      'gears_idle_count'    => 175,
    #      'gears_stopped_count' => 5,
    #      'gears_deploying_count' => 20, # in some part of create/update process
    #      'gears_unknown_count' => 0,  # state not one of the above, shouldn't happen
    #      'gears_total_count'   => 200,
    #      'gears_active_count'  => 20, # all gears except idle and stopped are "active"
    #      'gears_active_pct'    => 10.0, # percentage of total gears that are active
    #   },
    #   "node2.example.com" => ...
    # }
    detail_names = %w[
      node_profile district_uuid district_active
      max_active_gears gears_started_count
      gears_idle_count gears_stopped_count gears_deploying_count
      gears_unknown_count gears_total_count gears_active_count
      gears_usage_pct gears_active_usage_pct
    ]
    OpenShift::ApplicationContainerProxy.get_details_for_all(detail_names).each do |host,details|
      node = Admin::Stats::NodeEntry.new
      details.stringify_keys!
      # convert from strings to relevant values if needed
      %w{node_profile district_uuid}.each {|key| node[key] = details[key]}
      node['district_active'] = details['district_active'] == 'true' ? true : false
      %w{ max_active_gears gears_started_count
          gears_idle_count gears_stopped_count gears_deploying_count
          gears_unknown_count gears_total_count gears_active_count
        }.each {|key| node[key] = details[key].to_i}
      %w{gears_usage_pct gears_active_usage_pct
        }.each {|key| node[key] = details[key].to_f}
      node['gears_active_pct'] = (node['gears_total_count'] == 0) ? 100.0
           : 100.0 * node['gears_active_count'] / node['gears_total_count']

      # record that hash for this node host
      node['id'] = host
      node['name'] = host.split('.')[0]
      entry_for_node[host] = node
    end
    return entry_for_node
  end


  # get the district definitions from the DB
  def get_district_entries
    entry_for_district = {}
    # Which looks like:
    # {
    #   "2dfca730b863428da9af176160138651" => { # actually a DistrictEntry
    #        'profile'            => "small",        # gear profile (aka "size")
    #        'name'               => "small_district", #user-friendly name
    #        'uuid'               => "2dfca730b863428da9af176160138651", #unique ID
    #        'nodes' => {
    #                    "node1.example.com" => {'name' =>"node1.example.com", 'active' =>true},
    #                    "node2.example.com" => {'name' =>"node2.example.com", 'active' =>true}
    #                  },
    #        'district_capacity'   => 6000,   # configured number of gears allowed in this district
    #        'dist_avail_capacity' => 5967,   # district_capacity minus gears already allocated
    #        'dist_avail_uids'     => 5967,   # number of user ids left in the pool
    #   },
    #   "6e5d3ccc0bb1456399687c0be51676f8" => ...
    # }

    fields = %w[uuid name gear_size servers max_capacity available_capacity available_uids]
    with_each_record(:districts, {}, {:fields => fields }) do |dist|
      entry_for_district[dist['uuid'].to_s] = Admin::Stats::DistrictEntry.new.merge({
        'profile'             => dist['gear_size'],
        'name'                => dist['name'],
        'uuid'                => dist['uuid'].to_s,
        'nodes'               => district_nodes_clone(dist),
        'district_capacity'   => dist['max_capacity'],
        'dist_avail_capacity' => dist['available_capacity'],
        'dist_avail_uids'     => dist['available_uids'].length,
        'servers_by_region'   => servers_by_region(dist)
      })
    end
    return entry_for_district
  end

  def servers_by_region(district)
    result = {}
    district['servers'].each do |server|
      unless server['region_id'].nil?
        (result[server['region_id']] ||= []) << { 'name' => server['name'] }
      end
    end unless district['servers'].nil?
    return result
  end

  def get_region_entries
    entry_for_region = {}
    fields = %w[name]
    with_each_record(:regions, {}, {:fields => fields }) do |region|
      entry_for_region[region['_id']] = Admin::Stats::RegionEntry.new.merge({
        'name' => region['name']
      })
    end
    return entry_for_region
  end

  # perform a manual clone such that we don't get BSON entries
  def district_nodes_clone(district)
    cloned = {}
    district['servers'].each do |node|
      cloned[node['name']] = {
          'name' => node['name'],
          'active' => node['active']
      }
    end if district['servers']
    return cloned
  end

  def summarize_districts(entry_for_district, entry_for_node)
    # Returned hash with DistrictSummary values looks like:
    # {
    #   "2dfca730b863428da9af176160138651" => { # a DistrictSummary
    #         'uuid'               => "2dfca730b863428da9af176160138651", # unique ID for district
    #         'name'               => "small_district", # user-friendly name for district
    #         'profile'            => "small", # gear profile ("size") for district
    #         'nodes_count'        => 2,       # number of nodes responding in the district
    #         'nodes_active'       => 1,       # number of nodes marked "active" in district
    #         'nodes_inactive'     => 1,       # number of nodes marked inactive (not open for gear placement)
    #           # N.B. un-districted nodes are always considered inactive, though they can
    #           # have gears placed if there are no districts with capacity for the profile.
    #
    #         # the following are *district* capacity numbers:
    #         'district_capacity'   => 4000,    # configured number of gears allowed in this district
    #         'dist_avail_capacity' => 3967,    # district_capacity minus gears already allocated
    #         'dist_avail_uids'     => 5967,    # number of user ids left in the district 6000 uid pool
    #         'dist_usage_pct'      => 0.83, # percentage of district_capacity allocated
    #           # N.B. these are set to 0 for "NONE" districts (undistricted nodes)
    #
    #         # the following are capacity numbers according to responding nodes:
    #         'gears_started_count' => 20,
    #         'gears_idle_count'    => 175,
    #         'gears_stopped_count' => 5,
    #         'gears_deploying_count' => 20, # in some part of create/update process
    #         'gears_unknown_count' => 0,  # state not one of the above, shouldn't happen
    #         'gears_total_count'   => 200,
    #         'gears_active_count'  => 20, # gears not idled or stopped are "active"
    #         'gears_active_pct'    => 10.0, # percentage of total gears that are active
    #           # available capacity numbers
    #         'available_active_gears' => 173, # how many more active gears the nodes will support
    #         'effective_available_gears' => 173, # lower of available_active_gears, dist_avail_capacity
    #
    #         # min/max/average percent usage of active gear usage on nodes in this district:
    #         'lowest_active_usage_pct'  => 12.0,
    #         'highest_active_usage_pct' => 15.0,
    #         'avg_active_usage_pct'     => 13.5,
    #
    #         'nodes'=> [ array of entry_for_node values that are members of this district ]
    #
    #         'missing_nodes' => [ ids of node hosts for this district that did not respond ]
    #       },
    #   "6e5d3ccc0bb1456399687c0be51676f8" => { ... },
    #   ...
    # }

    # these are initial values, will accumulate as we go
    starter_stats = Hash[%w[
       nodes_count nodes_active gears_started_count nodes_inactive gears_idle_count
       gears_stopped_count gears_deploying_count gears_unknown_count gears_total_count
       gears_active_count avg_active_usage_pct
       available_active_gears available_active_gears_with_negatives effective_available_gears
    ].collect {|key| [key, 0]}]

    # may need a unique "NONE" district per profile for nodes that are not in a district
    none_district = Hash.new do |h,profile|
      h[profile] = Admin::Stats::DistrictSummary.new.merge({
        'name'    => "(NONE)",
        'uuid'    => "NONE profile=#{profile}",
        'profile' => profile,
        'district_capacity'   => 0,
        'dist_avail_capacity' => 0,
        'dist_avail_uids'     => 0,
        'nodes'               => [],
        'missing_nodes'       => {},
      }.merge starter_stats)
    end

    # hash to store the summaries per district
    summary_for_district = {}
    entry_for_district.each do |uuid,dist|
      summary_for_district[uuid] = Admin::Stats::DistrictSummary.new.
        merge(dist).merge(starter_stats).
        merge('missing_nodes' => dist['nodes'].clone, 'nodes' => [])
    end

    # We will drive this according to the nodes that responded.
    # There may be some that didn't respond, which won't be included.
    entry_for_node.each do |id,node|
      sum = summary_for_district[node['district_uuid']] ||
                   none_district[node['node_profile' ]]
      sum['nodes'] << node
      sum['missing_nodes'].delete id  # responded, so not missing
      sum['nodes_count'] += 1
      sum[ node['district_active'] ? 'nodes_active' : 'nodes_inactive'] += 1
      %w[ gears_started_count gears_idle_count gears_stopped_count gears_deploying_count
        gears_unknown_count gears_total_count gears_active_count
      ].each {|key| sum[key] += node[key]}
      # active gears can actually get higher than max; count that as 0 available, not negative
      available = [0, node['max_active_gears'] - node['gears_active_count']].max
      sum['available_active_gears'] += available
      sum['available_active_gears_with_negatives'] += node['max_active_gears'] - node['gears_active_count']
      sum['effective_available_gears'] += available if node['district_active'] ||
                                                      node['district_uuid'] == "NONE"
      sum['avg_active_usage_pct'] += node['gears_active_usage_pct']
    end

    none_district.values.each {|sum| summary_for_district[sum['uuid']] = sum}
    summary_for_district.each do |uuid,sum|
      sum['avg_active_usage_pct'] /= sum['nodes_count'] if sum['nodes_count'] > 0
      cap = sum['district_capacity']
      sum['dist_usage_pct'] = cap.zero? ? 0.0 : 100.0 - 100.0 * sum['dist_avail_capacity'] / cap
      sum['lowest_active_usage_pct'] = sum['nodes'].map{|node| node['gears_active_usage_pct']}.min || 0.0
      sum['highest_active_usage_pct'] = sum['nodes'].map{|node| node['gears_active_usage_pct']}.max || 0.0
      # effective gears available are limited by district capacity
      sum['effective_available_gears'] = [
        sum['effective_available_gears'],
        sum['dist_avail_capacity']
      ].min unless uuid =~ /^NONE/ # except in the NONE-district
      # convert 'missing' nodes to array
      sum['missing_nodes'] = sum['missing_nodes'].keys
      sum['gears_active_pct'] = (sum['gears_total_count'] == 0) ? 100.0
           : 100.0 * sum['gears_active_count'] / sum['gears_total_count']
    end
    return summary_for_district
  end

  def summarize_regions(entry_for_district, entry_for_region, entry_for_node)
    # these are initial values, will accumulate as we go
    starter_stats = Hash[%w[
       nodes_count nodes_active gears_started_count nodes_inactive gears_idle_count
       gears_stopped_count gears_deploying_count gears_unknown_count gears_total_count
       gears_active_count avg_active_usage_pct
       available_active_gears available_active_gears_with_negatives effective_available_gears
    ].collect {|key| [key, 0]}]

    # hash to store the summaries per region
    summary_for_region = {}
    entry_for_region.each do |id,region|
      summary_for_region[id] = Admin::Stats::RegionSummary.new.
        merge(region).merge(starter_stats).
        merge('missing_nodes' => {}, 'nodes' => [])
    end

    node_to_region = {}
    entry_for_district.each do |district_id,district|
      district['servers_by_region'].each do |region_id,servers|
        servers.each do |server|
          node_to_region[server['name']] = region_id
          summary_for_region[region_id]['missing_nodes'][server['name']] = server
        end
      end unless district['servers_by_region'].nil?
    end

    # We will drive this according to the nodes that responded.
    # There may be some that didn't respond, which won't be included.
    entry_for_node.each do |id,node|
      if node_to_region.has_key? id
        region_id = node_to_region[id]
        sum = summary_for_region[region_id]
        sum['nodes'] << node
        sum['missing_nodes'].delete id  # responded, so not missing
        sum['nodes_count'] += 1
        sum[ node['district_active'] ? 'nodes_active' : 'nodes_inactive'] += 1
        %w[ gears_started_count gears_idle_count gears_stopped_count gears_deploying_count
          gears_unknown_count gears_total_count gears_active_count
        ].each {|key| sum[key] += node[key]}
        # active gears can actually get higher than max; count that as 0 available, not negative
        available = [0, node['max_active_gears'] - node['gears_active_count']].max
        sum['available_active_gears'] += available
        sum['available_active_gears_with_negatives'] += node['max_active_gears'] - node['gears_active_count']
        sum['effective_available_gears'] += available if node['district_active']
        sum['avg_active_usage_pct'] += node['gears_active_usage_pct']
      end
    end

    summary_for_region.each do |region_id,sum|
      sum['avg_active_usage_pct'] /= sum['nodes_count'] if sum['nodes_count'] > 0
      sum['lowest_active_usage_pct'] = sum['nodes'].map{|node| node['gears_active_usage_pct']}.min || 0.0
      sum['highest_active_usage_pct'] = sum['nodes'].map{|node| node['gears_active_usage_pct']}.max || 0.0
      # convert 'missing' nodes to array
      # sum['missing_nodes'] = sum['missing_nodes'].keys
      sum['gears_active_pct'] = (sum['gears_total_count'] == 0) ? 100.0
           : 100.0 * sum['gears_active_count'] / sum['gears_total_count']
    end
    return summary_for_region
  end
  def summarize_profiles(summary_for_district, count_for_profile)
    # Returned hash with ProfileSummary values looks like: (a lot like the district summaries)
    # {
    #   "small" => { # ProfileSummary
    #      'profile'   => "small",
    #      'districts' => [ array of summaries from summary_of_district that have this profile ],
    #      'district_count' => 1, # number of districts with this profile (may include 1 "NONE" district)
    #      'nodes_count'        => 2,       # number of nodes responding with this profile
    #      'nodes_active'       => 1,       # number of nodes marked "active" with this profile
    #      'nodes_inactive'     => 1,       # number of nodes marked inactive (not open for gear placement)
    #        # N.B. un-districted nodes are always considered inactive, though they can
    #        # have gears placed if there are no districts with capacity for the profile.
    #      'missing_nodes' => [ ids of districted node hosts for this profile that did not respond ]
    #
    #      # the following are summarized *district* capacity numbers:
    #      'district_capacity'   => 4000,    # configured number of gears allowed in districts
    #      'dist_avail_capacity' => 3967,    # district_capacity minus gears already allocated
    #      'dist_avail_uids'     => 5967,    # number of user ids left in the districts' uid pool
    #      'highest_dist_usage_pct' => 15.0,
    #      'lowest_dist_usage_pct'  => 12.0,
    #      'avg_dist_usage_pct'     => 13.5,
    #        # N.B. these will be 0 for "NONE" districts (undistricted nodes)
    #
    #      # the following are usage/capacity numbers according to responding nodes:
    #      'gears_active_count'  => 20,
    #      'gears_idle_count'    => 175,
    #      'gears_stopped_count' => 5,
    #      'gears_unknown_count' => 0,  # state not one of the above, shouldn't happen
    #      'gears_total_count'   => 200,
    #      'gears_active_pct'    => 10.0, # percentage of total gears that are active
    #      'available_active_gears' => 173, # how many more active gears the nodes will support
    #
    #      # the following are usage numbers according to the DB, if collected
    #      'total_gears_in_db_records' => 27,  # gears recorded with this profile in the DB
    #      'total_apps'            => 20,  # apps recorded with this profile in the DB
    #      'cartridges'            => { cartridge counts as in get_db_stats }
    #      'cartridges_short'      => { cartridge short name counts as in get_db_stats }
    #
    #      # min/max/average percent usage of active gear capacity on nodes in this profile:
    #      'lowest_active_usage_pct'  => 12.0,
    #      'highest_active_usage_pct' => 15.0,
    #      'avg_active_usage_pct'     => 13.5,
    #   },
    #   "medium" => {...},
    #   ...
    # }
    #

    # these values will accumulate as we go
    starter_stats = Admin::Stats::ProfileSummary[ %w[
       nodes_count nodes_active nodes_inactive gears_active_count gears_idle_count
       gears_stopped_count gears_unknown_count gears_total_count available_active_gears available_active_gears_with_negatives
       effective_available_gears avg_active_usage_pct district_capacity
       dist_avail_capacity dist_avail_uids avg_dist_usage_pct
    ].collect {|key| [key, 0]}]
    summary_for_profile = Hash.new do |sum,p|
      sum[p] = starter_stats.merge({
        'profile' => p,
        'districts' => [],
        'missing_nodes' => [],
      })
    end
    summary_for_district.each do |uuid,dist|
      sum = summary_for_profile[dist['profile']]
      sum['districts'] << dist
      %w[ gears_active_count gears_idle_count gears_stopped_count gears_unknown_count
        gears_total_count available_active_gears available_active_gears_with_negatives effective_available_gears
        nodes_count nodes_active nodes_inactive missing_nodes district_capacity
        dist_avail_capacity dist_avail_uids
      ].each {|key| sum[key] += dist[key]}
      sum['avg_active_usage_pct'] += dist['avg_active_usage_pct'] * dist['nodes_count']
      sum['avg_dist_usage_pct'] += dist['dist_usage_pct']
    end
    summary_for_profile.each do |profile,sum|
      sum['district_count'] = sum['districts'].size
      sum['gears_active_pct'] = (sum['gears_total_count'] == 0) ? 100.0
           : 100.0 * sum['gears_active_count'] / sum['gears_total_count']
      sum['avg_active_usage_pct'] /= sum['nodes_count'] if sum['nodes_count'] > 0
      sum['lowest_active_usage_pct'] = sum['districts'].map{|d| d['lowest_active_usage_pct']}.min || 0.0
      sum['highest_active_usage_pct'] = sum['districts'].map{|d| d['highest_active_usage_pct']}.max || 0.0
      sum['avg_dist_usage_pct'] /= sum['district_count'] if sum['district_count'] > 0
      sum['lowest_dist_usage_pct'] = sum['districts'].map{|d| d['dist_usage_pct']}.min || 0.0
      sum['highest_dist_usage_pct'] = sum['districts'].map{|d| d['dist_usage_pct']}.max || 0.0
      if count_for_profile
        c = count_for_profile[profile]
        sum['total_gears_in_db_records'] = c['gears']
        sum['total_apps'] = c['apps']
        sum['cartridges'] = c['cartridges']
        sum['cartridges_short'] = c['cartridges_short']
        sum['gear_count_db_minus_node'] = c['gears'] - sum['gears_total_count']
      end
    end
    return summary_for_profile
  end

  # get statistics from the DB about users/apps/gears/cartridges
  def get_db_stats
    # initialize the things we will count for the entire installation
    count_all = Admin::Stats::DbSummary.new.merge({
        'apps' => 0,
        'gears' => 0,
        'cartridges' => Hash.new {|h,k| h[k] = 0},
        'cartridges_short' => Hash.new {|h,k| h[k] = 0},
        'users_with_num_apps' => Hash.new {|h,k| h[k] = 0},
        'users_with_num_gears' => Hash.new {|h,k| h[k] = 0},
      })
    # which ends up looking like:
    # { # A DbSummary
    #   'apps'  => 21,
    #   'gears' => 39,
    #   'cartridges'=> {
    #     "ruby-1.9"    => 5,
    #     "ruby-1.8"    => 7,
    #     "perl-5.10"   => 7,
    #     "mysql-5.1"   => 15,
    #     "haproxy-1.4" => 12,
    #     ...
    #   },
    #   'cartridges_short'=> {
    #     "ruby"    => 12,
    #     "perl"    => 7,
    #     "mysql"   => 15,
    #     "haproxy" => 12,
    #     ...
    #   },
    #   'users_with_num_apps' => {
    #     1 => 10,  # 10 users have 1 app
    #     2 => 2,
    #     9 => 1,
    #     ...
    #   },
    #   'users_with_num_gears' => {
    #     1 => 9,  # 9 users have 1 gear
    #     2 => 2,
    #     4 => 1,
    #     11 => 1,
    #     ...
    #   },
    # },

    count_for_profile = Hash.new do |hash,profile|
      hash[profile] = {
        'apps' => 0,
        'gears' => 0,
        'cartridges' => Hash.new {|h,k| h[k] = 0},
        'cartridges_short' => Hash.new {|h,k| h[k] = 0},
      }
    end
    # counts broken out by profile, which ends up looking like:
    # {
    #   "small"  => { hash like above without 'users_with_num_*' },
    #   "medium" => { ... },
    #   ...
    # }

    count_for_user = Hash.new do |hash,user|
      hash[user] = Hash.new {|h,k| h[k] = 0}
    end
    # which ends up looking like:
    # {
    #   "user1" => {'login' => "user1", 'small_gears' =>33, 'small_apps' =>18},
    #   "user2" => {'login' => "user2", 'medium_apps' =>1, 'medium_gears' =>2, 'small_gears' =>4, 'small_apps' =>2}
    #   ...
    # }
    #

    # read all user records and their logins from DB
    login_for_id = {}
    with_each_record(:cloud_users, {}, {:fields => %w[consumed_gears login], :timeout => false}) do |user|
      login_for_id[user["_id"]] = login = user["login"]
      count_for_user[login]['login'] = login # creates a count hash for every user
    end
    # read all domain records and map to user's hash of counts
    count_for_domain = {}
    with_each_record(:domains, {}, {:fields => ["owner_id"], :timeout => false}) do |domain|
      count_for_domain[domain["_id"]] = count_for_user[login_for_id[domain["owner_id"]]]
    end
    query = {"gears.0" => {"$exists" => true}}
    selection = {:fields => %w[
                             domain_id
                             default_gear_size
                             component_instances.cartridge_name
                             component_instances.group_instance_id
                             gears.group_instance_id
                             gears.server_identity
                            ], :timeout => false}
    with_each_record(:applications, query, selection) do |app|
      # record global stats
      count_all['apps'] += 1
      # record stats by gear profile (size)
      profile = app['default_gear_size']
      count_for_profile[profile]['apps'] += 1
      # record stats by user
      user_ct = count_for_domain[app['domain_id']] # per-domain=user counts
      user_ct["#{profile}_apps"] += 1
      user_ct['apps'] += 1
      # build hashes for the cartridges this app uses
      carts_for_group = Hash.new {|h,k| h[k] = []} # hash of arrays
      short_carts_for_group = Hash.new {|h,k| h[k] = []} # hash of arrays
      app['component_instances'].each do |comp|
        carts_for_group[gid = comp['group_instance_id']] << (cart = comp['cartridge_name'])
        # from "foo-bar-1.1" we want "foo-bar" for the short name
        cart.match(/^  ([-\w]+)  -  [\d.]+  $/x)
        short_carts_for_group[gid] << ($1 || cart)
      end
      # now walk the gears and count up everything.
      app['gears'].each do |gear|
        carts = carts_for_group[gear['group_instance_id']]
        short_carts = short_carts_for_group[gear['group_instance_id']]
        count_all['gears'] += 1
        # For now, we assume gear profile is same as app profile.
        # If that assumption becomes untrue, we can look up gear profile by
        # correlating with the server_identity's node profile.
        count_for_profile[profile]['gears'] += 1
        # account for the user's gear usage
        user_ct["#{profile}_gears"] += 1
        user_ct['gears'] += 1
        # for this gear, record the cartridges used in this group_instance
        carts.each do |cart|
          count_all['cartridges'][cart] += 1
          count_for_profile[profile]['cartridges'][cart] += 1
        end
        short_carts.each do |short|
          count_all['cartridges_short'][short] += 1
          count_for_profile[profile]['cartridges_short'][short] += 1
        end
      end
    end
    # sum distribution of apps/gears per user
    count_for_user.values.each do |user_ct|
      count_all['users_with_num_apps'][ user_ct['apps'] ] += 1
      count_all['users_with_num_gears'][user_ct['gears']] += 1
    end
    return count_all, count_for_profile, count_for_user
  end

  private

  def with_each_record(collection_name, query, selection, &block)
    OpenShift::DataStore.db.
      collection(collection_name).
      find(query, selection) do |mcursor|
        mcursor.each do |hash|
          block.call(hash)
        end
      end
  end

end #class Admin::Stats::Maker

