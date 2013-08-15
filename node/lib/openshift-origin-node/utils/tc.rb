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
require 'openshift-origin-node/utils/shell_exec'
require 'tempfile'
require 'fileutils'
require 'etc'

require_relative 'cgroups/config'

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
          @resources = ::OpenShift::Runtime::Utils::Cgroups::Config.new

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

          # The network interface we're planning on limiting bandwidth.
          @tc_if=(@config.get('EXTERNAL_ETH_DEV') or "eth0")
          @tc_if_mtu=get_interface_mtu(@tc_if)
          @tc_min_quantum=(@resources.get('tc_min_quantum') or @tc_if_mtu).to_i
          @tc_max_quantum=(@resources.get('tc_max_quantum') or 100000).to_i

          # Normal bandwidths are in Mbit/s
          @tc_max_bandwidth=(@resources.get('tc_max_bandwidth') or 800).to_i # 800 mbit/s
          @tc_user_share=(@resources.get('tc_user_share') or 2).to_i         # 8 mbit/s normal gear rate (*100 gears = tc_max_bandwidth)
          @tc_user_limit=(@resources.get('tc_user_limit') or @tc_max_bandwidth).to_i # Full burst by default
          @tc_user_quantum=(@resources.get('tc_user_quantum') or @tc_max_quantum).to_i

          # Throttles are in kbit/s
          @tc_throttle_user_share=(@resources.get('tc_throttle_user_share') or 128).to_i    # 128 kbits/s with no borrow
          @tc_throttle_user_limit=(@resources.get('tc_throttle_user_limit') or @tc_throttle_user_share).to_i
          @tc_throttle_user_quantum=(@resources.get('tc_throttle_user_quantum') or @tc_min_quantum).to_i

          # Where we keep track of throttled/high users
          @tc_user_dir=(@resources.get('tc_user_dir') or File.join(@config.get('GEAR_BASE_DIR'), '.tc_user_dir'))
        end

        def output
          @output
        end

        def get_interface_mtu(iface)
          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn(%Q[ip link show dev #{iface}], :chdir=>"/")
          if rc != 0
            raise RuntimeError, "Unable to determine external network interface IP address."
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
            yield(uuid, pwent, pwent.uid.to_s(16))
          end
        end

        def with_all_users
          users=[]
          Etc.passwd do |pwent|
            if pwent.gecos == (@config.get('GEAR_GECOS') or "OO guest")
              users << [pwent.name, pwent, pwent.uid.to_s(16)]
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
            out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("cat #{f.path} | tc -force -batch", :chdir=>"/")
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
          if File.exists?("#{@tc_user_dir}/#{uuid}_throttle")
            @output.last << "throttled"
            this_user_share="#{@tc_throttle_user_share}kbit"
            this_user_limit="#{@tc_throttle_user_limit}kbit"
            this_user_quantum=@tc_throttle_user_quantum
          else
            @output.last << "normal"
            this_user_share="#{@tc_user_share}mbit"
            this_user_limit="#{@tc_user_limit}mbit"
            this_user_quantum=@tc_user_quantum
          end

          # Overall class for the gear
          f.puts %Q[class add dev #{@tc_if} parent 1:1 classid 1:#{netclass} htb rate #{this_user_share} ceil #{this_user_limit} quantum #{this_user_quantum}]

          # Specific constraints within the gear's limit
          f.puts %Q[qdisc add dev #{@tc_if} parent 1:#{netclass} handle #{netclass}: htb default 0]
          f.puts %Q[class add dev #{@tc_if} parent #{netclass}: classid #{netclass}:2 htb rate 128kbit ceil 256kbit quantum #{@tc_min_quantum}]
          f.puts %Q[class add dev #{@tc_if} parent #{netclass}: classid #{netclass}:3 htb rate  12kbit ceil  24kbit quantum #{@tc_min_quantum}]
          f.puts %Q[filter add dev #{@tc_if} parent #{netclass}: protocol ip prio 10 u32 match ip dport 587 0xffff flowid #{netclass}:2]
          f.puts %Q[filter add dev #{@tc_if} parent #{netclass}: protocol ip prio 10 u32 match ip dport  25 0xffff flowid #{netclass}:3]
          f.puts %Q[filter add dev #{@tc_if} parent #{netclass}: protocol ip prio 10 u32 match ip dport 465 0xffff flowid #{netclass}:3]
        end

        def stopuser_impl(uuid, pwent, netclass, f)
          f.puts("class del dev #{@tc_if} parent 1:1 classid 1:#{netclass}")
        end

        def with_tc_loaded
          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc qdisc show dev #{@tc_if}", :chdir=>"/")
          if out.include?("qdisc htb 1:")
            if block_given?
              yield
            end
          else
            raise RuntimeError, "no htb qdisc on #{@tc_if}"
          end
        end

        def statususer(uuid, pwent, netclass)
          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc -s class show dev #{@tc_if} classid 1:#{netclass}", :chdir=>"/")
          if out.empty?
            raise ArgumentError, "tc not configured for user #{uuid}"
          else
            @output << out
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
          f.puts %Q[qdisc add dev #{@tc_if} root handle 1: htb]
          f.puts %Q[class add dev #{@tc_if} parent 1: classid 1:1 htb rate #{@tc_max_bandwidth}mbit]
          f.puts %Q[filter add dev #{@tc_if} parent 1: protocol ip prio 10 handle 1: cgroup]
          with_all_users do |uuid, pwent, netclass|
            @output << "Starting tc for #{uuid}: "
            startuser_impl(uuid, pwent, netclass, f)
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
          f.puts %Q[qdisc del dev #{@tc_if} root]
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
            parse_valid_user(uuid) do |uuid, pwent, netclass|
              with_tc_batch do |f|
                startuser_impl(uuid, pwent, netclass, f)
              end
            end
          end
        end

        def stopuser(uuid)
          @output << "Stopping tc for #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |uuid, pwent, netclass|
              with_tc_batch do |f|
                stopuser_impl(uuid, pwent, netclass, f)
              end
            end
          end
        end

        def restartuser(uuid)
          @output << "Restarting user #{uuid}: "
          synchronized do
            parse_valid_user(uuid) do |uuid, pwent, netclass|
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
            parse_valid_user(uuid) do |uuid, pwent, netclass|
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
            parse_valid_user(uuid) do |uuid, pwent, netclass|
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
            parse_valid_user(uuid) do |uuid, pwent, netclass|
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

        def status(uuid=nil)
          @output << "Bandwidth shaping status: "
          with_tc_loaded do
            if uuid
              parse_valid_user(uuid) do |uuid, pwent, netclass|
                statususer(uuid, pwent, netclass)
              end
            else
              out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc -s qdisc show dev #{@tc_if}", :chdir=>"/")
              @output << out
              out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("tc -s class show dev #{@tc_if}", :chdir=>"/")
              @output << out
            end
          end
        end

      end

    end
  end
end
