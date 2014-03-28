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
      # This NodeLogger implementation is backed by the Ruby stdlib +syslog+ package. Logs
      # are written using the +Syslog::LOG_LOCAL0+ facility.
      #
      # The priority threshold is configured by the +PLATFORM_SYSLOG_THRESHOLD+ config key,
      # which is a string matching one of the log priority values specified in the Ruby
      # syslog package:
      #
      #   http://ruby-doc.org/stdlib-1.9.3/libdoc/syslog/rdoc/Syslog.html#method-c-log
      #
      # If the +PLATFORM_SYSLOG_TRACE_ENABLED+ config value is +1+, +trace+ logs
      # will be written using the +LOG_DEBUG+ priority.
      #
      # Note: This implementation does not support deferred log entry evaluation. Any blocks
      # passed to log methods will be immediately evaluated.
      class SyslogLogger
        include LoggerSupport

        def initialize(config=nil)
          @config = config
          @trace_enabled = (@config.get('PLATFORM_SYSLOG_TRACE_ENABLED') || '1').to_i == 1

          threshold_config = @config.get('PLATFORM_SYSLOG_THRESHOLD') || 'LOG_DEBUG'
          begin
            @threshold = Syslog.const_get(threshold_config)
          rescue Exception => e
            raise "Invalid PLATFORM_SYSLOG_THRESHOLD value '#{threshold_config}': #{e.message}"
          end

          reinitialize
        end

        def reinitialize
          Syslog.open('openshift-platform', Syslog::LOG_PID, Syslog::LOG_LOCAL0) unless Syslog.opened?
          Syslog.mask = Syslog::LOG_UPTO(@threshold)
        end

        def info(*args, &block)
          Syslog.log(Syslog::LOG_INFO, build_entry(*args, &block))
        end

        def debug(*args, &block)
          Syslog.log(Syslog::LOG_DEBUG, build_entry(*args, &block))
        end

        def warn(*args, &block)
          Syslog.log(Syslog::LOG_WARNING, build_entry(*args, &block))
        end

        def error(*args, &block)
          Syslog.log(Syslog::LOG_ERR, build_entry(*args, &block))
        end

        def fatal(*args, &block)
          Syslog.log(Syslog::LOG_CRIT, build_entry(*args, &block))
        end

        def trace(*args, &block)
          return unless @trace_enabled
          Syslog.log(Syslog::LOG_DEBUG, build_entry(*args, &block))
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
      end
    end
  end
end
