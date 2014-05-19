#--
# Copyright 2014 Red Hat, Inc.
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
require 'openshift-origin-node/utils/metrics_helper'

class MetricsPlugin < OpenShift::Runtime::WatchmanPlugin
  def initialize(config, logger, gears, operation)
    super

    return if disabled?

    @gears_last_updated = nil

    @metrics = ::OpenShift::Runtime::WatchmanPlugin::Metrics.new(@config)
    @metrics.gears_updated(@gears)
    @metrics.start
  end

  def apply(iteration)
    return if disabled?

    if @gears_last_updated.nil? or @gears.last_updated != @gears_last_updated
      @metrics.gears_updated(@gears)
      @gears_last_updated = @gears.last_updated
    end
  end

  def disabled?
    @disabled ||= @config.get('WATCHMAN_METRICS_ENABLED') != 'true'
  end
end

module OpenShift
  module Runtime
    class WatchmanPlugin

      class SyslogLineShipper
        def <<(line)
          Syslog.info(line)
        end
      end

      class Metrics
        DEFAULT_INTERVAL = 60

        attr_reader :delay, :config

        def initialize(config)
          @config = config

          @gear_base_dir = @config.get('GEAR_BASE_DIR')

          @metrics_metadata = ::OpenShift::Runtime::Utils::MetricsHelper.metrics_metadata(@config)

          @cgroups_keys = @config.get('CGROUPS_METRICS_KEYS')
          unless @cgroups_keys.nil?
            @cgroups_keys = @cgroups_keys.split(',').map(&:strip).join(' -r ')
          end

          Syslog.info "Initializing Watchman metrics plugin"

          # Set the sleep time for the metrics thread
          # default to running every 60 seconds if not set in node.conf
          @delay = Integer(@config.get('WATCHMAN_METRICS_INTERVAL')) rescue DEFAULT_INTERVAL

          # must be at least 10s
          if @delay < 10
            Syslog.warning "Watchman metrics interval value '#{@delay}' is too small - resetting to 10s"
            @delay = 10
          end

          Syslog.info "Watchman metrics interval = #{@delay}s"


          @mutex = Mutex.new
          @syslog_line_shipper = SyslogLineShipper.new
          @cgget_metrics_parser = CggetMetricsParser.new(self)
          @quota_parser = QuotaMetricsParser.new(self)
        end

        def gear_metadata
          # Hash of the form (using example key names):
          #
          # {
          #   <gear uuid 1> => {
          #     'gear' => <gear uuid>,
          #     'ns' => <namespace>
          #   },
          #   ...
          # }
          #
          # Lazily load the data on Hash access
          @gear_metadata ||= Hash.new do |all_md, uuid|
            all_md[uuid] = Hash.new do |gear_md, key|
              env_var = @metrics_metadata[key]
              value = File.read(PathUtils.join(@gear_base_dir, uuid, '.env', env_var)) rescue nil
              gear_md[key] = value unless value.nil?
            end
          end

        end

        # Cache the metadata for each gear
        def gears_updated(gears)
          # need to sync modifications to gear_metadata
          @mutex.synchronize do
            seen = []

            gears.each do |uuid|
              # keep track of each uuid we've seen this time
              seen << uuid

              # add the uuid to the metadata if it's new;
              # data will be loaded lazily via Hash.new block above
              gear_metadata[uuid] unless gear_metadata.has_key?(uuid)
            end

            # remove metadata for all uuids that previously were in gear_metadata
            # but are no longer in the active gears list
            gear_metadata.delete_if { |key, value| not seen.include?(key) }
          end
        end

        # Step that is run on each interval
        #
        # Mutex acquired and held for duration of method
        def tick
          # need to sync access to gear_metadata
          @mutex.synchronize do
            if gear_metadata.size > 0
              get_gear_metrics
              get_application_container_metrics
            end
          end
        rescue => e
          Syslog.info("Metrics: unhandled exception #{e.message}\n" + e.backtrace.join("\n"))
        end

        def start
          Thread.new do
            loop do
              tick
              sleep @delay
            end
          end
        end

        # Get cartridge and application metrics for all gears.
        #
        # Mutex acquired and held by caller
        def get_application_container_metrics
          ::OpenShift::Runtime::Utils.oo_spawn("oo-admin-ctl-gears metricsall", out: @syslog_line_shipper)
        end

        # Get system-level gear metrics:
        # - cgroups
        # - quota
        #
        # Mutex acquired and held by ancestor caller
        def get_gear_metrics
          get_cgroups_metrics
          get_quota_metrics
        end

        def cgget_paths
          gear_metadata.keys.map { |uuid| "/openshift/#{uuid}" }
                            .join(' ')
        end

        def cgget_command(paths)
          if @cgroups_keys.nil?
            "cgget -a #{paths}"
          else
            "cgget -r #{@cgroups_keys} #{paths}"
          end
        end

        # Mutex acquired and held by ancestor caller
        def get_cgroups_metrics
          command = cgget_command(cgget_paths)

          @cgget_metrics_parser.reset

          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn(command, out: @cgget_metrics_parser)
        end

        def gear_file_system
          if @gear_file_system.nil?
            @gear_file_system, _, _ = ::OpenShift::Runtime::Utils.oo_spawn("df -P #{@gear_base_dir} | tail -1 | cut -d ' ' -f 1",
                                                                           expected_exitstatus: 0)

            @gear_file_system.chomp!
          end

          @gear_file_system
        end

        # Mutex acquired and held by ancestor caller
        def get_quota_metrics
          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("repquota #{gear_file_system}",
                                                              expected_exitstatus: 0,
                                                              out: @quota_parser)
        end

        def publish(gear_uuid, output)
          metadata = []

          # ruby 1.9+ returns keys in insertion order!
          @metrics_metadata.keys.each do |key|
            metadata << "#{key}=#{gear_metadata[gear_uuid][key]}"
          end

          line = "type=metric #{metadata.join(' ')} #{output}"

          Syslog.info(line)
        end
      end

      class CggetMetricsParser
        def initialize(parent)
          reset
          @parent = parent
          @max_output_length = (@parent.config.get('MAX_CGROUPS_METRICS_MESSAGE_LENGTH') || 1024).to_i
        end

        def reset
          @gear = nil
          @saved = ''
          @group = nil
          @current_output_length = 0
          @current_output = []
        end

        # Processes output from cgget and sends each metric to Syslog
        #
        # The ouput has the following sequences/types of data
        #
        # HEADER
        # /openshift/$gear_uuid:
        #
        # SINGLE KEY-VALUE PAIR
        # cpu.rt_period_us: 1000000
        #
        # PARENT-CHILD KEY-VALUE PAIRS
        # cpu.stat: nr_periods 6266
        #     nr_throttled 0
        #     throttled_time 0
        #
        # SEPARATOR
        # <a blank line separates gears>
        #
        # This method will take each chunk of output from cgget, keep track
        # of what it is in the middle of processing, and emit individual
        # metrics to Syslog as it sees them.
        #
        def <<(data)
          scanner = StringScanner.new(data)
          loop do
            # look for a newline
            line = scanner.scan_until(/\n/)
            if line.nil?
              # no newline, save what we got and wait for the next call to <<
              @saved += scanner.rest

              # if we have any unpublished output, publish it
              publish unless @current_output.empty?

              break
            end

            # got a full line
            line = @saved + line

            # clear out anything we might have previously saved
            @saved = ''

            # strip off any newline
            line.chomp!

            # HEADER check
            # see if we're looking for the gear
            if @gear.nil?
              # line must be a gear of the form /openshift/$uuid
              @gear = line[0..-2].gsub('/openshift/', '')

              # there may be more data to process, so move on to the next
              # loop iteration
              next
            end

            # SEPARATOR check
            # see if we've reached the end of data for the current gear
            # i.e. a blank line
            if line =~ /^\s*$/
              # if we have any unpublished output, publish it
              publish unless @current_output.empty?

              # clear out the gear
              @gear = nil

              # there may be more data to process, so move on to the next
              # loop iteration
              next
            end

            # CHILD check
            # currently in a group
            if line =~ /^\s/
              key, value = line.split
              store(key, value)
            else
              # no longer in a group if we previously were
              @group = nil

              key, value = line.split(':')
              value.strip!

              if key == 'cpuacct.usage_percpu'
                # got a line of the form "cpuacct.usage_percpu: 3180064217 3240110361"
                value.split.each_with_index do |usage, i|
                  store("#{key}.#{i}", usage)
                end
              elsif value =~ /\s/
                # got a line of the form "cpu.stat: nr_periods 6266"
                # so we're now in a group
                @group = "#{key}."

                key, value = value.split
                store(key, value)
              else
                # not in a group, got a line of the form "cpu.rt_runtime_us: 0"
                store(key, value)
              end
            end
          end
        end

        def store(key, value)
          new_output = "#{@group}#{key}=#{value}"
          new_output_length = new_output.length + 1 # account for the space in between metrics

          publish if @current_output_length + new_output_length > @max_output_length

          @current_output << new_output
          @current_output_length += new_output_length
        end

        def publish
          output = @current_output.join(' ')
          @parent.publish(@gear, output)

          # we're done publishing, so clear things
          @current_output = []
          @current_output_length = 0
        end
      end

      class QuotaMetricsParser
        def initialize(parent)
          @parent = parent
          @saved = ''
        end

        # Processes output from repquota and sends each metric to Syslog
        #
        # The ouput has the following format:

        # *** Report for user quotas on device /dev/mapper/VolGroup-lv_root
        # Block grace time: 7days; Inode grace time: 7days
        #                         Block limits                File limits
        # User            used    soft    hard  grace    used  soft  hard  grace
        # ----------------------------------------------------------------------
        # root      -- 4358824       0       0         203280     0     0
        # daemon    --       8       0       0              2     0     0
        # 533364839023f0bdad00001d --    1044       0 1048576            255     0 40000
        # #501      --     924       0       0             73     0     0
        #
        #
        # This method will take each chunk of output from repquota, keep track
        # of what it is in the middle of processing, and emit individual
        # metrics to Syslog as it sees them.
        #
        def <<(data)
          scanner = StringScanner.new(data)
          loop do
            # look for a newline
            line = scanner.scan_until(/\n/)
            if line.nil?
              # no newline, save what we got and wait for the next call to <<
              @saved += scanner.rest
              break
            end

            # got a full line
            line = @saved + line

            # clear out anything we might have previously saved
            @saved = ''

            # strip off any newline
            line.chomp!

            fields = line.split(/\s+/)
            if @parent.gear_metadata.keys.include?(fields[0])
              gear_uuid = fields[0]
              blocks_used = fields[2]
              blocks_limit = fields[4]
              files_used = fields[5]
              files_limit = fields[7]

              @parent.publish(gear_uuid, "quota.blocks.used=#{blocks_used} quota.blocks.limit=#{blocks_limit} quota.files.used=#{files_used} quota.files.limit=#{files_limit}")
            end
          end
        end
      end


    end
  end
end
