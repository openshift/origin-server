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

require 'pry'
require 'libvirt'

module OpenShift
  module Runtime
    module Containerization
      class Cgroups
        class LibvirtResourceManager
          # Exception types raised
          #
          # ArgumentError: Problem with the uuid
          # RuntimeError: Problem with the underlying system interface (ex: missing user, cannot assign value).
          # KeyError: Problem with requested parameter or subsystem (ex: not found).

          def initialize(container_uuid)
            @uuid = container_uuid
            conn = Libvirt::open("lxc:///")
            begin
              dom = conn.lookup_domain_by_name @uuid
              raise ArgumentError.new("Container not found") if dom.nil?
            ensure
              conn.close
            end
          end

          # Public: Create the gear cgroup
          def create
            # Note: Probably a noop on libvirt since it does so automatically.
          end

          # Public: Delete a gear cgroup.
          def delete
            # Note: Probably a noop on libvirt since it does so automatically.
          end

          # Public: Fetch cgroup settings for a gear
          #
          # Accepts a set of arguments (will flatten if an array is provided).
          #
          # Returns a hash of parameter names (strings) to their current values (strings).
          #
          # Ex:
          # fetch("cpu.rt_period_us",  "cpu.rt_runtime_us", "freezer.state") -> 
          #   {"cpu.rt_period_us"=>"1000000", "cpu.rt_runtime_us"=>"0", "freezer.state"=>"THAWED" }
          def fetch(*args)
            args = args.flatten
            conn = Libvirt::open("lxc:///")
            begin
              domain = conn.lookup_domain_by_name @uuid
              raise ArgumentError.new("Container not found") if domain.nil?
              values = {
                "cpu.cfs_quota_us"  => domain.scheduler_parameters["vcpu_quota"].to_s,
                "cpu.shares"        => domain.scheduler_parameters["cpu_shares"].to_s,

                "memory.limit_in_bytes"  => domain.memory_parameters["hard_limit"].to_s,
                "memory.memsw.limit_in_bytes"  => domain.memory_parameters["swap_hard_limit"].to_s,

                "freezer.state"     => 'THAWED',
              }

              values.delete_if { |k,v| not args.include?(k) }
            ensure
              conn.close
            end
          end

          # Public: Store cgroup settings for a gear
          #
          # Accepts either a hash or expanded array of parameter names
          # (strings) and values (coerced to string).
          # Ex: {"cpu.rt_period_us"=>"1000000", "cpu.rt_runtime_us"=>"0", "freezer.state"=>"THAWED" }
          # Ex: "cpu.rt_period_us", "1000000", "cpu.rt_runtime_us", "0", "freezer.state", "THAWED"
          #
          # Returns a hash with the settings fed as arguments.
          # Ex: {"cpu.rt_period_us"=>"1000000", "cpu.rt_runtime_us"=>"0", "freezer.state"=>"THAWED" }
          def store(*args)
            # Note: the libcgroup implementation only restores
            # defaults on reboot, whereas libvirt probably makes
            # durable settings.
            h = {}
            if args[0].class == Array
              args.each_slice(2) do |slice|
                h[slice[0]] = slice[1]
              end
            else
              h = args[0]
            end

            conn = Libvirt::open("lxc:///")
            begin
              domain = conn.lookup_domain_by_name @uuid
              raise ArgumentError.new("Container not found") if domain.nil?
              scheduler_parameters = domain.scheduler_parameters
              scheduler_parameters["vcpu_quota"] = h["cpu.cfs_quota_us"].to_i if h.has_key? "cpu.cfs_quota_us"
              scheduler_parameters["cpu_shares"] = h["cpu.shares"].to_i if h.has_key? "cpu.shares"
              domain.scheduler_parameters = scheduler_parameters

              memory_parameters = domain.memory_parameters
              memory_parameters["hard_limit"] = h["memory.limit_in_bytes"].to_i if h.has_key? "memory.limit_in_bytes"
              memory_parameters["swap_hard_limit"] = h["memory.memsw.limit_in_bytes"].to_i if h.has_key? "memory.memsw.limit_in_bytes"
              domain.memory_parameters = memory_parameters
            ensure
              conn.close
            end

            fetch(h.keys)
          end

          # Public: Return the list of processes in the cgroup
          # regardless of who owns them.
          def processes
            # Note: noop for libvirt-sandbox
            []
          end

          # Public: Place processes for this gear in the correct cgroup.
          def classify_processes
            # Note: noop for libvirt-sandbox
          end

          # Return list of cgroup parameters available to the gear
          #
          # Returns a hash of parameter names (strings) to their
          # default values (strings).
          # {"cpu.rt_period_us"=>"1000000", "cpu.rt_runtime_us"=>"0", ..., "freezer.state"=>"THAWED" }
          def parameters
            {
                "cpu.cfs_quota_us"  => '',
                "cpu.shares"        => '',

                "memory.limit_in_bytes"  => '',
                "memory.memsw.limit_in_bytes"  => '',

                "freezer.state"     => 'THAWED',
            }
          end

          # Return cpu utilization of all gears for throttler
          #
          # Returns a structure of hashes from cpu.stat cpuacct.usage cpu.cfs_quota_us
          # { uuid => { :nr_periods => integer,
          #             :nr_throttled => integer,
          #             :throttled_time => integer,
          #             :usage => integer,
          #             :cfs_quota_us => integer },
          #   uuid => { etc...
          #
          def self.usage
            usage = {}

            conn = Libvirt::open("lxc:///")
            begin
              domain_ids = conn.list_domains
              domain_ids.each do |dom_id|
                cgroups = {}
                domain = conn.lookup_domain_by_id dom_id
                (out, err, rc) = ::OpenShift::Runtime::Utils::oo_spawn("cgget /machine/#{domain.name}.libvirt-lxc -g cpu -g cpuacct", :quiet => true)
                out.scan(/([_a-z\.]*): ([\s\-a-z_0-9]*)\n/).map do |line|
                  if(line[1].strip.match('\n'))
                    cgroups[line[0]] = line[1].scan(/[\s]*([a-z_]*) ([0-9\-]*)/).reduce({}){|a, (k,v)| a[k] = v.strip; a}
                  else
                    cgroups[line[0]] = line[1].strip
                  end
                end
                usage[domain.name] = {
                  :nr_periods => cgroups["cpu.stat"]["nr_periods"],
                  :nr_throttled => cgroups["cpu.stat"]["nr_throttled"],
                  :throttled_time => cgroups["cpu.stat"]["throttled_time"],
                  :usage => cgroups["cpuacct.usage"],
                  :cfs_quota_us => cgroups["cpu.cfs_quota_us"],
                }
              end
            ensure
              conn.close
            end
          end
        end
      end
    end
  end
end

