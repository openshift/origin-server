#!/usr/bin/env oo-ruby

require 'active_support/core_ext/numeric/time'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/shell_exec'
require 'syslog'
require_relative 'monitored_gear'

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class Throttler
          attr_reader :wanted_keys, :uuids, :running_apps, :threshold, :interval

          @@conf_file = '/etc/openshift/resource_limits.conf'
          @@cgroups_dir = Libcgroup.cgroup_path

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
            @running_apps = Hash.new do |h,k|
              h[k] = MonitoredGear.new(k)
            end

            Syslog.open(File.basename($0), Syslog::LOG_PID, Syslog::LOG_DAEMON) unless Syslog.opened?
            Syslog.info("Starting throttler => threshold: #{@threshold.to_f}%%/#{@interval}s, check_interval: #{MonitoredGear.delay}")

            # Start our collector thread
            start
          end

          # Loop through all lines from grep and contruct a hash
          # TODO: Should this be moved into libcgroup?
          def parse_usage(info)
            info.lines.to_a.inject(Hash.new{|h,k| h[k] = {}} ) do |h,line|
              (uuid, key, val) = line.split(/\W/).values_at(0,-2,-1)
              h[uuid][key.to_sym] = val.to_i
              h
            end
          end

          # TODO: Should this be moved into libcgroup?
          def get_usage
            cmd = 'grep -H "" */{cpu.stat,cpuacct.usage,cpu.cfs_quota_us} 2> /dev/null'
            out = ::OpenShift::Runtime::Utils::oo_spawn(cmd, :chdir => @@cgroups_dir).first
            out
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
            usage = get_usage
            vals = parse_usage(usage)
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
              apps.select!{|k,v| v.gear.profile == state}
            end
            # Return current utilization with the apps for logging
            [apps, cur_util]
          end

          def throttle(args)
            (bad_gears, cur_util) = find(args)
            # If this is our first run, make sure we find any previously throttled gears
            # NOTE: There is a corner case where we won't find non-running throttled applications
            @old_bad_gears ||= find(state: :throttled).first

            # Separate the good and bad gears
            (@old_bad_gears, good_gears) = @old_bad_gears.partition{|k,v| bad_gears.has_key?(k) }.map{|a| Hash[a] }
            # Only throttle bad gears that aren't throttled
            (@old_bad_gears, bad_gears) = bad_gears.partition{|k,v| @old_bad_gears.has_key?(k) }.map{|a| Hash[a] }

            apply_action({
              :restore => good_gears,
              :throttle => bad_gears,
              nil => @old_bad_gears
            }, cur_util)

            @old_bad_gears.merge!(bad_gears)
          end

          def apply_action(hash, cur_util)
            util = cur_util.inject({}) do |h,(uuid,vals)|
              h[uuid] = (vals.map{|k,v| v[:usage_percent] }.first || '???')
              h
            end

            hash.each do |action, gears|
              str = action || "over_threshold"
              gears.each do |uuid, g|
                g.gear.send(action) if action
                log_action(str, uuid, util[uuid])
              end
            end
          end

          def log_action(action, uuid, value)
            Syslog.info("Throttler: #{action} => #{uuid} (#{value})")
          end
        end
      end
    end
  end
end
