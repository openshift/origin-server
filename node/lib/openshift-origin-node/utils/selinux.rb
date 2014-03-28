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
require 'openshift-origin-common/utils/etc_utils'
require 'openshift-origin-node/utils/node_logger'

module Selinux
  class Context_s_t
    include Comparable

    # Comparison excluding MCS label
    #
    # @param other [Context_s_t] context being compared against
    def <=>(other)
      test = Selinux.context_user_get(self) <=> Selinux.context_user_get(other)
      return test unless 0 == test

      test = Selinux.context_role_get(self) <=> Selinux.context_role_get(other)
      return test unless 0 == test

      Selinux.context_type_get(self) <=> Selinux.context_type_get(other)
    end

    # Convert context to string
    def to_s
      Selinux.context_str(self)
    end
  end
end

module OpenShift
  module Runtime
    module Utils
      class SELinux

        @@DEF_RUN_USER  = 'unconfined_u'
        @@DEF_RUN_ROLE  = 'system_r'
        @@DEF_RUN_TYPE  = 'openshift_t'
        @@DEF_RUN_LABEL = 's0'

        @@DEF_MCS_SET_SIZE   = 1024       # baked into SELinux
        @@DEF_MCS_GROUP_SIZE = 2          # 2 is historical OpenShift value
        @@DEF_MCS_UID_OFFSET = 0
        @@DEF_MLS_NUM        = 0          # 0 unless MLS in use

        @@mutex              = Mutex.new  # protect matchpathcon context

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
              uid = EtcUtils.uid(name)
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
          expected, actual = path_context(path)
          Selinux.context_range_set(expected, label) unless label.nil?
          Selinux.context_type_set(expected, type) unless type.nil?
          Selinux.context_role_set(expected, role) unless role.nil?
          Selinux.context_user_set(expected, user) unless user.nil?

          range_eq = Selinux.context_range_get(expected) == Selinux.context_range_get(actual)
          return if expected == actual && range_eq
          return if -1 != Selinux.lsetfilecon(path, expected.to_s)

          err = "Could not set the file context #{expected} on #{path}"
          NodeLogger.logger.error(err)
          raise Errno::EINVAL.new(err)
        end

        # Retrieve the default context for an object on the file system
        #
        # @param path [String] path of file or directory
        # @return [Array<Context_s_t, Context_s_t>] The expected context and actual context
        def self.path_context(path)
          matchpathcon_update

          mode     = File.lstat(path).mode & 07777
          actual   = Selinux.lgetfilecon(path)
          expected = -1
          @@mutex.synchronize { expected = Selinux.matchpathcon(path, mode) }

          if -1 == expected
            if -1 == actual
              err = "Could not read or determine the file context for #{path}"
              NodeLogger.logger.error(err)
              raise Errno::EINVAL.new(err)
            else
              expected = actual
            end
          end

          return Selinux.context_new(expected[1]), Selinux.context_new(actual[1])
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

        @@matchpathcon_files_mtimes = Hash.new
        FILE_CONTEXT_PATH           = Selinux.selinux_file_context_path + '*'

        #
        # Public: Update the file context database cache
        #
        def self.matchpathcon_update
          @@mutex.synchronize do
            mtimes = Dir[FILE_CONTEXT_PATH].collect { |f| File.stat(f).mtime }

            if mtimes != @@matchpathcon_files_mtimes
              Selinux.matchpathcon_fini unless @@matchpathcon_files_mtimes.empty?

              NodeLogger.logger.debug('The file context database is being reloaded.')
              Selinux.matchpathcon_init(nil)
              @@matchpathcon_files_mtimes = mtimes
            end
          end
        end

      end
    end
  end
end

