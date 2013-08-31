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

require 'admin/suggestion/types'

#
# This superclass is the entry point for performing various tests and
# returning relevant suggestions (Admin::Suggestion::Base subclass instances).
# Subclasses contain testing logic specific to the particular type of
# suggestion being made.
#
module Admin
  module Suggestion
    # log using Rails... for now
    module Logger
      def log_debug(msg); Rails.logger.debug(msg); end
      def log_info(msg); Rails.logger.info(msg); end
      def log_warn(msg); Rails.logger.warn(msg); end
      def log_error(msg); Rails.logger.error(msg); end
    end

    # Advisors are a class heirarchy for generating suggestions.
    # This class executes .query(Params, Results, current_suggestions) on all
    # of its subclasses, expecting each to return a Container with any new
    # suggestions.
    class Advisor
      extend Logger
      include Logger

      # Expected parameter:
      #   Params or hash of parameters for constructing Params
      # Returns:
      #   Container (Array) of subclass instances
      # Validates parameters and executes .query(Params, Results, current_suggestions)
      # on all subclasses (which must override this method)
      def self.query(p = nil, stats = nil)
        # if params are badly specified, let exceptions blow up
        p = Params.new(p || {}) if !p.is_a? Params

        suggestions = Container.new
        # we want other errors to show up, but not totally halt generation
        begin
          # sanity test params
          suggestions += p.validate

          unless stats
            stats = Admin::Stats::Maker.new( wait: p.mcollective_timeout )
            stats.gather_statistics
            stats = stats.results
          end

          # run .query on subclass tree starting with these
          klasses = [ Advisor::MissingNodes,
                      Advisor::Capacity::Add,
                      Advisor::Capacity::Remove] + self.descendants
          klasses.uniq.each do |klass|
            begin
              suggestions += klass.query(p, stats, suggestions)
            rescue StandardError
              suggestions << Error.new(error: $!, stack: $!.backtrace)
            end
          end
        rescue StandardError
          suggestions << Error.new(error: $!, stack: $!.backtrace)
        end
        suggestions
      end

      # have all descendants generate representative test instances
      # for display/test purposes.
      def self.subclass_test_instances
        sugs = self.descendants.inject(Container.new) do |c,klass|
            klass.respond_to?(:test_instances) ? c += klass.test_instances : c
        end
        e = StandardError.new("test error")
        sugs += Suggestion::Base.new(scope: "general", profile: test_profile)
        sugs += Suggestion::Error.new(scope: "general", error: e, stack: caller)
        sugs += Params.test_instances
        Container.new +  # sort by one from each class first.
          sugs.group_by_class.values.inject([]) do |c,arr|
            c += arr.each_with_index.map {|s,i| [s,i]}
          end.sort_by {|s| [s[1], s[0].class.to_s]}.map {|s| s[0]}
      end
      def self.test_profile
        Rails.application.config.openshift[:gear_sizes].first
      end

      class MissingNodes < Suggestion::Advisor
        MN = Admin::Suggestion::MissingNodes # not to be confused with the Advisor
        def self.query(params, stats, current_suggestions)
          suggestions = Container.new
          all = MN.new(nodes: [], scope: "general", contents: Container.new)
          profile_missing = {}
          district_missing = {}
          stats.profile_summaries_hash.each do |profile, psum|
            psum.districts.each do |dsum|
              next if dsum.missing_nodes.empty?
              profile_missing[profile] ||= MN.new(profile: profile, nodes: [])
              district_missing[dsum.uuid] = MN.new(profile: profile, nodes: [],
                                                   scope: "district",
                                                   district_uuid: dsum.uuid,
                                                   district_name: dsum.name)
              profile_missing[profile].nodes += dsum.missing_nodes
              district_missing[dsum.uuid].nodes += dsum.missing_nodes
              all.nodes += dsum.missing_nodes
            end
          end
          if ! profile_missing.empty?
            suggestions << all
            all.contents += profile_missing.values + district_missing.values
          end
          suggestions
        end

        def self.test_instances
          # simple - one node missing
          profile = self.test_profile
          nodes = [ "missing.example.com" ]
          all1 = MN.new(contents: Container.new, scope:"general", nodes: nodes)
          all1.contents << MN.new(profile: profile, nodes: nodes.clone)
          all1.contents << MN.new(scope: "district", nodes: nodes.clone,
                                  profile: profile,
                                  district_uuid: "test_dist_uuid",
                                  district_name: "test_dist")
          # more complicated - several nodes missing across profiles and districts
          nodes = (1..3).map {|n| "missing#{n}.example.com" }
          all2 = MN.new(contents: all1.contents.clone, scope:"general",
                                  nodes: all1.nodes + nodes)
          profile = self.test_profile + "2"
          all2.contents << MN.new(profile: profile, nodes: nodes.clone)
          all2.contents << MN.new(scope: "district", nodes: [nodes[0]],
                                  profile: profile,
                                  district_uuid: "test_dist_uuid1",
                                  district_name: "test_dist1")
          all2.contents << MN.new(scope: "district", nodes: [nodes[1], nodes[2]],
                                  profile: profile,
                                  district_uuid: "test_dist_uuid2",
                                  district_name: "test_dist2")
          Container.new + [all1, all2]
        end

      end # MissingNodes
    end # Advisor
  end # Suggestion
end # Admin

# ensure known advisor subclasses are loaded at runtime by adding on here:
Admin::Suggestion::Advisor::Capacity
