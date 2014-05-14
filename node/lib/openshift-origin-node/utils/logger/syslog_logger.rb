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

require 'openshift-origin-node/utils/logger/logger_support'
require 'syslog'

module OpenShift
  module Runtime
    module NodeLogger
      #
      # This NodeLogger implementation is backed by the Ruby stdlib +syslog+ package.
      #
      # The priority threshold is configured by the +PLATFORM_SYSLOG_THRESHOLD+ config key,
      # which is a string matching one of the log priority values specified in the Ruby
      # syslog package:
      #
      #   http://ruby-doc.org/stdlib-1.9.3/libdoc/syslog/rdoc/Syslog.html#method-c-log
      #
      # Logs are written using the facility defined by the
      # +PLATFORM_SYSLOG_FACILITY+ config value (default: LOG_LOCAL0).
      #
      # If the +PLATFORM_SYSLOG_TRACE_ENABLED+ config value is +1+, +trace+ logs
      # will be written using the +LOG_DEBUG+ priority and the facility defined
      # by the +PLATFORM_SYSLOG_TRACE_FACILITY+ config value (default:
      # LOG_LOCAL1).
      #
      # Note: This implementation does not support deferred log entry evaluation. Any blocks
      # passed to log methods will be immediately evaluated.
      class SyslogLogger
        include LoggerSupport

        def initialize(config=nil)
          @config = config
          @trace_enabled = (@config.get('PLATFORM_SYSLOG_TRACE_ENABLED') || '1').to_i == 1

          @threshold = get_syslog_const('PLATFORM_SYSLOG_THRESHOLD', 'LOG_DEBUG')
          @facility = get_syslog_const('PLATFORM_SYSLOG_FACILITY', 'LOG_LOCAL0')
          @trace_facility = get_syslog_const('PLATFORM_SYSLOG_TRACE_FACILITY', 'LOG_LOCAL1')

          reinitialize
        end

        def reinitialize
          Syslog.open('openshift-platform', Syslog::LOG_PID, @facility) unless Syslog.opened?
          Syslog.mask = Syslog::LOG_UPTO(@threshold)
        end

        def info(*args, &block)
          dispatch(Syslog::LOG_INFO, *args, &block)
        end

        def debug(*args, &block)
          dispatch(Syslog::LOG_DEBUG, *args, &block)
        end

        def warn(*args, &block)
          dispatch(Syslog::LOG_WARNING, *args, &block)
        end

        def error(*args, &block)
          dispatch(Syslog::LOG_ERR, *args, &block)
        end

        def fatal(*args, &block)
          dispatch(Syslog::LOG_CRIT, *args, &block)
        end

        def trace(*args, &block)
          return unless @trace_enabled
          dispatch(@trace_facility | Syslog::LOG_DEBUG, *args, &block)
        end

        private
        def dispatch(level, *args, &block)
          Syslog.log(level, '%s', build_entry(*args, &block))
        end

        # Callers might send a block rather than a string to log, intending
        # to take advantage of deferred evaluation capabilities of the underlying
        # logger impl; however, we aren't going to do that here, so call any
        # block (preferring any string argument supplied).
        private
        def build_entry(*args, &block)
          entry = if args[0]
            args[0].to_s
          elsif block
            block.call
          end
          format(entry || '')
        end

        private
        def get_syslog_const(key, default)
          begin
            value = @config.get(key) || default
            Syslog.const_get(value)
          rescue Exception => e
            raise "Invalid #{key} config value: #{value}"
          end
        end
      end
    end
  end
end
