#--
# Copyright 2010 Red Hat, Inc.
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

require 'openshift-origin-common/config'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/shell_exec'
require 'tempfile'
require 'fileutils'
require 'etc'

$OPENSHIFT_RUNTIME_UTILS_TC_MUTEX = Mutex.new

module OpenShift
  module Runtime
    module Utils

      #
      # This class is a nearly direct translation of the TC shell
      # script to solve a specific problem and should be rewritten
      # to be a clean API when time permits.
      #
      #
      # CAVEAT: This script assumes the selinux container and libcgroup
      #         cgroups implementation.
      #
      class TC

        @@MUTEX=$OPENSHIFT_RUNTIME_UTILS_TC_MUTEX
        @@LOCKFILE="/var/lock/oo-tc"

        def initialize
          @output = []

          @config    = ::OpenShift::Config.new('/etc/openshift/node.conf')
          @wrap_around_uid = (@config.get("WRAPAROUND_UID") || 65536).to_i
          @resources = ::OpenShift::Runtime::Utils::Cgroups::Config.new('/etc/openshift/resource_limits.conf')


          # ============================================================================
          #  Functions for setting the net class
          # ============================================================================

          #
          #  tc uses the following units when passed as a parameter.
          #  kbps: Kilobytes per second
          #  mbps: Megabytes per second
          #  kbit: Kilobits per second
          #  mbit: Megabits per second
          #  bps: Bytes per second
          #       Amounts of data can be specified in:
          #       kb or k: Kilobytes
          #       mb or m: Megabytes
          #       mbit: Megabits
          #       kbit: Kilobits
          #  To get the byte figure from bits, divide the number by 8 bit
          #

          # Create a openshift parent qdesc and limit it to a large percentage of the
          # bandwidth of the interface (leaving some for the OS)
          #
          # Then create for each user a qdesc and limit it to a small fraction of
          # the total bandwidth
          #

          # The network interface(s) we're planning on limiting bandwidth.
          @tc_ifs=(@config.get('TRAFFIC_CONTROL_DEVS') or @config.get('EXTERNAL_ETH_DEV') or 'eth0').gsub(/\s+/m, ' ').strip.split(" ")
          # a map of interface name to min quantum (e.g. { 'eth0' => 1500, 'lo' => 65536 })
          @tc_min_quantum=Hash[@tc_ifs.collect { |tc_if| [tc_if, (@resources.get('tc_min_quantum') or get_interface_mtu(tc_if)).to_i] }]
          @tc_max_quantum=(@resources.get('tc_max_quantum') or 100000).to_i

          # Normal bandwidths are in Mbit/s
          @tc_max_bandwidth=(@resources.get('tc_max_bandwidth') or 800).to_i # 800 mbit/s
          @tc_user_share=(@resources.get('tc_user_share') or 2).to_i         # 8 mbit/s normal gear rate (*100 gears = tc_max_bandwidth)
          @tc_user_limit=(@resources.get('tc_user_limit') or @tc_max_bandwidth).to_i # Full burst by default
          @tc_user_quantum=(@resources.get('tc_user_quantum') or @tc_max_quantum).to_i

          # Throttles are in kbit/s
          @tc_throttle_user_share=(@resources.get('tc_throttle_user_share') or 128).to_i    # 128 kbits/s with no borrow
          @tc_throttle_user_limit=(@resources.get('tc_throttle_user_limit') or @tc_throttle_user_share).to_i
          # a map of interface name to throttle user quantum (e.g. { 'eth0' => 1500, 'lo' => 65536 })
          @tc_throttle_user_quantum=Hash[@tc_ifs.collect { |tc_if| [tc_if, (@resources.get('tc_throttle_user_quantum') or @tc_min_quantum[tc_if]).to_i] }]

          # Where we keep track of throttled/high users
          @tc_user_dir=(@resources.get('tc_user_dir') or File.join(@config.get('GEAR_BASE_DIR'), '.tc_user_dir'))
          @tc_outbound_htb=@resources.tc_outbound_htb
        end

        def output
          @output
        end

        def get_interface_mtu(iface)
          out, _, rc = ::OpenShift::Runtime::Utils.oo_spawn(%Q[ip link show dev #{iface}], :chdir=>"/")
          if rc != 0
            raise RuntimeError, "Unable to determine interface MTU for #{iface}."
          end
          if out=~/mtu\s+(\d+)/
            $~[1].to_i
          else
            1500
          end
        end

        def parse_valid_user(uuid)
          pwent = Etc.getpwnam(uuid.to_s)
          if block_given?
            yield(pwent, (pwent.uid % @wrap_around_uid).to_s(16))
          end
        end

        def with_all_users
          users=[]
          Etc.passwd do |pwent|
            if pwent.gecos == (@config.get('GEAR_GECOS') or "OO guest")
              users << [pwent.name, pwent, (pwent.uid % @wrap_around_uid).to_s(16)]
            end
          end
          if block_given?
            users.each do |uuid, pwent, netclass|
              yield(uuid, pwent, netclass)
            end
          end
        end

        def with_tc_batch
          f=Tempfile.new("tc-batch", "/tmp")
          begin
            if block_given?
              yield(f)
            end
            f.fsync
            # Can't directly send the file to TC in stdin due to selinux domains.
            _, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("cat #{f.path} | tc -force -batch", :chdir=>"/")
            if rc != 0
              raise RuntimeError, err
            end
          ensure
            f.close!
          end
        end

        def startuser_impl(uuid, pwent, netclass, f)
          # Select what type of user.  Note that a user can high bandwidth
          # normally but throttled for a specific and temporary reason.
          throttled = File.exists?("#{@tc_user_dir}/#{uuid}_throttle")
          if throttled
            @output.last << "throttled"
            this_user_share="#{@tc_throttle_user_share}kbit"
            this_user_limit="#{@tc_throttle_user_limit}kbit"
          else
            @output.last << "normal"
            this_user_share="#{@tc_user_share}mbit"
            this_user_limit="#{@tc_user_limit}mbit"
          end

          # Overall class for the gear
          @tc_ifs.each do |tc_if|
            this_user_quantum=throttled ? @tc_throttle_user_quantum[tc_if] : @tc_user_quantum
            # for the loopback interface, we want to ignore any configured limits and set a very high limit of 100gbit/s, but only for non-throttled users
            this_if_user_limit=(tc_if.eql?('lo') and not throttled) ? '100000mbit' : this_user_limit
            f.puts %Q[class add dev #{tc_if} parent 1:1 classid 1:#{netclass} htb rate #{this_user_share} ceil #{this_if_user_limit} quantum #{this_user_quantum}]
          end

          # Specific constraints within the gear's limit
          @tc_ifs.each do |tc_if|
            f.puts %Q[qdisc add dev #{tc_if} parent 1:#{netclass} handle #{netclass}: htb default 0]
          end

          @tc_outbound_htb.each.with_index do |htb_array, i|
            bandwidth, ports = htb_array
            rate, ceil = bandwidth
            # I think 0 and 1 are special in tc.  Before we had support for
            # configuring outbound htb minor numbers started at 2.
            minor_number = i+2

            @tc_ifs.each do |tc_if|
              f.puts %Q[class add dev #{tc_if} parent #{netclass}: classid #{netclass}:#{minor_number} htb rate #{rate} ceil #{ceil} quantum #{@tc_min_quantum[tc_if]}]
            end
            ports.each do |p|
              @tc_ifs.each do |tc_if|
                f.puts %Q[filter add dev #{tc_if} parent #{netclass}: protocol ip prio 10 u32 match ip dport #{p} 0xffff flowid #{netclass}:#{minor_number}]
              end
            end
          end
        end

        def stopuser_impl(uuid, pwent, netclass, f)
          @tc_ifs.each do |tc_if|
            f.puts("class del dev #{tc_if} parent 1:1 classid 1:#{netclass}")
          end
        end

        def tc_exists?(netclass)
          exists_all = true
          @tc_ifs.each do |tc_if|
            out, _, _ = ::OpenShift::Runtime::Utils.oo_spawn("tc -s class show dev #{tc_if} classid 1:#{netclass}", :chdir=>"/")
            exists_all = false if out.empty?
          end
          exists_all and not @tc_ifs.empty?
        end

        def with_tc_loaded
          @tc_ifs.each do |tc_if|
            out, _, _ = ::OpenShift::Runtime::Utils.oo_spawn("tc qdisc show dev #{tc_if}", :chdir=>"/")
            if out.include?("qdisc htb 1:")
              yield if block_given?
            else
              raise RuntimeError, "no htb qdisc on #{tc_if}"
            end
          end
        end

        def statususer(uuid, pwent, netclass, verbose=false)
          if out = tc_exists?(netclass)
            @output << "tc is active for the user #{uuid}"
            @output << out if verbose
          else
            raise ArgumentError, "tc not configured for user #{uuid}"
          end
        end

        def synchronized
          r=nil
          @@MUTEX.synchronize do
            File.open(@@LOCKFILE, File::RDWR|File::CREAT|File::TRUNC|File::SYNC, 0o0600) do |lockfile|
              lockfile.sync=true
              lockfile.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
              lockfile.flock(File::LOCK_EX)
              lockfile.write("#{Process::pid}\n")
              begin
                if block_given?
                  r = yield
                end
              ensure
                lockfile.flock(File::LOCK_UN)
              end
            end
          end
          r
        end

        def start_impl(f)
          all_stopped = true
          with_all_users do |uuid, pwent, netclass|
            all_stopped = false if tc_exists?(netclass)
          end
          if all_stopped
            @tc_ifs.each do |tc_if|
              # for the loopback interface, we want to ignore any configured limits and set a very high limit of 100gbit/s
              this_tc_max_bandwidth = tc_if.eql?('lo') ? 100000 : @tc_max_bandwidth
              f.puts %Q[qdisc add dev #{tc_if} root handle 1: htb]
              f.puts %Q[class add dev #{tc_if} parent 1: classid 1:1 htb rate #{this_tc_max_bandwidth}mbit]
              f.puts %Q[filter add dev #{tc_if} parent 1: protocol ip prio 10 handle 1: cgroup]
            end
          end

          
          with_all_users do |uuid, pwent, netclass|
            @output << "Starting tc for #{uuid}: "
            if !tc_exists?(netclass)
              startuser_impl(uuid, pwent, netclass, f)
            else
              @output.last << "tc is already active."
            end
          end
        end

        def start
          @output << "Starting bandwidth shaping: "
          synchronized do
            with_tc_batch do |f|
              start_impl(f)
            end
          end
        end

        def stop_impl(f)
          @tc_ifs.each do |tc_if|
            f.puts %Q[qdisc del dev #{tc_if} root]
          end
        end

        def stop
          @output << "Stopping bandwidth shaping: "
          synchronized do
            with_tc_batch do |f|
              stop_impl(f)
            end
          end
        end

        def startuser(uuid)
          @output << "Starting tc for #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              if tc_exists?(netclass)
                @output << "Throttling is already active for #{uuid}"
              else
                with_tc_batch do |f|
                  startuser_impl(uuid, pwent, netclass, f)
                end
              end
            end
          end
        end

        def stopuser(uuid)
          @output << "Stopping tc for #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              with_tc_batch do |f|
                stopuser_impl(uuid, pwent, netclass, f)
              end
            end
          end
        end

        def restartuser(uuid)
          @output << "Restarting user #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              begin
                with_tc_batch { |f| stopuser_impl(uuid, pwent, netclass, f) }
              rescue RuntimeError, ArgumentError
              end
              with_tc_batch { |f| startuser_impl(uuid, pwent, netclass, f) }
            end
          end
        end

        def throttleuser(uuid)
          @output << "Throttling user #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              FileUtils.touch("#{@tc_user_dir}/#{uuid}_throttle")
              with_tc_batch do |f|
                stopuser_impl(uuid, pwent, netclass, f)
                startuser_impl(uuid, pwent, netclass, f)
              end
            end
          end
        end

        def nothrottleuser(uuid)
          @output << "Unthrottling user #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              FileUtils.rm_f("#{@tc_user_dir}/#{uuid}_throttle")
              begin
                with_tc_batch { |f| stopuser_impl(uuid, pwent, netclass, f) }
              rescue RuntimeError, ArgumentError
              end
              with_tc_batch { |f| startuser_impl(uuid, pwent, netclass, f) }
            end
          end
        end

        def deluser(uuid)
          @output << "Deleting user #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |pwent, netclass|
              FileUtils.rm_f(Dir.glob("#{@tc_user_dir}/#{uuid}_*"))
              with_tc_batch do |f|
                stopuser_impl(uuid, pwent, netclass, f)
              end
            end
          end
        end

        def restart
          @output << "Restarting bandwidth shaping: "
          synchronized do
            begin
              with_tc_batch { |f| stop_impl(f) }
            rescue RuntimeError, ArgumentError
            end
            with_tc_batch { |f| start_impl(f) }
          end
        end

        def show(uuid=nil)
          status(uuid)
        end

        def status(uuid=nil, verbose=false)
          @output << "Bandwidth shaping status: "
          with_tc_loaded do
            if uuid
              parse_valid_user(uuid) do |pwent, netclass|
                statususer(uuid, pwent, netclass, verbose)
              end
            else
              @tc_ifs.each do |tc_if|
                out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc -s qdisc show dev #{tc_if}", :chdir=>"/")
                @output << out
                out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc -s class show dev #{tc_if}", :chdir=>"/")
                @output << out
              end
            end
          end
        end

      end

    end
  end
end
