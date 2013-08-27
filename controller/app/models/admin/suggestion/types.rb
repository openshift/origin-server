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

#
# Suggestion::Base and subclasses define attributes specific to the
# particular type of suggestion being made.
#
module Admin
  module Suggestion
    class Base

      # Actual suggestions are just value objects to be consumed by callers

      # String - profile affected
      attr_accessor :profile

      # String - scope at which this suggestion applies.
      # One of: general, profile, district, node
      attr_accessor :scope

      # String - district uuid to modify
      attr_accessor :district_uuid
      # String - name for same district
      attr_accessor :district_name

      require 'digest/md5'
      # "ID" that should be unique across serialization or regeneration of the
      # suggestion - subclasses should override as needed,
      # or just specify instance variable names not to include in the hash.
      def id(*ignore_vars)
        Digest::MD5.hexdigest(self.class.to_s +
                              (self.instance_variables - ignore_vars).sort.
                              map {|v| "#{v}=#{self.instance_variable_get v}" }.join)
      end

      # subclass instances just set attributes given
      def initialize(attrs)
        attrs[:scope] ||= "profile" # most common
        attrs.each_pair {|attr,value| self.send("#{attr}=", value)}
      end

      def self.important?
        false
      end
      def important?
        self.class.important?
      end

    end

    ##################################################################
    #
    # Subclasses which are for specific types of suggestions
    #
    ##################################################################

    # Missing nodes list as that may impact whether to actually take action.
    # Each district with missing nodes gets its own district-scoped suggestion.
    # These are rolled up into a profile-scope suggestion.
    # These are rolled up into a single general-scope suggestion.
    # So, one missing node means three suggestions with different scope.
    class MissingNodes < Suggestion::Base

      def self.important?; true; end
      def id; super(:@contents); end

      # array of names of missing nodes
      attr_accessor :nodes

      # Container of rolled up suggestions underneath this scope.
      attr_accessor :contents

    end # MissingNodes

    # some error occurred during processing that wasn't anticipated
    class Error < Suggestion::Base
      attr_accessor :error
      attr_accessor :stack
      def id; super(:@stack); end
    end


    module Capacity
      class Add < Suggestion::Base

        # adding capacity is generally "important"
        # removing, not so much.
        def self.important?; true; end
        def id; super(:@contents); end

        # shared properies of these suggestions
        attr_accessor :contents # Container for suggestions that roll up into one add

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
      end # Add
      class Remove < Suggestion::Base
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
      end
    end # Capacity

    #
    # Config suggestions: something about the conf parameters missing or wrong
    #
    class Config < Suggestion::Base

      def self.important?; true; end
      #
      # A value is invalid.
      #
      class FixVal <  Config
        # attrs -
        #   profile: string or :default or nil

        #   :gear_up_threshold, :gear_down_threshold, or :active_gear_pct
        attr_accessor :name

        #   string representation of offending value
        attr_accessor :value
      end

      #
      # :gear_down_threshold too low compared to :gear_up_threshold
      # (this would lead to competing scale up/down suggestions)
      #
      class FixGearDown < Config
        # attrs -
        #   profile: string or :default or nil

        #   up: integer threshold
        attr_accessor :up

        #   down: integer threshold
        attr_accessor :down

        #   size: integer number of gears
        #   - down should be at least this much larger than up
        attr_accessor :size
      end

      #
      # Value not supplied - suggest doing that
      #
      class SupplyValue < Config
        # attrs -
        #   profile: string or nil

        #   :gear_up_threshold, :gear_down_threshold, or :active_gear_pct
        attr_accessor :name
      end
    end # Config

  end
end
