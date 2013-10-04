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
require 'openshift-origin-common/config'
require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Runtime
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


        #
        # Public: Return an enumerator which yields each UID -> MCS label combination.
        #
        # Provides a more efficient way to iterate through all of the
        # available ones than re-running the combinations each time.
        #
        def self.mcs_labels
          Enumerator.new do |yielder|
            config = ::OpenShift::Config.new

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

        #
        # Public: Determine the MCS label for a given index
        #
        # @param [Integer] The user name or uid
        # @return [String] The SELinux MCS label
        def self.get_mcs_label(name)
          config = ::OpenShift::Config.new

          set_size  = (config.get("SELINUX_MCS_SET_SIZE")   || @@DEF_MCS_SET_SIZE).to_i
          group_size= (config.get("SELINUX_MCS_GROUP_SIZE") || @@DEF_MCS_GROUP_SIZE).to_i
          uid_offset= (config.get("SELINUX_MCS_UID_OFFSET") || @@DEF_MCS_UID_OFFSET).to_i
          mls_num   = (config.get("SELINUX_MLS_NUM")        || @@DEF_MLS_NUM).to_i


          begin
            if name.to_i.to_s == name.to_s
              uid = name.to_i
            else
              uid = Etc.getpwnam(name.to_s).uid
            end
          rescue ArgumentError, TypeError, NoMethodError
            raise ArgumentError, "Argument must be a numeric UID or existing username: #{name}"
          end

          if uid < uid_offset + group_size - 1
            raise ArgumentError, "Argument must resolve to a UID greater than #{uid_offset + group_size - 1}: #{name}"
          end

          if group_size == 2
            if uid < uid_offset + set_size * ( set_size - 1) / 2
              # offset uid
              ouid = uid - uid_offset
              # Quadratic formula
              a = 1
              # This is actually negative b, which is what you want
              b = 2 * set_size - 1
              c = ( 2 * ouid - 2 )

              # Root of the equation
              root = ((b - Math::sqrt(b**2 - 4*a*c)) / (2 * a)).to_i
              # remainder
              remainder = (ouid - ( 2*set_size - root - 1 ) * root / 2) + root
              return "s#{mls_num}:c#{root},c#{remainder}"
            end
          else
            mcs_labels.each do |tuid, label|
              if uid == tuid
                return label
              end
            end
          end
          raise ArgumentError, "Argument resolved to a UID too large for MCS set parameters: #{uid}"
        end

        #
        # Public: Set the context of a single file or directory.
        #
        # Where a portion of the context is not provided on the command
        # line, it will be determined from the file context database or
        # the file itself.
        #
        def self.chcon(path, label=nil, type=nil, role=nil, user=nil)
          matchpathcon_update
          mode = File.lstat(path).mode & 07777
          old_context = Selinux.lgetfilecon(path)
          context = Selinux.matchpathcon(path, mode)
          if context == -1
            if old_context == -1
              err = "Could not read or determine the file context for #{path}"
              NodeLogger.logger.error(err)
              raise Errno::EINVAL.new(err)
            else
              context = old_context
            end
          end
          context = Selinux.context_new(context[1])
          Selinux.context_range_set(context, label) unless label.nil?
          Selinux.context_type_set(context, type)   unless type.nil?
          Selinux.context_role_set(context, role)   unless role.nil?
          Selinux.context_user_set(context, user)   unless user.nil?
          context = Selinux.context_str(context)
          if context != old_context[1]
            if Selinux.lsetfilecon(path, context) == -1
              err = "Could not set the file context #{context} on #{path}"
              NodeLogger.logger.error(err)
              raise Errno::EINVAL.new(err)
            end
          end
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
          paths.flatten.each do |path|
            chcon(path, label)
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
          paths.flatten.each do |path|
            Find.find(path) do |fpath|
              chcon(fpath, label)
            end
          end
        end

        #
        # Public: Clear the SELinux context of any MCS label.
        #
        def self.clear_mcs_label(*paths)
          set_mcs_label(nil, *paths)
        end

        #
        # Public: Recursively clear the SELinux context of any MCS label.
        #
        def self.clear_mcs_label_R(*paths)
          set_mcs_label_R(nil, *paths)
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
          Selinux.getcon[1]
        end

        private

        #
        # Private: Update the file context database cache
        #
        @@matchpathcon_files_mtimes = Hash.new
        def self.matchpathcon_update
          new_files_mtimes = Hash.new
          Dir.glob(Selinux.selinux_file_context_path + '*').each do |f|
            new_files_mtimes[f] = File.stat(f).mtime
          end

          if new_files_mtimes != @@matchpathcon_files_mtimes
            if not @@matchpathcon_files_mtimes.empty?
              Selinux.matchpathcon_fini
            end
            NodeLogger.logger.debug("The file context database is being reloaded.")
            Selinux.matchpathcon_init(nil)
            @@matchpathcon_files_mtimes = new_files_mtimes
          end
        end

      end
    end
  end
end

