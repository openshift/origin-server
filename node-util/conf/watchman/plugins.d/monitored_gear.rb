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
require 'active_support/core_ext/numeric/time'
require 'openshift-origin-node/utils/cgroups'

# Provide some helpers for array math
# These will only work on arrays of number values
class Array
  # Get the average value for an array
  def average
    inject(&:+) / length rescue 0
  end

  # Perform division
  # - If provided with an array, will divide all values
  # - If provided with an integer, will divide all values by that value
  def divide(arr)
    do_math(arr) do |a, b|
      if 0 == a || 0 == b
        0
      else
        a.to_f / b rescue 0
      end
    end
  end

  # Perform multiplication
  # - If provided with an array, will multiply all values
  # - If provided with an integer, will multiply all values by that value
  def mult(arr)
    do_math(arr) do |a, b|
      a * b
    end
  end

  protected
  def do_math(arr)
    unless arr.is_a?(Array)
      arr = [arr] * length
    end
    zip(arr).map { |x| yield x.first, x.last }
  end
end

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class MonitoredGear
          @@intervals = [10.seconds, 30.seconds]
          @@delay     = nil
          @@max       = nil
          @@_delay    = nil
          MIN_DELAY   = 5

          attr_accessor :thread, :times
          attr_reader :gear

          def initialize(uuid)
            @gear  = OpenShift::Runtime::Utils::Cgroups.new(uuid)
            @times = {}
          end

          # Get the current values and remove any expired values
          # Then make sure our intervals are updated
          def update(vals)
            time         = Time.now
            @times[time] = vals
            @utilization = nil
            cutoff       = time - MonitoredGear.max
            @times.delete_if { |k, v| k < cutoff }
          end

          def oldest
            times.min.first
          end

          def newest
            times.max.first
          end

          def age
            (newest - oldest) rescue 0.0
          end

          def utilization
            @utilization ||= update_utilization
          end

          # Update the elapsed intervals
          def update_utilization
            utilization = {}
            unless times.empty?
              cur     = newest
              # Go through each interval we want
              threads = MonitoredGear.intervals.map do |i|
                Thread.new do
                  if age.to_i >= i
                    # Find any values at or after our cutoff
                    vals = times.select { |k, v| k >= (cur - i) }
                    # Make sure we have enough sample points for this dataset
                    if vals.length > 0
                      # Calculate the elapsed usage for our values
                      utilization[i] = elapsed_usage(vals.values)
                    end
                  end
                end
              end
              threads.map(&:join)
            end
            Hash[utilization.sort]
          end

          # Calculate the elapsed usage as a percentage of the max for that time
          # period
          # Doing it this way allows us to calculate the percentage based on the
          # quota and period at the time of each measurement in case it changes
          def elapsed_usage(hashes)
            # These are keys we don't want to include in our calculations
            util_keys   = %w(cfs_quota_us nr_periods cfs_period_us ts)
            # Collect all of the values into a single hash
            values      = collapse_hashes(hashes)
            # Calculate the differences across values
            differences = calculate_differences(values)

            # Disregard the first quota, so we can align with the differences
            (quotas       = values['cfs_quota_us']).shift
            periods       = differences['nr_periods']
            time_deltas   = differences['ts']

            # Find the max possible cpu usage by the following:
            # time_delta * 1 billion * quota/period
            # The 1 billion is because throttled_time and cpuacct.usage are in nanoseconds
            quota_periods = quotas.mult(time_deltas).mult(1_000_000_000).divide(values['cfs_period_us'])

            differences.inject({}) do |h, (k, vals)|
              unless util_keys.include?(k) || vals.empty?
                # Calculate the values as a percentage of the max utilization for a period
                percentage = vals.divide(quota_periods).mult(100)
                per_period = vals.divide(periods)
                {
                    nil          => vals.average,
                    'per_period' => per_period.average.round(3),
                    'percent'    => percentage.average.round(3),
                }.each do |k2, v|
                  # skip _ if either 'k' is nil
                  key    = [k, k2].compact.join('_')
                  h[key] = v
                end
              end
              h
            end
          end

          class << self
            def intervals=(intervals)
              @@intervals = intervals
              @@delay     = nil
              @@max       = nil
            end

            def delay=(delay)
              @@delay  = delay
              # Store this explicit delay so that it doesn't get overwritten
              @@_delay = delay
              @@max    = nil
            end

            def max
              @@max ||= intervals.max + (delay * 2)
            end

            def delay
              @@delay ||= (@@_delay || new_delay)
            end

            def intervals
              @@intervals
            end

            protected
            def new_delay
              new_delay = intervals.min.to_f / 4
              [new_delay, MIN_DELAY].max
            end
          end

          # Collapse multiple hashes into a single hash with the values from corresponding keys combined
          def collapse_hashes(hashes)
            hashes.inject(Hash.new { |h, k| h[k] = [] }) { |h, vals| vals.each { |k, v| h[k] << v }; h }
          end

          # For each value in the hash, calculate the difference between elements
          def calculate_differences(values)
            values.inject({}) { |h, (k, v)| h[k] = v.each_cons(2).map { |a, b| b-a }; h }
          end
        end
      end
    end
  end
end
