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
  def initialize(config,logger,gears,operation)
    super(config,logger,gears,operation)
    @gear_app_uuids = Hash.new do |h,uuid|
      h[uuid] = File.read(PathUtils.join(@config.get('GEAR_BASE_DIR', '/var/lib/openshift'), uuid, '.env', 'OPENSHIFT_APP_UUID'))
    end
    # Initiallize metrics to run every 60 seconds
    delay = Integer(@config.get('WATCHMAN_METRICS_INTERVAL')) rescue 60
    @metrics = ::OpenShift::Runtime::Utils::Cgroups::Metrics.new(delay)
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
    module WatchmanPlugin
      class Metrics
        attr_accessor :delay, :running_apps

        def initialize delay
          Syslog.info "Initializing Watchman metrics plugin"
          # Set the sleep time for the metrics thread
          @delay = delay
          @mutex = Mutex.new
          @running_apps = {}
          initialize_cgroups_vars
          # Begin collection thread
          start
        end

        # Step that is run on each interval
        def tick
          @mutex.synchronize do
            gear_metric_time = time_method {call_gear_metrics}
            Syslog.info "type=metric gear.metric_time=#{gear_metric_time}"
            call_application_container_metrics
          end
        rescue Exception => e
          Syslog.info("Metric: unhandled exception #{e.message}\n" + e.backtrace.join("\n"))

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
          @mutex.synchronize do
            @running_apps = gears
          end
        end

        def time_method
          start = Time.now
          yield
          Time.now - start
        end

        def call_application_container_metrics
          res,err, _ = Utils.oo_spawn("oo-admin-ctl-gears metricsall")
          Syslog.info(res)
        end

        def call_gear_metrics
          output = []
          @running_apps.keys.each do |uuid|
            cgroup_name = "/openshift/#{uuid}"
            output.concat get_cgroup_metrics(cgroup_name).map{|metric| "app=#{@running_apps[uuid]} gear=#{uuid} #{metric}"}
          end
          output.each { |metric| Syslog.info("type=metric #{metric}") }
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
          kv_groups = cg_output.split(/\n(?!\t)/)
          kv_groups.each_with_index do |group, index|
            lines = group.split("\n")
            lines.each_with_index do |line, sub_index|
              key, value = line.split.map { |item| item.strip }
              output.push("#{metrics[index]}.#{key}=#{value}")
            end
          end
          output
        end

        # This method returns a string to be processed, is it worth wrapping the execute?
        def execute_cgget(metrics, path)
          Utils.oo_spawn("cgget -n -v -r #{metrics} #{path}")[0]
        end
      end
    end
  end
end
