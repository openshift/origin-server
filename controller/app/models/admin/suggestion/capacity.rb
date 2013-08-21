#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module Admin
  class Suggestion
    class Capacity < Suggestion
      MAX_DISTRICT_GEARS = 6000 # today's hard limit

      module Util # to be extended into advisors as needed
        # Nodes in a profile can theoretically have different sizes.
        # For the current implementation, we just look at the nodes in the
        # profile now and assume the largest max_active_gears is
        # representative of the profile. If there are no nodes, arbitrarily
        # return 100.
        #
        def node_capacity_in_profile(psummary)
          psummary.districts.
            inject([]) {|nodes,dist| nodes += dist.nodes}.
            map {|node| node.max_active_gears}.max || 100
        end

        # If a district or profile has a significant number of gears,
        # check whether its actual active gear percent is lower than expected,
        # and adjust if so to keep from putting too many nodes in it.
        #
        def adjusted_active_pct(summary, node_capacity, active_gear_pct)
          if summary.gears_total_count > node_capacity # sample size large enough
            est_active_pct = [1, summary.gears_active_pct.floor].max
            # always estimate low so as not to overfill districts
            active_gear_pct = [active_gear_pct, est_active_pct].min
          end
          active_gear_pct
        end

        # Suggest the number of nodes a district should have.
        # Lower active_gear_pct means we expect more total gears on each node,
        # so fewer nodes should be created in the district.
        #
        def suggested_nodes_per_district(node_capacity, active_gear_pct)
          # note that integer division gets us the floor value
          max = MAX_DISTRICT_GEARS * active_gear_pct / (100 * node_capacity)
          max = 2 if max < 2 # should always at least have 2 to enable balancing
          max
        end

        # Decide how many nodes an existing district can add, given how
        # big nodes are and the expected percentage of gears that stay active.
        #
        def nodes_district_can_accept(dsum, node_capacity, active_gear_pct)
          # If a district is already idling more than expected, project using
          # its actual active_gear_pct
          active_gear_pct = adjusted_active_pct(dsum, node_capacity, active_gear_pct)
          max_nodes = suggested_nodes_per_district(node_capacity, active_gear_pct)
          return max_nodes if dsum.nodes.empty?
          return [0, max_nodes - dsum.nodes.size].max # avoid negative :)
        end
      end

      class Add < Capacity
        # shared properies of these suggestions

        # why add? because available < threshold
        attr_accessor :threshold # configured for the profile
        # current active available for the profile (limited by district capacity)
        attr_accessor :available_gears

        attr_accessor :active_gear_pct # for the profile - may have been adjusted
        attr_accessor :max_active_gears # for the profile - largest node
        attr_accessor :gears_needed # total gears that were to be added to profile
        attr_accessor :nodes_needed # total nodes that were to be added to profile
        attr_accessor :node_quantity # nodes to add with this suggestion
        attr_accessor :nodes_creatable # could have created in existing districts
        # recommend adding node to a particular district (could be new district)
        class Node < Add
          # Which district to add to - or nil if profile is undistricted
          # attr_accessor :district_name  # inherited - district name
          # attr_accessor :district_uuid # also inherited
          # Why the particular district? because given active_gear_pct, it was
          # the one that could best handle the new capacity. This may have been
          # adjusted per current district contents.
          #attr_accessor :district_active_gear_pct # calculate if we care
        end

        # recommend adding district and two nodes for it.
        class District < Add
          # why not use an existing district? given current usage and
          # expected active percentage, existing districts would be
          # overly full with another node.
          # so, create this many districts...
          attr_accessor :district_quantity
          # we estimate each district can handle this many nodes:
          attr_accessor :district_nodes_target
          # ...but start out each with this many nodes (about half)
          attr_accessor :nodes_per_district
        end

        class Advisor < Suggestion::Advisor
          extend Capacity::Util
          #
          # decide if a profile needs more capacity based on params
          #
          def self.query(params, stats, current_suggestions)
            suggestions = Container.new
            stats.profile_summaries_hash.each do |profile,summary|
              threshold = params.gear_up_threshold(profile)
              next if threshold.nil? # don't suggest for this profile
              if summary.effective_available_gears < threshold
                # profile needs more active capacity
                suggestions += add_capacity(summary, params)
              end
            end
            return suggestions
          end

          #
          # build suggestions for adding capacity to a profile based on params
          #
          # Returns: array of Capacity::Add subclasses
          #
          def self.add_capacity(psum, params)
            suggestions = Container.new
            profile = psum.profile
            node_capacity = node_capacity_in_profile(psum)
            active_gear_pct = params.active_gear_pct(profile)
            active_gear_pct = adjusted_active_pct(psum, node_capacity, active_gear_pct)
            # hash used to build the attributes for suggestions; since those
            # are mainly details on how we decided on a suggestion, it is also
            # convenient to store parameters in as we go along.
            s = { profile: profile,
                  active_gear_pct: active_gear_pct,
                  available_gears: psum.effective_available_gears,
                  threshold: params.gear_up_threshold(profile),
                  max_active_gears: node_capacity,
                }
            s[:gears_needed] = [ params.gear_up_size(profile),
                                 s[:threshold] - s[:available_gears]
                               ].max
            s[:nodes_needed] = (1.0 * s[:gears_needed] / node_capacity).ceil

            # if no districts, just add undistricted nodes as needed
            if psum.district_count == 1 && psum.district_capacity == 0
              s[:node_quantity] = s[:nodes_needed]
              return suggestions << Add::Node.new(s)
            end

            # figure out where we have space in current districts and how much
            open_dists = districts_with_space(psum.districts,
                                              node_capacity, active_gear_pct)
            s[:nodes_creatable] = open_dists.inject(0) {|sum,dist| sum += dist.space}

            # if existing districts lack the space, create new district(s)
            nodes_still_needed = s[:nodes_needed]
            if s[:nodes_creatable] < s[:nodes_needed]
              suggestions << (suggestion = add_district(s))
              nodes_still_needed -= suggestion.node_quantity
            end

            # now fill remaining need from existing districts
            suggestions += add_node(s, open_dists, nodes_still_needed)

            return suggestions
          end

          #
          # figure out where we have space in current districts and how much
          #
          # Returns: Array of filtered district summaries
          #
          def self.districts_with_space(dists, node_capacity, active_gear_pct)
            dists.select do |d|
              d[:space] = nodes_district_can_accept(d, node_capacity, active_gear_pct)
              d.space > 0 && d.missing_nodes.size == 0 # exclude if missing nodes
            end
          end

          #
          # Recommend adding new district or districts
          #
          # Returns: Add::District
          #
          def self.add_district(s)
            # First, decide how many nodes a new district would take...
            target_nodes = suggested_nodes_per_district(s[:max_active_gears],
                                                        s[:active_gear_pct])
            nodes_per = target_nodes / 2 # only add half of target to begin with,
            nodes_per = [s[:nodes_needed], nodes_per].min # but not more than we need,
            nodes_per = [2, nodes_per].max #... and at least 2

            # Then, decide how many districts of that size to suggest.
            d_quantity = 0
            d_quantity += 1 until d_quantity * nodes_per >=
                                  s[:nodes_needed] - s[:nodes_creatable]
            # Finally, create the suggestion for that.
            return Add::District.new(
              s.merge( district_quantity: d_quantity,
                       nodes_per_district: nodes_per,
                       node_quantity: nodes_per * d_quantity,
                       district_nodes_target: target_nodes,
              ))
          end

          #
          # Recommend adding new node or nodes to district(s)
          #
          # Returns: array of Add::Node
          #
          def self.add_node(s, open_dists, nodes_needed)
            sug_for_dist = {}
            while nodes_needed > 0 && !open_dists.empty?
              # add one in each existing district until we have enough.
              # start with the ones with the fewest nodes.
              open_dists.sort_by {|dist| dist.nodes.size}.each do |dist|
                sug = sug_for_dist[dist.uuid] ||= Add::Node.new(
                  s.merge district_name: dist.name, district_uuid: dist.uuid,
                          node_quantity: 0)
                dist[:space] -= 1
                sug.node_quantity += 1
                nodes_needed -= 1
                break if nodes_needed == 0
              end
              open_dists = open_dists.select {|dist| dist.space > 0}
            end
            sug_for_dist.values
          end

        end # Capacity::Add::Advisor
      end # Add

      # too much capacity, recommend removing at least one node
      class Remove < Capacity

        # past the gear-down threshold - remove capacity
        class Node < Remove
          # Note: for now, we will not specify specific nodes to be removed,
          # or which district to remove them from. So, no district_* will be set.

          # Active gear capacity available for profile - not limited by the
          # district capacity, because we would especially like to remove capacity
          # limited by that too.
          attr_accessor :available_gears

          attr_accessor :threshold        # gear_down_threshold for profile
          attr_accessor :max_active_gears # guess for node capacity in profile
          attr_accessor :nodes_to_remove  # nodes of that size to remove
        end

        # district maxed out - suggest repurposing/removing most idle node(s)
        class CompactDistrict < Remove
          attr_accessor :node_names # array of node hostnames to be removed

          # we use the smallest node to estimate what how many nodes should go
          # in the district - this makes it generous so we don't recommend
          # compacting just because one node is larger; OTOH we may refrain from
          # recommending compacting just because one node is smaller. What can
          # ya do? Better if all nodes are the same size:
          attr_accessor :max_active_gears

          attr_accessor :active_gear_pct # for this district
          attr_accessor :node_target # max nodes this district should have

          # available capacity in this node that could never be used because
          # it is too full of inactive gears.
          attr_accessor :excess_gears
        end

        class Advisor < Suggestion::Advisor
          extend Capacity::Util
          def self.query(params, stats, current_suggestions)

            # suggest compacting districts as needed
            suggestions = compact_districts(params, stats)

            # suggest removing any extra nodes
            stats.profile_summaries_hash.each do |profile,summary|
              # It is too complex to figure out where to remove nodes in
              # addition to compacting. So, hold off if compaction is
              # already suggested for this profile.
              next if !suggestions.for_profile(profile).empty?
              suggestions += remove_nodes_from_profile(params, summary)
            end
            suggestions
          end

          def self.compact_districts(params, stats)
            compact_district = {}
            stats.district_summaries.each do |dsum|
              next if !dsum.missing_nodes.empty? # missing nodes throw off calculations
              next if dsum.district_capacity == 0 # exclude the NONE district

              # smallest node in this district; keep in mind they could vary!
              max_active_gears = dsum.nodes.map {|node| node.max_active_gears}.min || 100
              # active gear pct in this district
              active_gear_pct = adjusted_active_pct(dsum, max_active_gears, 100)
              # how many nodes we should have based on above (being generous)
              node_target = suggested_nodes_per_district(max_active_gears,
                                                         active_gear_pct)
              # active capacity that will never be used
              excess_gears = dsum.available_active_gears - dsum.dist_avail_capacity
              if dsum.nodes.size > node_target && excess_gears > max_active_gears
                # compacting is advised; pick out least-used nodes to remove
                remaining_nodes = dsum.nodes.clone
                c_excess_gears = excess_gears # keep track as nodes removed
                d_avail_active = dsum.available_active_gears # likewise
                while c_excess_gears > max_active_gears &&
                      remaining_nodes.size > node_target
                  found_one = false
                  remaining_nodes.sort_by! do |node|
                    # put inactive nodes first in consideration for removal;
                    # then prefer those with the least gears to move
                    [(node.district_active ? 1 : 0), node.gears_total_count ]
                  end.select! do |node|
                    keep = true
                    node_cap = [0, node.max_active_gears - node.gears_active_count].max
                    if d_avail_active - node_cap > node.gears_active_count
                      # active gears on this node won't overwhelm remaining nodes
                      keep = false
                      found_one = true
                      c_excess_gears -= node_cap
                      d_avail_active -= node_cap
                      compact_district[dsum.uuid] ||= Remove::CompactDistrict.new(
                        profile: dsum.profile,
                        district_uuid: dsum.uuid,
                        district_name: dsum.name,
                        node_names: [],
                        max_active_gears: max_active_gears,
                        active_gear_pct: active_gear_pct,
                        node_target: node_target,
                        excess_gears: excess_gears,
                      )
                      compact_district[dsum.uuid].node_names << node.id
                      break if max_active_gears >= c_excess_gears
                    end
                    keep
                  end
                  break unless found_one # couldn't reduce any further
                end
              end
            end # each district
            Container.new + compact_district.values
          end

          def self.remove_nodes_from_profile(params, psum)
            down = params.gear_down_threshold(psum.profile)
            avail = psum.available_active_gears
            return [] unless down && avail > down
            # TODO: pick out specific nodes that would be best to remove
            gears_to_rm = avail - down
            rm = Remove::Node.new(
                        profile: psum.profile,
                        available_gears: avail,
                        threshold: down,
                        max_active_gears: node_capacity_in_profile(psum),
                        nodes_to_remove: 0,
                   )
            rm.nodes_to_remove += 1 until gears_to_rm <=
                                          rm.max_active_gears * rm.nodes_to_remove
            return [ rm ]
          end
        end # A:S:C:R:Advisor

      end # A:S:C:Remove
    end # A:S:Capacity
  end
end
