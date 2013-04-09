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
      @@DEF_MLS_NUM    =    0  # 0 unless MLS in use


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
            mcs_label = mcs.sort.map { |i| "c#{i}" }.join(",")
            mls_label = "s#{mls_num}"

            yielder.yield([iuid, "#{mls_label}:#{mcs_label}"])
            iuid +=1
          end

        end
      end

      # Determine the MCS label for a given index
      #
      # @param [Integer] The uid
      # @return [String] The SELinux MCS label
      def self.get_mcs_label(uid)
        config = OpenShift::Config.new

        group_size= (config.get("SELINUX_MCS_GROUP_SIZE") || @@DEF_MCS_GROUP_SIZE).to_i
        uid_offset= (config.get("SELINUX_MCS_UID_OFFSET") || @@DEF_MCS_UID_OFFSET).to_i

        if uid < uid_offset + group_size - 1
          raise ArgumentError, "Supplied UID must be greater than #{uid_offset + set_size - 1}"
        end

        mcs_labels.each do |tuid, label|
          if uid == tuid
            return label
          end
        end
        raise ArgumentError, "Supplied UID was too large for MCS set parameters: #{uid}"
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
      # Ex: set_mcs_label_r("s0:c1,c2", Dir.glob("/path/to/gear/*"))
      #
      def self.set_mcs_label_r(label, *paths)
        set_mcs_label(label) do |f|
          paths.flatten.each do |top_path|
            Find.find(top_path) do |path|
              f.call(path)
            end
          end
        end
      end


      #
      # Private: Single shot call to set mcs label for a specific
      # file.
      #
      def self.set_mcs_label_single(label, path)
        mode = File.lstat(path).mode & 07777
        context = Selinux.matchpathcon(path, mode)
        if context == -1
          # We cannot get the real errno out of the C bindings, use EINVAL.
          raise Errno::EINVAL.new(path)
        end
        context = Selinux.context_new(context[1])
        Selinux.context_range_set(context, label)
        context = Selinux.context_str(context)
        if Selinux.lsetfilecon(path, context) == -1
          raise Errno::EINVAL.new(path)
        end
      end


      #
      # Public: Compare an SELinux context aginst expected values.
      #
      # The type, role and user may be an array of allowed values or nil to use defaults.
      #
      def self.is_con?(context, label, type=nil, role=nil, user=nil)
        comp_context = Selinux.context_new(context)

        if type.nil?
          comp_type = [@@DEF_RUN_TYPE]
        else
          comp_type = [type].flatten
        end

        if role.nil?
          comp_role = [@@DEF_RUN_ROLE]
        else
          comp_role = [role].flatten
        end

        if user.nil?
          comp_user = [@@DEF_RUN_USER]
        else
          comp_user = [user].flatten
        end

        (label == Selinux.context_range_get(comp_context) &&
         comp_type.include?(Selinux.context_type_get(comp_context)) &&
         comp_role.include?(Selinux.context_role_get(comp_context)) &&
         comp_user.include?(Selinux.context_role_get(comp_context)))  
      end

      #
      # Public: Validate whether we are running in the context of an SELinux label.
      #
      # The type, role and user may be an array of allowed values or nil to use defaults.
      #
      def self.is_runcon?(label, type=nil, role=nil, user=nil)
        context = Selinux.getcon
        is_con?(context[1], label, type, role, user)
      end

      #
      # Public: Validate whether the execution context matches an SELinux label.
      #
      # The type, role and user may be an array of allowed values or nil to use defaults.
      #
      # If the label is nil, then compare whether its set to the process default.
      #
      def self.is_execcon?(label=nil, type=nil, role=nil, user=nil)
        context = Selinux.getexeccon
        if context == 0
          return label.nil?
        end
        is_con?(context[1], label, type, role, user)
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


      #################################  DEPRECATED METHODS #####################################

      #
      # Deprecated: Change SELinux execution context of forked processes
      #
      # The type, role and user may be nil to use defaults.
      #
      # If the label is nil, then the process defaults will be used.
      #
      # If a block is provided, the original context is restored after
      # the block and the return value is the value of the block.
      #
      # If no block is provided, the return value is the original context.
      #
      # WARNING: Multiple threads that exec will step on each other.
      # Fork first.
      #
      def self.setexeccon(label, type=nil, role=nil, user=nil)
        old_context = nil
        context = Selinux.getexeccon
        if context == 0
          context = nil
        end

        if context.nil? or not is_con?(context, label, type, role, user)
          old_context = context

          context = context_from_defaults(label, type, role, user)

          setexeccon_s(context)
        end

        if block_given?
          begin
            return yield(context)
          ensure
            setexeccon_s(old_context)
          end
        else
          return old_context
        end
      end

      #
      # Deprecated: Set execution context to the specified label.
      #
      # Typically used after calling setexeccon to restore the old label.
      #
      def self.setexeccon_s(context)
        if Selinux.setexeccon(context) != 0
          raise Errno::EINVAL.new(context)
        end
      end

      #
      # Deprecated: Change SELinux context of the current process.
      #
      # The type, role and user may be nil to use defaults.
      #
      # If a block is provided, the original context is restored after
      # the block and the return value is the value of the block.
      #
      # If no block is provided, the return value is the original context
      # and can be reset with Selinux.setcon.
      #
      # WARNING: Complications with threads.  See man setcon(3).
      #
      def self.setcon(label, type=nil, role=nil, user=nil)
        old_context = nil
        context = Selinux.getcon[1]
        if not is_con?(context, label, type, role, user)
          old_context = context

          context = context_from_defaults(label, type, role, user)

          setcon_s(context)
        end

        if block_given?
          begin
            return yield(context)
          ensure
            if not old_context.nil?
              setcon_s(old_context)
            end
          end
        else
          return old_context
        end
      end

      #
      # Deprecated: Set context to the specified label.
      #
      # Typically used after calling setcon to restore the old label.
      #
      def self.setcon_s(context)
        if Selinux.setcon(context) != 0
          raise Errno::EINVAL.new(context)
        end
      end

    end
  end
end

