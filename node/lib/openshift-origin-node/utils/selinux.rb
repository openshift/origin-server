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
require 'selinux'
require 'find'
require 'openshift-origin-common'

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
      # If a block is provided, it will yield a function to call in a
      # set of paths to properly set the MCS label.  This allows
      # efficient caching of the file context table with efficient use
      # of enumerators like Find.
      #
      def self.set_mcs_label(label, *paths)
        Selinux.matchpathcon_init(nil)
        begin
          paths.flatten.each do |path|
            set_mcs_label_single(label, path)
          end
          if block_given?
            yield(lambda { |passed_path| set_mcs_label_single(label, passed_path) })
          end
        ensure
          Selinux.matchpathcon_fini
        end
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
        set_mcs_label(label) do |f|
          paths.flatten.each do |top_path|
            Find.find(top_path) do |path|
              f.call(path)
            end
          end
        end
      end

      #
      # Public: Clear the SELinux context of any MCS label.
      #
      def self.clear_mcs_label(*paths)
        config = OpenShift::Config.new
        mls_num   = (config.get("SELINUX_MLS_NUM")        || @@DEF_MLS_NUM).to_i
        set_mcs_label("s#{mls_num}", *paths)
      end

      #
      # Public: Recursively clear the SELinux context of any MCS label.
      #
      def self.clear_mcs_label_R(*paths)
        config = OpenShift::Config.new
        mls_num   = (config.get("SELINUX_MLS_NUM")        || @@DEF_MLS_NUM).to_i
        set_mcs_label_R("s#{mls_num}", *paths)
      end

      #
      # Private: Single shot call to set mcs label for a specific
      # file.
      #
      def self.set_mcs_label_single(label, path)
        mode = File.lstat(path).mode & 07777
        context = Selinux.matchpathcon(path, mode)
        if context == -1
          context = Selinux.lgetfilecon(path)
        end
        context = Selinux.context_new(context[1])
        Selinux.context_range_set(context, label)
        context = Selinux.context_str(context)
        if Selinux.lsetfilecon(path, context) == -1
          raise Errno::EINVAL.new(path)
        end
      end

      #
      # Public: Create a context from defaults.
      #
      def self.context_from_defaults(label=nil, type=nil, role=nil, user=nil)
        context = Selinux.context_new("#{@@DEF_RUN_USER}:#{@@DEF_RUN_ROLE}:#{@@DEF_RUN_TYPE}:#{@@DEF_RUN_LABEL}")
        Selinux.context_range_set(context, label) unless label.nil?
        Selinux.context_type_set(context, type) unless type.nil?
        Selinux.context_role_set(context, role) unless role.nil?
        Selinux.context_user_set(context, user) unless user.nil?
        Selinux.context_str(context)
      end


      #
      # Public: Get the current context
      #
      def self.getcon
        Selinux.getcon[1]
      end

    end
  end
end

