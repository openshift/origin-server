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

class MetricPlugin < OpenShift::Runtime::WatchmanPlugin
  attr_accessor :gear_app_uuids
  def initialize(config,gears,restart,operation)
    super(config,gears,restart,operation)
    @gear_app_uuids = Hash.new do |h,uuid|
      h[uuid] = File.read(PathUtils.join(@config.get('GEAR_BASE_DIR', '/var/lib/openshift'), uuid, '.env', 'OPENSHIFT_APP_UUID'))
    end
    # Initiallize metrics to run every 60 seconds
    @metrics = ::OpenShift::Runtime::Utils::Cgroups::Metrics.new 60
  end

  def apply(iteration)
    # Cached using lazy evaluation :)
    @gears.each do |uuid|
      gear_app_uuids[uuid]
    end
    @metrics.update_gears gear_app_uuids
  end
end

module OpenShift
  module Runtime
    module Utils
      class Cgroups
        class Metrics
          attr_accessor :delay, :running_apps

          def initialize delay
            Syslog.info "Initializing watchmen metrics plugin"
            # Set the sleep time for the metrics thread
            @delay = delay
            @mutex = Mutex.new

            initialize_cgroups_vars
            # Begin collection thread
            start
          end

          # Step that is run on each interval
          def tick
            gear_metric_time = time_method {call_gear_metrics}
            Syslog.info "type=metric gear.metric_time=#{gear_metric_time}\n"
          rescue Exception => e
            Syslog.info("Throttler: unhandled exception #{e.message}\n" + e.backtrace.join("\n"))

          end

          def start
            Thread.new do
              loop do
                tick
                sleep @delay
              end
            end
          end

          def update_gears gears
            @running_apps = gears
          end

          def time_method
            start = Time.now
            yield
            Time.now - start
          end

          def call_gear_metrics
            #We need to make sure we have the most up-to-date list of gears on each run
            output = []
            @running_apps.keys.each do |uuid|
              Syslog.info "Running metrics for gear #{uuid}"
              cgroup_name = "/openshift/#{uuid}"
              output.concat get_cgroup_metrics(cgroup_name).map{|metric| "app=#{@running_apps[uuid]} gear=#{uuid} #{metric}"}
            end
            output.each { |metric| Syslog.info("type=metric #{metric}\n") }
          end

          def initialize_cgroups_vars

            @cgroups_single_metrics = %w(cpu.cfs_period_us
                              cpu.cfs_quota_us
                              cpu.rt_period_us
                              cpu.rt_runtime_us
                              cpu.shares
                              cpuacct.usage
                              freezer.state
                              memory.failcnt
                              memory.limit_in_bytes
                              memory.max_usage_in_bytes
                              memory.memsw.failcnt
                              memory.memsw.limit_in_bytes
                              memory.memsw.max_usage_in_bytes
                              memory.memsw.usage_in_bytes
                              memory.move_charge_at_immigrate
                              memory.soft_limit_in_bytes
                              memory.swappiness
                              memory.usage_in_bytes
                              memory.use_hierarchy
                              net_cls.classid
                              notify_on_release)

            @cgroups_kv_metrics = %w(cpu.stat
                      cpuacct.stat
                      memory.oom_control
                      memory.stat)

            @cgroups_multivalue_metrics = %w(cpuacct.usage_percpu)


          end

          def get_cgroup_metrics(path)
            output = []

            #one_call_metrics = @cgroups_single_metrics.concat(@cgroups_kv_metrics).concat(@cgroups_multivalue_metrics)
            output.concat(get_cgroups_single_metric(@cgroups_single_metrics, path))
            output.concat(get_cgroups_multivalue_metric(@cgroups_multivalue_metrics, path))
            output.concat(get_cgroups_kv_metric(@cgroups_kv_metrics, path))

            output
          end

          def get_cgroups_single_metric(metrics, path)
            output = []
            joined_metrics = metrics.join(" -r ")
            retrieved_values = execute_cgget(joined_metrics, path).split("\n")
            retrieved_values.each_with_index do |value, index|
              output.push("#{metrics[index]}=#{value}")
            end
            output
          end

          def get_cgroups_multivalue_metric(metrics, path)
            output = []
            joined_metrics = metrics.join(" -r ")
            lines = execute_cgget(joined_metrics, path).split("\n")
            lines.each_with_index do |line, index|
              line.split.each { |value| output.push("#{metrics[index]}=#{value}") }
            end
            output
          end

          def get_cgroups_kv_metric(metrics, path)
            output = []
            joined_metrics = metrics.join(" -r ")
            cg_output = execute_cgget(joined_metrics, path)
            kv_groups = cg_output.split(/\\n(?!\\t)/)
            metric_prefix = ""
            metric_index = 0
            kv_groups.each_with_index do |group, index|
              lines = group.split("\n")
              lines.each_with_index do |line, sub_index|
                key, value = line.split.map { |item| item.strip }
                if sub_index == 0
                  metric_prefix = key
                  output.push("#{metrics[index]}.#{key}=#{value}")
                end
                output.push("#{metrics[index]}.#{metric_prefix}.#{key}=#{value}")
              end
            end
            output
          end

          # This method returns a string to be processed, is it worth wrapping the execute?
          def execute_cgget(metrics, path)
            `cgget -n -v -r #{metrics} #{path}`
          end
        end
      end
    end
  end
end
