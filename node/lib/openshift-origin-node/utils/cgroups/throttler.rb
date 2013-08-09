#!/usr/bin/env oo-ruby

require 'active_support/core_ext/numeric/time'
require 'openshift-origin-node/utils/cgroups'
require 'syslog'
require_relative 'monitored_gear'

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class Throttler

          attr_reader :wanted_keys, :uuids, :running_apps, :threshold, :interval

          @@conf_file = '/etc/openshift/resource_limits.conf'

          def initialize
            # Make sure we create a MonitoredGear for the root OpenShift cgroup
            # Keys for information we want from cgroups
            @wanted_keys = %w(usage throttled_time nr_periods cfs_quota_us).map(&:to_sym)
            # Allow us to synchronize destructive operations to @running_apps
            @mutex = Mutex.new
            @uuids = []

            throttler_config = ::OpenShift::Runtime::Utils::Cgroups::Config.new(@@conf_file).get_group('cg_template_throttled')

            # Set the interval to save
            @interval = throttler_config.get('apply_period').to_i rescue nil
            # The threshold to query against
            @threshold = throttler_config.get('apply_threshold').to_i rescue nil

            raise ArgumentError, "#{@@conf_file} requires 'apply_period' in '[cg_template_throttled]' group" if @interval.nil?
            raise ArgumentError, "#{@@conf_file} requires 'apply_threshold' in '[cg_template_throttled]' group" if @threshold.nil?

            MonitoredGear.intervals = [@interval]

            # Allow us to lazy initialize MonitoredGears
            @running_apps = Hash.new do |h,uuid|
              h[uuid] = MonitoredGear.new(uuid)
            end

            Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?
            Syslog.info("Starting throttler => threshold: #{@threshold.to_f}%%/#{@interval}s, check_interval: #{MonitoredGear.delay}")

            # Start our collector thread
            start
          end

          def start
            Thread.new do
              loop do
                tick
                sleep MonitoredGear.delay
              end
            end
          end

          def tick
            vals = Libcgroup.usage
            vals = Hash[vals.map{|uuid,hash| [uuid,hash.select{|k,v| wanted_keys.include?k}]}]

            update(vals)
          end

          # Update our MonitoredGears based on new data
          def update(vals)
            # Synchronize this in case uuids are deleted
            @mutex.synchronize do
              _uuids = uuids
              threads = vals.select{|k,v| _uuids.include?(k) }.map do |uuid,data|
                Thread.new do
                  begin
                    @running_apps[uuid].update(data)
                  rescue ArgumentError
                    # Sometimes we enter a race condition with app creation/deletion
                    # This will cause the MonitoredGear object to not be created
                    # We can ignore this error and retry it next time
                  end
                end
              end
              threads.map(&:join)
            end
          end

          # Update the list of uuids
          # Synchronize this in case we remove applications in the middle of an update
          def uuids=(new_uuids)
            @mutex.synchronize do
              # Set the uuids of running gears
              @uuids = new_uuids
              # Delete any missing gears to free up memory
              @running_apps.select!{|k,v| uuids.include?(k) }
            end
          end

          def utilization(apps = running_apps)
            utilization = {}
            @mutex.synchronize do
              threads = apps.map do |k,v|
                Thread.new do
                  utilization[k] = v.utilization
                end
              end
              threads.map(&:join)
            end
            Hash[utilization.sort]
          end

          def find(options)
            apps = running_apps.clone

            cur_util = utilization
            if (usage = options[:usage])
              period = options[:period] || MonitoredGear.intervals.first
              # Find any utilization values with the correct period
              with_period = cur_util.inject({}) do |h,(k,v)|
                if (vals = (v.find{|k,v| k == period} || []).last)
                  h[k] = vals
                end
                h
              end
              # Find any gears over the threshold
              over_usage = with_period.select do |k,v|
                v[:usage_percent] >= usage
              end.keys
              apps.select!{|k,v| over_usage.include?(k) }
            end

            if (state = options[:state])
              apps.select! do |k,v|
                begin
                  v.gear.profile == state
                rescue RuntimeError
                  # There's the possibility that this gear no longer exists, so just ignore it
                  false
                end
              end
            end
            # Return current utilization with the apps for logging
            [apps, cur_util]
          end

          def throttle(args)
            (@bad_gears, cur_util) = find(args)
            # If this is our first run, make sure we find any previously throttled gears
            # NOTE: There is a corner case where we won't find non-running throttled applications
            @old_bad_gears ||= find(state: :throttled).first

            apply_action({
              :restore => @old_bad_gears,
              :throttle => @bad_gears,
            }, cur_util)
          end

          def apply_action(hash, cur_util)
            util = cur_util.inject({}) do |h,(uuid,vals)|
              h[uuid] = (vals.map{|k,v| v[:usage_percent] }.first || '???')
              h
            end

            hash.each do |action, gears|
              gears.each do |uuid, g|
                begin
                  case action
                  when :throttle
                    if @old_bad_gears.has_key?(uuid)
                      log_action("REFUSED #{action}", uuid, "gear already throttled", :warning)
                      next
                    elsif g.gear.boosted?
                      log_action("REFUSED #{action}", uuid, "gear is boosted", :warning)
                      next
                    end
                  when :restore
                    if @bad_gears.has_key?(uuid)
                      log_action("REFUSED #{action}", uuid, "still over threshold", :warning)
                      next
                    end
                  end
                  g.gear.send(action)
                  if action == :throttle
                    @old_bad_gears[uuid] = g
                  end
                  log_action(action, uuid, util[uuid])
                rescue RuntimeError => e
                  log_action("FAILED #{action}", uuid, e.message, :warning)
                end
              end
            end
          end

          def log_action(action, uuid, value, level = :info)
            msg = "Throttler: #{action} => #{uuid} (#{value})"
            log_level = case level
                        when :warning
                          Syslog::LOG_WARNING
                        else
                          Syslog::LOG_INFO
                        end
            Syslog.log(log_level, msg)
          end
        end
      end
    end
  end
end
