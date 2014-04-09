#--
# Copyright 2013-2014 Red Hat, Inc.
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
require 'singleton'

module Selinux
  # SWIG Selinux Context class
  class Context_s_t
    include Comparable

    # Comparison excluding MCS level
    #
    # @param other [Context_s_t] context being compared against
    # @return [true, false] true if Selinux user, role and type are equal
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
      # Provide safe access to SELinux library
      #
      # libselinux#matchpathcon is written such that there is a thread-local handle
      #   +static __thread struct selabel_handle *hnd+. When #matchpathcon is invoked, it checks to see if the
      #   thread-local handle is NULL. If so, it calls #matchpathcon_init_prefix, which sets a non-NULL value for
      #   the pthread specific destructor_key. Once this is non-NULL, it means that when the thread terminates,
      #   #matchpathcon_fini will execute. When this happens, it frees memory that is NOT declared
      #   +__thread (SELABELSUB *selabelsublist)+. As a result, because there is no mutex guarding access to
      #   +selabelsublist+, it is possible for 1 thread to be calling #matchpathcon (which uses +selabelsublist+)
      #   while another thread is freeing the memory associated with +selabelsublist+, resulting in segfault
      #   either due to an invalid memory address, or an attempt to double free the memory.
      #
      class SelinuxContext
        include Singleton

        # data-holding class for communicating with worker
        # @!attribute id
        #   thread id making request, index for hash
        # @!attribute path
        #   File to query for selinux context query
        # @!attribute mode
        #   File mode used for selinux context query
        # @!attribute context
        #   selinux context results from query
        class MatchPathContext < Struct.new(:id, :path, :mode, :context)
        end

        DefaultUser  = 'unconfined_u'
        DefaultRole  = 'system_r'
        DefaultType  = 'openshift_t'
        DefaultLevel = 's0'

        # @return [Fixnum] 1024 baked into SELinux (node.conf#SELINUX_MCS_SET_SIZE)
        attr_reader :set_size

        # @return [Fixnum] 2 is historical OpenShift value (node.conf#SELINUX_MCS_GROUP_SIZE)
        attr_reader :group_size

        # @return [Fixnum] 0 (node.conf#SELINUX_MCS_UID_OFFSET)
        attr_reader :uid_offset

        # @return [Fixnum] 0 unless MLS in use (node.conf#SELINUX_MLS_NUM)
        attr_reader :mls_num

        def initialize
          @context       = Hash.new
          @context_mutex = Mutex.new
          @query         = ConditionVariable.new
          @response      = ConditionVariable.new

          @thread = matchpathcon_worker

          config     = ::OpenShift::Config.new
          @set_size  = (config.get('SELINUX_MCS_SET_SIZE') || 1024).to_i
          @group_size= (config.get('SELINUX_MCS_GROUP_SIZE') || 2).to_i
          @uid_offset= (config.get('SELINUX_MCS_UID_OFFSET') || 0).to_i
          @mls_num   = (config.get('SELINUX_MLS_NUM') || 0).to_i

        end

        # Instantiate a background thread for holding the connection to the libselinux#matchpath* functions
        #
        # @note This *must* be the only access to the libselinux#matchpath* functions. Otherwise, the library will
        #   seg fault. See above.
        # @see ConditionVariable, Mutex
        #
        # @return [Thread]
        def matchpathcon_worker
          Thread.start do
            # Now we're in a safe place, initialize the matchpathcon context.
            # @note Never do this again anywhere in this process. Or you will be seg faulted.
            Selinux.matchpathcon_init(nil)

            # Yes, this worker will live until the process is killed
            loop do
              # Worker and subscribers synchronize on +mutex+ to ensure one writer at a time changes @context
              @context_mutex.synchronize do

                # @note false wake ups are possible so we sleep until we know there is work queued up
                # Also, @context may not be empty, but all the requests may have been handled and we're
                # just waiting for the callers to pick them up, so make sure we wait if every value's
                # .context is filled in
                while @context.empty? or @context.values.all? { |v| not v.context.nil? }
                  # Wait for a +signal+ from a #matchpathcon call if there is no work queued up for us
                  @query.wait(@context_mutex)
                end

                broadcast = false
                @context.keys.each do |key|
                  # Process all queued requests, Later we'll wakeup all the sleepers...
                  if @context[key].context.nil?
                    # Because we're in the +mutex+ and a subscriber has signaled us, it is safe to call
                    #   libselinux#matchpathcon() and update context hash with results
                    @context[key].context = Selinux.matchpathcon(@context[key].path, @context[key].mode)
                    broadcast             = true
                  end
                end
                # We did some work, so tell anyone who may be waiting
                @response.broadcast if broadcast
              end
            end
          end
        end

        # get the default SELinux security context for the specified path from the file contexts configuration
        #
        # This is the thread safe method that will delegate work to the background thread holding the connection
        #   to the libselinux library.
        #
        # @param path [String] Path to query against
        # @param mode [Fixnum] mode for path
        # @return [Selinux#Context_s_t] default security context associated with the path
        def matchpathcon(path, mode)
          @context_mutex.synchronize do
            # We queue up our request in the hash for processing
            @context[Thread.current.object_id] = MatchPathContext.new(Thread.current.object_id, path, mode)

            # wake up the worker to call the library
            @query.signal

            while @context[Thread.current.object_id].context.nil?
              # wait until the worker publishes any results.
              # @note false wake ups are possible, so we go back to sleep if our results are ready.
              @response.wait(@context_mutex)
            end

            # We have our results! Remove the request and return the results.
            return @context.delete(Thread.current.object_id).context
          end
        end

        # Return an enumerator which yields each UID -> MCS label combination.
        #
        # Provides a more efficient way to iterate through all of the
        # available ones than re-running the combinations each time.
        #
        def mcs_labels
          Enumerator.new do |yielder|
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
        # @param name [String, Integer] The user name or uid
        # @return [String] The SELinux MCS label
        def get_mcs_label(name)
          begin
            uid = EtcUtils.uid(name)
          rescue ArgumentError, TypeError, NoMethodError
            raise ArgumentError, "Argument must be a numeric UID or existing username: #{name}"
          end

          if uid < uid_offset + group_size - 1
            raise ArgumentError, "Argument must resolve to a UID greater than #{uid_offset + group_size - 1}: #{name}"
          end

          if group_size == 2
            if uid < uid_offset + set_size * (set_size - 1) / 2
              # offset uid
              ouid      = uid - uid_offset
              # Quadratic formula
              a         = 1
              # This is actually negative b, which is what you want
              b         = 2 * set_size - 1
              c         = (2 * ouid - 2)

              # Root of the equation
              root      = ((b - Math::sqrt(b**2 - 4*a*c)) / (2 * a)).to_i
              # remainder
              remainder = (ouid - (2*set_size - root - 1) * root / 2) + root
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

        # Set the context of a single file or directory.
        #
        # Where a portion of the context is not provided on the command
        # line, it will be determined from the file context database or
        # the file itself.
        #
        # @param [String] path file to set selinux
        # @param [String] level selinux level to set for path, defaults to OpenShift policy
        # @param [String] type selinux type to set for path, defaults to selinux policy
        # @param [String] role selinux role to set for path, defaults to selinux policy
        # @param [String] user selinux user to set for path, defaults to selinux policy
        def chcon(path, level=nil, type=nil, role=nil, user=nil)
          expected, actual = path_context(path)
          Selinux.context_range_set(expected, level) unless level.nil?
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
        # @param [String] path of file or directory
        # @return [Array<Context_s_t, Context_s_t>] The expected context and actual context
        def path_context(path)
          mode     = File.lstat(path).mode & 07777
          actual   = Selinux.lgetfilecon(path)
          expected = matchpathcon(path, mode)

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

        # Set the SELinux context with provided MCS label on a
        # given set of files.
        #
        # Acts on the symbolic link itself instead of dereferencing.
        #
        # Globs must be dereferenced but can be provided as an argument.
        # @example
        #   set_mcs_label("s0:c1,c2", Dir.glob("/path/to/gear/*"))
        #
        # @param [String] label for files
        # @param [Array<String>] paths for files
        def set_mcs_label(label, *paths)
          paths.flatten.each do |path|
            chcon(path, label)
          end
        end

        # Recursively set SELinux context with provided MCS
        # label on a given set of files.
        #
        # Will not dereference symbolic links either as a parameter or
        # as a discovered file.
        #
        # Globs must be dereferenced but can be provided as an argument.
        # @example
        #   set_mcs_label_R("s0:c1,c2", Dir.glob("/path/to/gear/*"))
        #
        # @param [String] label for files
        # @param [Arrary<Strings>] paths for files
        def set_mcs_label_R(label, *paths)
          paths.flatten.each do |path|
            Find.find(path) do |fpath|
              chcon(fpath, label)
            end
          end
        end

        # Clear the SELinux context of any MCS label.
        #
        def clear_mcs_label(*paths)
          set_mcs_label(nil, *paths)
        end

        # Recursively clear the SELinux context of any MCS label.
        #
        def clear_mcs_label_R(*paths)
          set_mcs_label_R(nil, *paths)
        end

        # Create a context from defaults.
        #
        # @param [String] level selinux level, defaults to OpenShift policy
        # @param [String] type selinux type, defaults to OpenShift policy
        # @param [String] role selinux role, defaults to OpenShift policy
        # @param [String] user selinux user, defaults to OpenShift policy
        def from_defaults(level=nil, type=nil, role=nil, user=nil)
          t_label = (level || DefaultLevel).to_s
          t_type  = (type || DefaultType).to_s
          t_role  = (role || DefaultRole).to_s
          t_user  = (user || DefaultUser).to_s
          "#{t_user}:#{t_role}:#{t_type}:#{t_label}"
        end

        # Get the current context
        #
        # @return [Context_s_t] Selinux context for process
        def getcon
          Selinux.getcon[1]
        end

        # reset Singleton
        # @note Only to be used during testing
        def reset
          Singleton.__init__(self)
        end
      end
    end
  end
end

