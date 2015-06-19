#--
# Copyright 2013-2014 Red Hat, Inc.
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

require 'openshift-origin-node/model/watchman/watchman_plugin'

# Provide Watchman with monitoring of gear resource usage and limit abusers
class ThrottlerPlugin < OpenShift::Runtime::WatchmanPlugin

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  def initialize(config, logger, gears, operation)
    super

    # create thread here...
    @throttler = begin
      ::OpenShift::Runtime::Utils::Cgroups::Throttler.new
    rescue => e
      Syslog.warning("Warning node is running un-throttled!\nFailed to create Throttler: #{e.message}")
      nil
    end
  end

  # Update Throttler tables and find any abusers...
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration not used
  def apply(iteration)
    begin
      @throttler.throttle(@gears)
    rescue => e
      Syslog.info("Throttler run failed: #{e.message}, will retry.")
    end
  end
end

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class Throttler
          RESOURCE_LIMITS = '/etc/openshift/resource_limits.conf'

          attr_accessor :running_apps, :interval, :uuids

          def initialize
            # Allow us to synchronize destructive operations to @running_apps
            @mutex            = Mutex.new
            @uuids            = []

            # Make sure we create a MonitoredGear for the root OpenShift cgroup
            # Keys for information we want from cgroups
            @wanted_keys      = %w(usage throttled_time nr_periods cfs_quota_us cfs_period_us ts)

            # Set the interval to save
            @interval         = resource('apply_period') { |x| Integer(x) }
            # Throttle at this percent
            @throttle_percent = resource('apply_percent') { |x| Float(x) }
            # Restore at this percent
            @restore_percent  = resource('restore_percent') { |x| Float(x) }

            MonitoredGear.intervals = [@interval]

            MonitoredGear.delay = 5
            MonitoredGear.delay = ENV['THROTTLER_CHECK_PERIOD'].to_i unless ENV['THROTTLER_CHECK_PERIOD'].nil?

            # Allow us to lazy initialize MonitoredGears
            @running_apps       = Hash.new { |h, uuid| h[uuid] = MonitoredGear.new(uuid) }

            # Need to "escape" the percents here for use in Syslog.info
            str                 = 'throttle at: %0.2f%%%%, restore at: %0.2f%%%%, period: %d, check_interval: %0.2fs' %
                [@throttle_percent, @restore_percent, @interval, MonitoredGear.delay]
            Syslog.info("Starting throttler => #{str}")

            # Start our collector thread
            start
          end

          # Allow us to get the config value from the cgroups_config
          # It also allows us to try to cast it into a particular type or raise an error it that fails
          # @param key   [String]        resource to read
          # @yieldreturn [String]        value of resource read
          # @@raise      [ArgumentError] if resource not found
          def resource(key)
            begin
              @resource_limits ||= ::OpenShift::Runtime::Utils::Cgroups::Config.new(RESOURCE_LIMITS).get_group('cg_template_throttled')
              val              = @resource_limits.get(key)
              yield val
            rescue
              raise ArgumentError, "#{RESOURCE_LIMITS} requires '#{key}' in '[cg_template_throttled]' group"
            end
          end

          # Update throttle with current usage
          # @param gears [Array<String>] running gears on system
          def throttle(gears)
            self.uuids            = gears
            (bad_gears, cur_util) = find(period: @interval, usage: @throttle_percent)

            util           = cur_util.inject({}) do |h, (uuid, vals)|
              h[uuid] = (vals.map { |_, v| v['usage_percent'] }.first || '???')
              h
            end

            # If this is our first run, make sure we find any previously throttled gears
            # NOTE: There is a corner case where we won't find non-running throttled applications
            @old_bad_gears ||= find(state: :throttled).first

            # Remove any previously throttled gears that are no longer running
            @mutex.synchronize do
              @old_bad_gears.select! { |k, v| running_apps.keys.include?(k) }
            end

            # Restore any gears we have utilization values for that are <= restore_percent
            (restore_gears, @old_bad_gears) = @old_bad_gears.partition do |uuid, _|
              util.has_key?(uuid) && util[uuid] <= @restore_percent
            end.map { |a| Hash[a] }

            @old_bad_gears.each do |uuid, gear|
              u   = util[uuid]
              msg = (u.nil? || u == '???') ? 'unknown utilization' : "still over threshold (#{util[uuid]})"
              refuse_action(:restore, uuid, msg)
            end

            # Do not attempt to throttle any gears that are already throttled
            bad_gears.reject! do |uuid, _|
              @old_bad_gears.has_key?(uuid)
            end

            # Find any "bad" gears that are boosted
            (boosted_gears, bad_gears) = bad_gears.partition do |_, gear|
              gear.gear.boosted?
            end.map { |a| Hash[a] }

            boosted_gears.each do |uuid, _|
              refuse_action(:throttle, uuid, 'gear is boosted')
            end

            (restore_gears.keys & bad_gears.keys).each {|k| bad_gears.delete(k)}
            apply_action({restore: restore_gears, throttle: bad_gears}, util)
          end

          # start background thread
          def start
            Thread.new do
              loop do
                tick
                sleep MonitoredGear.delay
              end
            end
          end

          # update gear usage values
          def tick
            vals = Libcgroup.usage
            vals = Hash[vals.map { |uuid, hash| [uuid, hash.select { |k, _| @wanted_keys.include? k }] }]

            update(vals)
          rescue => e
            Syslog.info("Throttler: unhandled error #{e.message}\n" + e.backtrace.join("\n"))
          end

          # Update our MonitoredGears based on new data
          #
          # @param vals [Hash] usage data
          def update(vals)
            # Synchronize this in case uuids are deleted
            @mutex.synchronize do
              _uuids  = uuids
              threads = vals.select { |k, _| _uuids.include?(k) }.map do |uuid, data|
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
          #
          # @param new_uuids [Array<String>] list of running gears
          def uuids=(new_uuids)
            @mutex.synchronize do
              # Set the uuids of running gears
              @uuids = new_uuids
              # Delete any missing gears to free up memory
              @running_apps.select! { |k, v| new_uuids.include?(k) }
            end
          end

          # Update utilization for running gears
          #
          # @param apps [Hash<String,..] cached utilization for running gears
          def utilization(apps = running_apps)
            utilization = {}
            @mutex.synchronize do
              threads = apps.map do |k, v|
                Thread.new do
                  utilization[k] = v.utilization
                end
              end
              threads.map(&:join)
            end
            Hash[utilization.sort]
          end

          # find gears that have exceeded their allotted resources
          #
          # @param options [Hash<Symbol, ...] options to find
          # @return [Hash<String, ...>, Hash<String, ...>]
          def find(options)
            apps = running_apps.clone

            cur_util = utilization
            if (usage = options[:usage])
              period      = options[:period] || MonitoredGear.intervals.first
              # Find any utilization values with the correct period
              with_period = cur_util.inject({}) do |h, (k, v)|
                if (vals = (v.find { |k, v| k == period } || []).last)
                  h[k] = vals
                end
                h
              end
              # Find any gears over the threshold
              over_usage  = with_period.select do |k, v|
                begin
                  percent = v['usage_percent']
                  percent && percent >= usage
                rescue
                  Syslog.log(:info, "Throttler: problem in find for #{k} (#{v['usage_percent']})")
                  return false
                end
              end.keys
              apps.select! { |k, v| over_usage.include?(k) }
            end

            if (state = options[:state])
              apps.select! do |_, v|
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


          # Apply changes to gears
          #
          # @param hash [Hash<Symbol, Hash<String, ...>>] Action to be done, which gears to apply Action
          def apply_action(hash, util)
            hash.each do |action, gears|
              gears.each do |uuid, g|
                begin
                  g.gear.send(action)
                  if action == :throttle
                    @old_bad_gears[uuid] = g
                  end
                  log_action(action, uuid, util[uuid])
                rescue RuntimeError => e
                  failed_action(action, uuid, e.message)
                end
              end
            end
          end

          # Log message refusing action
          # @param action [Symbol] action being refused
          # @param uuid   [String] Gear that was commanded
          # @param reason [String] Why was action not performed
          def refuse_action(action, uuid, reason)
            log_action("REFUSED #{action}", uuid, reason, Syslog::LOG_WARNING)
          end

          # Log message when action fails
          # @param action [Symbol] action that failed
          # @param uuid   [String] Gear that was commanded
          # @param reason [String] Why did action fail
          def failed_action(action, uuid, reason)
            log_action("FAILED #{action}", uuid, reason, Syslog::LOG_WARNING)
          end

          def log_action(action, uuid, value, level = Syslog::LOG_INFO)
            Syslog.log(level, "Throttler: #{action} => #{uuid} (#{value})")
          end
        end
      end
    end
  end
end

