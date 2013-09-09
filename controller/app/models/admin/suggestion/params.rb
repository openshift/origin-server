
require 'admin/suggestion/types'
module Admin
  module Suggestion
    # Class for Suggestion parameters
    #
    # dual purposes:
    # - validate parameters for suggestions
    # - logic to retrieve values per profile, referring to defaults as needed
    #
    class Params
      Admin::Suggestion::Advisor # ensure it's loaded
      extend Suggestion::Logger # defined in that :)
      include Suggestion::Logger

      def initialize(attrs = {})
        @attrs = {}
        raise "suggestion config should be a hash" unless attrs.respond_to?(:has_key?)
        attrs.deep_dup.each_pair {|attr,value| self.send("#{attr}=", value)}
      end

      # Expected attributes (all are optional):

      # Numeric mcollective timeout (seconds) for admin stats to override broker default
      attr_accessor :mcollective_timeout

      #   For all hashes, key :default specifies default.
      #   For thresholds, nil means don't suggest for that profile.
      #
      #   active_gear_pct: hash of 'profile => Int between 1..100 or nil
      #   - percentage of gears expected to be active (default 50)
      #   gear_up_threshold: hash of 'profile' => Int > 0 or nil
      #   - number of gears (per profile) that should be available;
      #     suggest capacity increase if there are fewer.
      #   gear_up_size: hash of 'profile' => Int > 0 or nil
      #   - number of gears (per profile) to add when capacity is needed (default 200)
      #   gear_down_threshold: hash of 'profile' => Int > 0 or nil
      #   - if this many gears are available (per profile),
      #     suggest removing a node.
      @@per_profile = [ :active_gear_pct, :gear_up_size,
                        :gear_up_threshold, :gear_down_threshold ]
      @@per_profile_default = { active_gear_pct: 50,
                                gear_up_size: 200} # and nil for others
      # Define accessors for the per-profile attributes that expect
      # a hash in and return a value from the hash per profile.
      # e.g.:
      # params.active_gear_pct = { default: 80 }
      # params.active_gear_pct('some_profile')
      #   => 80
      @@per_profile.each do |attr|
        define_method("#{attr}=") {|value| @attrs[attr] = value }
        define_method(attr, ->(profile=nil) { # stabby lambda for optional arg
          profile.nil? ? @attrs[attr].deep_dup  # return whole hash when no profile
                       : for_profile(@attrs[attr], attr, profile)
        })
      end

      #
      # sanity check the parameters, nil out any bogus ones
      #
      def validate
        suggestions = Container.new
        rconf = Rails.application.config.openshift
        #
        # per-profile values should be nil or hash of profile => number
        #   :default symbol may be specified
        #
        @@per_profile.each do |attr|
          val = @attrs[attr]
          if val.nil?
              log_debug "#{self.class}: no #{attr} set for Suggestion conf."
              next
          end
          unless val.respond_to?(:has_key?)
            log_error "#{self.class}: parameter #{attr} is not a hash:\n  #{val.inspect}"
            suggestions << Config::FixVal.new(name: attr, value: val.inspect)
            @attrs[attr] = nil
            next
          end
          #
          # check that values are valid for all profiles
          #
          ([:default] + rconf[:gear_sizes]).each do |profile|
            if val[profile].nil?
              log_debug "#{self.class}: no #{attr} set for profile #{profile}"
            elsif attr == :active_gear_pct && ! valid_active_pct?(val[profile])
              log_error "#{self.class}: #{attr} for profile #{profile} is not valid:\n" +
                        "  #{val.inspect}"
              suggestions << Config::FixVal.new(profile: profile,
                                                name: attr,
                                                value: val[profile].inspect)
            elsif ! valid_threshold?(val[profile])
              log_error "#{self.class}: #{attr} for profile #{profile} is not valid:\n" +
                        "  #{val.inspect}"
              suggestions << Config::FixVal.new(profile: profile,
                                                name: attr,
                                                value: val[profile].inspect)
              val[profile] = nil
              next
            end
          end
        end
        #
        # check that gear_down thresholds make sense compared to gear_up
        #
        rconf[:gear_sizes].each do |profile|
          up   = gear_up_threshold(profile)
          down = gear_down_threshold(profile)
          size = gear_up_size(profile)
          next if up.nil? || down.nil?
          log_error "#{self.class}: gear_up is larger than gear_down threshold" if up > down
          if up + size > down
            log_warn "#{self.class}: gear_down threshold #{down} should be at least gear_up_size #{size} greater than gear_up threshold #{up}"
            suggestions << Config::FixGearDown.new(profile: profile, up: up,
                                                   down: down, size: size)
          end
        end
        return suggestions
      end

      def self.test_instances
        profile = Advisor.test_profile
        Container.new +
          Config::FixVal.new(name: :active_gear_pct, value: ["bogus"].inspect) +
          Config::FixVal.new(profile: profile, name: :gear_up_threshold,
                             value: (-1).inspect) +
          Config::FixGearDown.new(profile: profile, up: 1000, down: 1200, size: 500)
      end

      private

      #
      # determine the configured value for the symbol and profile given
      #
      def for_profile(hash, symbol, profile)
        default = @@per_profile_default[symbol]
        return default if hash.nil?
        raise "param #{symbol} should be a hash" unless hash.respond_to?(:has_key?)
        val = hash.has_key?(profile) ? hash[profile]  # even if it's nil
                                     : hash[:default]
        return default if val.nil?
        return val.respond_to?(:to_i) ? val.to_i : default
      end

      def valid_threshold?(t)
        t.nil? || t.respond_to?(:to_i) && t.to_i > 0
      end
      def valid_active_pct?(p)
        p.nil? || p.respond_to?(:to_i) && p.to_i > 0 && p.to_i <= 100
      end
    end # Params
  end
end
