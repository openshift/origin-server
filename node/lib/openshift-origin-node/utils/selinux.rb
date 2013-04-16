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

require 'etc'
require 'openshift-origin-common'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Utils
    class SELinux

      @@DEF_RUN_USER="unconfined_u"
      @@DEF_RUN_ROLE="system_r"
      @@DEF_RUN_TYPE="openshift_t"
      @@DEF_RUN_LABEL="s0"

      @@DEF_MCS_SET_SIZE   = 1024  # baked into SELinux
      @@DEF_MCS_GROUP_SIZE =    2  # 2 is historical OpenShift value
      @@DEF_MCS_UID_OFFSET =    0
      @@DEF_MLS_NUM    =        0  # 0 unless MLS in use


      # Return an enumerator which yields each UID -> MCS label combination.
      #
      # Provides a more efficient way to iterate through all of the
      # available ones than re-running the combinations each time.
      #
      def self.mcs_labels
        Enumerator.new do |yielder|
          config = OpenShift::Config.new

          set_size  = (config.get("SELINUX_MCS_SET_SIZE")   || @@DEF_MCS_SET_SIZE).to_i
          group_size= (config.get("SELINUX_MCS_GROUP_SIZE") || @@DEF_MCS_GROUP_SIZE).to_i
          uid_offset= (config.get("SELINUX_MCS_UID_OFFSET") || @@DEF_MCS_UID_OFFSET).to_i
          mls_num   = (config.get("SELINUX_MLS_NUM")        || @@DEF_MLS_NUM).to_i

          iuid = uid_offset + group_size - 1

          set_size.times.to_a.combination(group_size) do |c|
            mcs_label = c.sort.map { |i| "c#{i}" }.join(",")
            mls_label = "s#{mls_num}"

            yielder.yield([iuid, "#{mls_label}:#{mcs_label}"])
            iuid +=1
          end

        end
      end

      # Determine the MCS label for a given index
      #
      # @param [Integer] The user name or uid
      # @return [String] The SELinux MCS label
      def self.get_mcs_label(name)
        config = OpenShift::Config.new

        group_size= (config.get("SELINUX_MCS_GROUP_SIZE") || @@DEF_MCS_GROUP_SIZE).to_i
        uid_offset= (config.get("SELINUX_MCS_UID_OFFSET") || @@DEF_MCS_UID_OFFSET).to_i

        begin
          uid = Etc.getpwnam(name.to_s).uid
        rescue ArgumentError, TypeError, NoMethodError
          uid = name.to_i
        end

        if uid < uid_offset + group_size - 1
          raise ArgumentError, "Argument must resolve to a UID greater than #{uid_offset + group_size - 1}: #{name}"
        end

        mcs_labels.each do |tuid, label|
          if uid == tuid
            return label
          end
        end
        raise ArgumentError, "Argument resolved to a UID too large for MCS set parameters: #{uid}"
      end

      #
      # Public: Set the SELinux context with provided MCS label on a
      # given set of files.
      #
      # Acts on the symbolic link itself instead of dereferencing.
      #
      # Globs must be dereferenced but can be provided as an argument.
      # Ex: set_mcs_label("s0:c1,c2", Dir.glob("/path/to/gear/*"))
      #
      def self.set_mcs_label(label, *paths)
        pathargs = paths.flatten.join(" ")
        call_selinux_cmd("/sbin/restorecon #{pathargs}; /usr/bin/chcon -l #{label} #{pathargs}")
      end

      #
      # Public: Recursively set SELinux context with provided MCS
      # label on a given set of files.
      #
      # Will not dereference symbolic links either as a parameter or
      # as a discovered file.
      #
      # Globs must be dereferenced but can be provided as an argument.
      # Ex: set_mcs_label_R("s0:c1,c2", Dir.glob("/path/to/gear/*"))
      #
      def self.set_mcs_label_R(label, *paths)
        pathargs = paths.flatten.join(" ")
        call_selinux_cmd("/sbin/restorecon -R #{pathargs}; /usr/bin/chcon -R -l #{label} #{pathargs}")
      end

      #
      # Public: Clear the SELinux context of any MCS label.
      #
      def self.clear_mcs_label(*paths)
        pathargs = paths.flatten.join(" ")
        call_selinux_cmd("/sbin/restorecon -F #{pathargs}")
      end

      #
      # Public: Recursively clear the SELinux context of any MCS label.
      #
      def self.clear_mcs_label_R(*paths)
        pathargs = paths.flatten.join(" ")
        call_selinux_cmd("/sbin/restorecon -R -F #{pathargs}")
      end


      #
      # Public: Create a context from defaults.
      #
      def self.context_from_defaults(label=nil, type=nil, role=nil, user=nil)
        t_label = (label || @@DEF_RUN_LABEL).to_s
        t_type  = (type  || @@DEF_RUN_TYPE).to_s
        t_role  = (role  || @@DEF_RUN_ROLE).to_s
        t_user  = (user  || @@DEF_RUN_USER).to_s
        "#{t_user}:#{t_role}:#{t_type}:#{t_label}"
      end


      #
      # Public: Get the current context
      #
      def self.getcon
        File.read(File.join('', 'proc', Process.pid.to_s, 'attr', 'current')).strip
      end

      private

      # Private: Calling pattern for selinux
      #
      # Raises exception if the underlying command fails.
      #
      def self.call_selinux_cmd(cmd)
        output = ""
        begin
          out, err, rc = Utils.oo_spawn(cmd, expected_exitstatus: 0)
        rescue ShellExecutionException => e
          NodeLogger.logger.debug("Failed: #{cmd}; rc: #{e.rc}; stdout: #{e.stdout}; stderr: #{e.stderr}")
          raise "Failed: #{cmd}; rc: #{e.rc}; stdout: #{e.stdout}; stderr: #{e.stderr}"
        end
        output << out
        output << err
        output
      end

    end
  end
end

