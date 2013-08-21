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
# This superclass is the entry point for performing various tests and
# returning relevant suggestions, which are all subclass instances.
# Subclasses contain testing logic and attributes specific to the
# particular type of suggestion being made.
#
module Admin
  class Suggestion

    # Actual suggestions are just value objects to be consumed by callers

    # String - profile affected
    attr_accessor :profile

    # String - district uuid to modify
    attr_accessor :district_uuid
    # String - name for same district
    attr_accessor :district_name

    # subclass instances just set attributes given
    def initialize(attrs)
      attrs.each_pair {|attr,value| self.send("#{attr}=", value)}
    end

    # log using Rails... for now
    module Logger
      def log_debug(msg); Rails.logger.debug(msg); end
      def log_info(msg); Rails.logger.info(msg); end
      def log_warn(msg); Rails.logger.warn(msg); end
      def log_error(msg); Rails.logger.error(msg); end
    end
    include Logger  #instance methods
    extend Logger   #class methods

    # Advisors are a parallel class heirarchy for generating suggestions.
    # This class executes .query(Params, Results, current_suggestions) on all
    # of its subclasses, expecting each to return a Container with any new
    # suggestions.
    class Advisor # sub-namespace but not sub-class
      extend Logger

      # Expected parameter:
      #   Params or hash of parameters for constructing Params
      # Returns:
      #   Container (Array) of subclass instances
      # Validates parameters and executes .query(Params, Results, current_suggestions)
      # on all subclasses (which must override this method)
      def self.query(p = Params.new, stats = nil)
        # if params are badly specified, let exceptions blow up
        p = Params.new(p) if !p.is_a? Params

        suggestions = Container.new
        # we want other errors to show up, but not totally halt generation
        begin
          # sanity test params
          suggestions += p.validate

          unless stats
            stats = Admin::Stats.new( wait: p.mcollective_timeout )
            stats.gather_statistics
            stats = stats.results
          end

          # run .query on subclass tree starting with these
          klasses = [ MissingNodes::Advisor,
                      Capacity::Add::Advisor,
                      Capacity::Remove::Advisor ] + self.descendants
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
    end

    # add some helper methods for an array of suggestions
    class Container < ::Array
      def +(add)  # need to return a Container - default morphs to Array
        add.each {|x| self << x}
        self
      end
      def for_general
        Container.new + select {|sugg| sugg.profile.nil?}
      end
      def for_profile(profile)
        Container.new + select {|sugg| sugg.profile == profile}
      end
      def for_district(uuid)
        Container.new + select {|sugg| sugg.district_uuid == uuid}
      end
      def group_by_profile
        inject(Hash.new) {|h,sugg| (h[sugg.profile] ||= Container.new) << sugg; h }
      end
      def group_by_district_uuid
        inject(Hash.new) {|h,sugg| (h[sugg.district_uuid] ||= Container.new) << sugg; h }
      end
      def group_by_class
        inject(Hash.new) {|h,sugg| (h[sugg.class] ||= Container.new) << sugg; h }
      end
    end

    ##################################################################
    #
    # Subclasses which are for specific types of suggestions
    #
    ##################################################################

    # missing nodes list as that may impact whether to actually take action
    class MissingNodes < Suggestion

      # array of names of missing nodes
      attr_accessor :nodes

      class Advisor < Suggestion::Advisor
        def self.query(params, stats, current_suggestions)
          suggestions = Container.new
          all = MissingNodes.new(nodes: [])
          profile_missing = {}
          district_missing = {}
          stats.profile_summaries_hash.each do |profile, psum|
            psum.districts.each do |dsum|
              next if dsum.missing_nodes.empty?
              profile_missing[profile] ||= MissingNodes.new(profile: profile,
                                                            nodes: [])
              district_missing[dsum.uuid] ||= MissingNodes.new( profile: profile,
                                                             district_uuid: dsum.uuid,
                                                             district_name: dsum.name,
                                                             nodes: [])
              profile_missing[profile].nodes += dsum.missing_nodes
              district_missing[dsum.uuid].nodes += dsum.missing_nodes
              all.nodes += dsum.missing_nodes
            end
          end
          suggestions << all unless profile_missing.empty?
          suggestions += profile_missing.values + district_missing.values
        end
      end
    end # MissingNodes

    # some error occurred during processing that wasn't anticipated
    class Error < Suggestion
        attr_accessor :error
        attr_accessor :stack
    end


  end
end
