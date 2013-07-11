module AdminConsole
  class Profile
    def self.find(id)
      profiles = all
      profiles[id]
    end

    def self.all
      #TODO cache the profile summary data
      @db = OpenShift::DataStore.db
      @nodes = get_node_entries
      @entry_for_district = get_district_entries
      @summary_for_district = summarize_districts(@entry_for_district, @nodes)
      @summary_for_profile = summarize_profiles(@summary_for_district, nil)
    end

    protected
      def self.get_node_entries
        nodes = OpenShift::ApplicationContainerProxy.get_details_for_all %w[
          gears_usage_pct
          gears_active_usage_pct
          max_active_gears
          gears_started_count
          gears_idle_count
          gears_stopped_count
          gears_deploying_count
          gears_unknown_count
          gears_total_count
          gears_active_count
          node_profile
          district_uuid
          district_active
        ]
        nodes.each do |identity, facts|
          # convert from strings to relevant values if needed
          facts[:district_active] = facts[:district_active] == 'true' ? true : false
          %w{ max_active_gears gears_started_count
              gears_idle_count gears_stopped_count gears_deploying_count
              gears_unknown_count gears_total_count gears_active_count
            }.each {|fact| facts[fact.to_sym] = facts[fact.to_sym].to_i}
          %w{gears_usage_pct gears_active_usage_pct
            }.each {|fact| facts[fact.to_sym] = facts[fact.to_sym].to_f}
        end
      end

      # get the district definitions from the DB
      def self.get_district_entries
        entry_for_district = {}
        # Which looks like:
        # {
        #   "2dfca730b863428da9af176160138651" => {
        #        :profile            => "small",        # gear profile (aka "size")
        #        :name               => "small_district", #user-friendly name
        #        :uuid               => "2dfca730b863428da9af176160138651", #unique ID
        #        :nodes => {
        #                    "node1.example.com" => {:name =>"node1.example.com", :active =>true},
        #                    "node2.example.com" => {:name =>"node2.example.com", :active =>true}
        #                  },
        #        :district_capacity   => 6000,   # configured number of gears allowed in this district
        #        :dist_avail_capacity => 5967,   # district_capacity minus gears already allocated
        #        :dist_avail_uids     => 5967,   # number of user ids left in the pool
        #   },
        #   "6e5d3ccc0bb1456399687c0be51676f8" => ...
        # }

        fields = %w[uuid name gear_size server_identities max_capacity available_capacity available_uids]
        _with_each_record(:districts, {}, {:fields => fields }) do |dist|
          entry_for_district[dist['uuid']] = {
            :profile             => dist['gear_size'],
            :name                => dist['name'],
            :uuid                => dist['uuid'],
            :nodes               => district_nodes_clone(dist),
            :district_capacity   => dist['max_capacity'],
            :dist_avail_capacity => dist['available_capacity'],
            :dist_avail_uids     => dist['available_uids'].length,
          }
        end
        return entry_for_district
      end

      def self.summarize_districts(entry_for_district, entry_for_node)
        # Returned hash looks like:
        # {
        #   "2dfca730b863428da9af176160138651" => {
        #         :uuid               => "2dfca730b863428da9af176160138651", # unique ID for district
        #         :name               => "small_district", # user-friendly name for district
        #         :profile            => "small", # gear profile ("size") for district
        #         :nodes_count        => 2,       # number of nodes responding in the district
        #         :nodes_active       => 1,       # number of nodes marked "active" in district
        #         :nodes_inactive     => 1,       # number of nodes marked inactive (not open for gear placement)
        #           # N.B. un-districted nodes are always considered inactive, though they can
        #           # have gears placed if there are no districts with capacity for the profile.
        #
        #         # the following are *district* capacity numbers:
        #         :district_capacity   => 4000,    # configured number of gears allowed in this district
        #         :dist_avail_capacity => 3967,    # district_capacity minus gears already allocated
        #         :dist_avail_uids     => 5967,    # number of user ids left in the district 6000 uid pool
        #         :dist_usage_pct      => 0.83, # percentage of district_capacity allocated
        #           # N.B. these are set to 0 for "NONE" districts (undistricted nodes)
        #
        #         # the following are capacity numbers according to responding nodes:
        #         :gears_started_count => 20,
        #         :gears_idle_count    => 175,
        #         :gears_stopped_count => 5,
        #         :gears_deploying_count => 20, # in some part of create/update process
        #         :gears_unknown_count => 0,  # state not one of the above, shouldn't happen
        #         :gears_total_count   => 200,
        #         :gears_active_count  => 20, # gears not idled or stopped are "active"
        #           # available capacity numbers
        #         :available_active_gears => 173, # how many more active gears the nodes will support
        #         :effective_available_gears => 173, # lower of available_active_gears, dist_avail_capacity
        #
        #         # min/max/average percent usage of active gear usage on nodes in this district:
        #         :lowest_active_usage_pct  => 12.0,
        #         :highest_active_usage_pct => 15.0,
        #         :avg_active_usage_pct     => 13.5,
        #
        #         :nodes=> [ array of entry_for_node values that are members of this district ]
        #
        #         :missing_nodes => [ ids of node hosts for this district that did not respond ]
        #       },
        #   "6e5d3ccc0bb1456399687c0be51676f8" => { ... },
        #   ...
        # }

        # these are initial values, will accumulate as we go
        starter_stats = Hash[%w[
           nodes_count nodes_active gears_started_count nodes_inactive gears_idle_count
           gears_stopped_count gears_deploying_count gears_unknown_count gears_total_count
           gears_active_count available_active_gears avg_active_usage_pct
        ].collect {|key| [key.to_sym, 0]}]

        # may need a unique "NONE" district per profile for nodes that are not in a district
        none_district = Hash.new do |h,profile|
          h[profile] = {
            :name    => "(NONE)",
            :uuid    => "NONE profile=#{profile}",
            :profile => profile,
            :district_capacity   => 0,
            :dist_avail_capacity => 0,
            :dist_avail_uids     => 0,
            :nodes               => [],
            :missing_nodes       => {},
          }.merge starter_stats
        end

        # hash to store the summaries per district
        summary_for_district = {}
        entry_for_district.each do |uuid,dist|
          summary_for_district[uuid] = dist.merge(starter_stats).
            merge(:missing_nodes => dist[:nodes].clone, :nodes => [])
        end

        # We will drive this according to the nodes that responded.
        # There may be some that didn't respond, which won't be included.
        entry_for_node.each do |id,node|
          sum = summary_for_district[node[:district_uuid]] ||
                       none_district[node[:node_profile ]]
          sum[:nodes] << node
          sum[:missing_nodes].delete id  # responded, so not missing
          sum[:nodes_count] += 1
          sum[ node[:district_active] ? :nodes_active : :nodes_inactive] += 1
          [ :gears_started_count, :gears_idle_count, :gears_stopped_count, :gears_deploying_count,
            :gears_unknown_count, :gears_total_count, :gears_active_count
          ].each {|key| sum[key] += node[key]}
          # active gears can actually get higher than max; count that as 0 available, not negative
          sum[:available_active_gears] += [0, node[:max_active_gears] - node[:gears_active_count]].max
          sum[:avg_active_usage_pct] += node[:gears_active_usage_pct]
        end

        none_district.values.each {|sum| summary_for_district[sum[:uuid]] = sum}
        summary_for_district.each do |uuid,sum|
          sum[:avg_active_usage_pct] /= sum[:nodes_count] if sum[:nodes_count] > 0
          cap = sum[:district_capacity]
          sum[:dist_usage_pct] = cap.zero? ? 0.0 : 100.0 - 100.0 * sum[:dist_avail_capacity] / cap
          sum[:lowest_active_usage_pct] = sum[:nodes].map{|node| node[:gears_active_usage_pct]}.min || 0.0
          sum[:highest_active_usage_pct] = sum[:nodes].map{|node| node[:gears_active_usage_pct]}.max || 0.0
          # effective gears available are limited by district capacity
          sum[:effective_available_gears] = [sum[:available_active_gears], sum[:dist_avail_capacity]].min
          # convert :missing nodes to array
          sum[:missing_nodes] = sum[:missing_nodes].keys
        end
        return summary_for_district
      end

      def self.summarize_profiles(summary_for_district, count_for_profile)
        # Returned hash looks like: (a lot like the district summaries)
        # {
        #   "small" => {
        #      :profile   => "small",
        #      :districts => [ array of summaries from summary_of_district that have this profile ],
        #      :district_count => 1, # number of districts with this profile (may include 1 "NONE" district)
        #      :nodes_count        => 2,       # number of nodes responding with this profile
        #      :nodes_active       => 1,       # number of nodes marked "active" with this profile
        #      :nodes_inactive     => 1,       # number of nodes marked inactive (not open for gear placement)
        #        # N.B. un-districted nodes are always considered inactive, though they can
        #        # have gears placed if there are no districts with capacity for the profile.
        #      :missing_nodes => [ ids of districted node hosts for this profile that did not respond ]
        #
        #      # the following are summarized *district* capacity numbers:
        #      :district_capacity   => 4000,    # configured number of gears allowed in districts
        #      :dist_avail_capacity => 3967,    # district_capacity minus gears already allocated
        #      :dist_avail_uids     => 5967,    # number of user ids left in the districts' uid pool
        #      :highest_dist_usage_pct => 15.0,
        #      :lowest_dist_usage_pct  => 12.0,
        #      :avg_dist_usage_pct     => 13.5,
        #        # N.B. these will be 0 for "NONE" districts (undistricted nodes)
        #
        #      # the following are usage/capacity numbers according to responding nodes:
        #      :gears_active_count  => 20,
        #      :gears_idle_count    => 175,
        #      :gears_stopped_count => 5,
        #      :gears_unknown_count => 0,  # state not one of the above, shouldn't happen
        #      :gears_total_count   => 200,
        #      :available_active_gears => 173, # how many more active gears the nodes will support
        #
        #      # the following are usage numbers according to the DB, if collected
        #      :total_db_gears        => 27,  # gears recorded with this profile in the DB
        #      :total_apps            => 20,  # apps recorded with this profile in the DB
        #      :cartridges            => { cartridge counts as in get_db_stats }
        #      :cartridges_short      => { cartridge short name counts as in get_db_stats }
        #
        #      # min/max/average percent usage of active gear capacity on nodes in this profile:
        #      :lowest_active_usage_pct  => 12.0,
        #      :highest_active_usage_pct => 15.0,
        #      :avg_active_usage_pct     => 13.5,
        #   },
        #   "medium" => {...},
        #   ...
        # }
        #

        # these values will accumulate as we go
        starter_stats = Hash[ %w[
           nodes_count nodes_active nodes_inactive gears_active_count gears_idle_count
           gears_stopped_count gears_unknown_count gears_total_count available_active_gears
           effective_available_gears avg_active_usage_pct district_capacity
           dist_avail_capacity dist_avail_uids avg_dist_usage_pct
        ].collect {|key| [key.to_sym, 0]}]
        summary_for_profile = Hash.new do |sum,p|
          sum[p] = {
            :profile => p,
            :districts => [],
            :missing_nodes => [],
          }.merge starter_stats
        end
        summary_for_district.each do |uuid,dist|
          sum = summary_for_profile[dist[:profile]]
          sum[:districts] << dist
          [ :gears_active_count, :gears_idle_count, :gears_stopped_count, :gears_unknown_count,
            :gears_total_count, :available_active_gears, :effective_available_gears, :nodes_count,
            :nodes_active, :nodes_inactive, :missing_nodes, :district_capacity,
            :dist_avail_capacity, :dist_avail_uids
          ].each {|key| sum[key] += dist[key]}
          sum[:avg_active_usage_pct] += dist[:avg_active_usage_pct] * dist[:nodes_count]
          sum[:avg_dist_usage_pct] += dist[:dist_usage_pct]
        end
        summary_for_profile.each do |profile,sum|
          sum[:district_count] = sum[:districts].size
          sum[:avg_active_usage_pct] /= sum[:nodes_count] if sum[:nodes_count] > 0
          sum[:lowest_active_usage_pct] = sum[:districts].map{|d| d[:lowest_active_usage_pct]}.min || 0.0
          sum[:highest_active_usage_pct] = sum[:districts].map{|d| d[:highest_active_usage_pct]}.max || 0.0
          sum[:avg_dist_usage_pct] /= sum[:district_count] if sum[:district_count] > 0
          sum[:lowest_dist_usage_pct] = sum[:districts].map{|d| d[:dist_usage_pct]}.min || 0.0
          sum[:highest_dist_usage_pct] = sum[:districts].map{|d| d[:dist_usage_pct]}.max || 0.0
          if count_for_profile
            c = count_for_profile[profile]
            sum[:total_gears_in_db_records] = c[:gears]
            sum[:total_apps] = c[:apps]
            sum[:cartridges] = c[:cartridges]
            sum[:cartridges_short] = c[:cartridges_short]
            sum[:gear_count_db_minus_node] = c[:gears] - sum[:gears_total_count]
          end
        end
        return summary_for_profile
      end

      def self._with_each_record(collection_name, query, selection)
        coll = @db.collection(collection_name)
        coll.find(query, selection) do |mcursor|
          mcursor.each do |hash|
            yield hash
          end
        end
      end
  end
end
