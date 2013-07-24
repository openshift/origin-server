#!/usr/bin/env oo-ruby

require 'active_support/core_ext/numeric/time'
require 'openshift-origin-node/utils/cgroups'
require_relative 'monitored_gear'

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class Throttler
          def initialize(*args)
            # Make sure we create a MonitoredGear for the root OpenShift cgroup
            # Keys for information we want from cgroups
            @wanted_keys = %w(usage throttled_time nr_periods cfs_quota_us cfs_period_us).map(&:to_sym)
            # Allow us to synchronize destructive operations to @running_apps
            @mutex = Mutex.new
            @uuids = []

            # Go through any arguments passed to us
            Hash[*args].each do |k,v|
              case k
              when :intervals, :delay
                MonitoredGear.send("#{k}=",v)
              end
            end

            # Allow us to lazy initialize MonitoredGears
            @running_apps = Hash.new do |h,k|
              h[k] = MonitoredGear.new(k)
            end

            # Start our collector thread
            start
          end

          # Loop through all lines from grep and contruct a hash
          def parse_usage(info)
            info.lines.map(&:strip).inject(Hash.new{|h,k| h[k] = {}}) do |h,line|
              # Split the output into the file and data
              (file,info) = line.split(':')
              # Create a path out of the filename and extract the uuid
              uuid = File.dirname(file).split('/').last
              # Create a key out of the filename
              key = File.basename(file).split('.').last
              # Get the value out of the data
              parts = info.split
              val = parts.last.to_i
              # Some of the files have multiple lines, so we use that as the key instead
              if parts.length == 2
                key = parts.first
              end
              # Save the value
              h[uuid][key.to_sym] = val
              h
            end
          end

          def get_usage
            parse_usage(`grep -H "" /cgroup/all/openshift/{,*/}{cpu.stat,cpuacct.usage,cpu.cfs_quota_us} 2> /dev/null`)
          end

          def start
            Thread.new do
              loop do
                vals = get_usage
                vals = Hash[vals.map{|uuid,hash| [uuid,hash.select{|k,v| @wanted_keys.include?k}]}]

                update(vals)

                sleep MonitoredGear::delay
              end
            end
          end

          # Update our MonitoredGears based on new data
          def update(vals)
            # Synchronize this in case uuids are deleted
            @mutex.synchronize do
              threads = vals.select{|k,v| @uuids.include?(k) }.map do |uuid,data|
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
              @running_apps.select!{|k,v| @uuids.include?(k) }
            end
          end

          def utilization(apps = @running_apps)
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

          def find(*args)
            options = args.pop if args.last.is_a?(Hash)

            apps = args.shift
            apps ||= @running_apps.clone

            cur_util = utilization
            if (usage = options[:usage])
              period = options[:period]
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
            args[:period] ||= MonitoredGears.intervals.first

            (bad_gears, cur_util) = find(args)
            # If this is our first run, make sure we find any previously throttled gears
            # NOTE: There is a corner case where we won't find non-running throttled applications
            @old_bad_gears ||= find(@running_apps, state: :throttled).first

            # Separate the good and bad gears
            (@old_bad_gears, good_gears) = @old_bad_gears.partition{|k,v| bad_gears.has_key?(k) }.map{|a| Hash[a] }
            # Only throttle bad gears that aren't throttled
            (@old_bad_gears, bad_gears) = bad_gears.partition{|k,v| @old_bad_gears.has_key?(k) }.map{|a| Hash[a] }

            # Restore all of the good gears
            good_gears.each do |uuid,g|
              g.gear.restore
            end

            # Throttle all of the bad gears
            bad_gears.each do |uuid,g|
              g.gear.throttle
            end

            retval = {
              "Throttled"       => get_util(bad_gears, cur_util),
              "Restored"        => get_util(good_gears, cur_util),
              "Over Threshold"  => get_util(@old_bad_gears, cur_util)
            }

            @old_bad_gears.merge!(bad_gears)

            retval
          end

          def get_util(gears, util)
            gears.keys.inject({}) do |h,uuid|
              val = util[uuid].values.first[:usage_percent] rescue "???"
              h[uuid] = val
              h
            end
          end
        end
      end
    end
  end
end
