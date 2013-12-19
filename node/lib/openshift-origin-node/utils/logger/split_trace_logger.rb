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
require 'logger'
require 'fileutils'

module OpenShift
  module Runtime
    module NodeLogger
      #
      # This NodeLogger implementation is backed by the Ruby stdlib +logger+ class, and uses
      # a separate logger instance for +trace+ logging in order to physically segregate messages
      # at the +trace+ level.
      #
      # The logger uses the following config keys:
      #
      #   PLATFORM_LOG_FILE        - The absolute path to the primary log file (default: /var/log/openshift/node/platform.log)
      #   PLATFORM_LOG_LEVEL       - The log level for the primary logger (default: DEBUG)
      #   PLATFORM_TRACE_LOG_FILE  - The absolute path to the trace log file (default: /var/log/openshift/node/platform-trace.log)
      #   PLATFORM_TRACE_LOG_LEVEL - The log level for the trace logger (default: INFO)
      #
      # Note: File IO for the underlying loggers is synchronous.
      #
      class SplitTraceLogger
        include LoggerSupport

        @@DEFAULT_PROFILES = {
          :standard => {
            file_config:   'PLATFORM_LOG_FILE',
            level_config:  'PLATFORM_LOG_LEVEL',
            default_file:  File.join(File::SEPARATOR, %w{var log openshift node platform.log}),
            default_level: Logger::DEBUG
          },
          :trace    => {
            file_config:   'PLATFORM_TRACE_LOG_FILE',
            level_config:  'PLATFORM_TRACE_LOG_LEVEL',
            default_file:  File.join(File::SEPARATOR, %w{var log openshift node platform-trace.log}),
            default_level: Logger::INFO
          }
        }

        def initialize(config, profiles = nil)
          @config = config
          @profiles = profiles || @@DEFAULT_PROFILES

          reinitialize
        end

        def reinitialize
          @logger = build_logger(@profiles[:standard])
          @trace_logger = build_logger(@profiles[:trace])
        end

        def info(*args, &block)
          @logger.info(*args, &block)
        end

        def debug(*args, &block)
          @logger.info(*args, &block)
        end

        def warn(*args, &block)
          @logger.warn(*args, &block)
        end

        def error(*args, &block)
          @logger.error(*args, &block)
        end

        def fatal(*args, &block)
          @logger.fatal(*args, &block)
        end

        def trace(*args, &block)
          @trace_logger.info(*args, &block)
        end


        private

        def build_logger(profile)
          begin
            # Use defaults
            log_file  = profile[:default_file]
            log_level = profile[:default_level]

            # Override defaults with configs if possible
            begin
              config_log_file  = @config.get(profile[:file_config])
              config_log_level = @config.get(profile[:level_config])

              if config_log_level && Logger::Severity.const_defined?(config_log_level)
                log_level = Logger::Severity.const_get(config_log_level)
              end

              if config_log_file
                log_file = config_log_file
              end
            rescue => e
              # just use the defaults
              Logger.new(STDERR).error { "Failed to apply logging configuration #{profile}: #{e.message}" }
            end

            FileUtils.mkpath(File.dirname(log_file)) unless File.exist? File.dirname(log_file)

            orig_umask = File.umask(0)
            file = File.open(log_file, File::WRONLY | File::APPEND| File::CREAT, 0660)
            File.umask(orig_umask)

            file.sync = true

            logger       = Logger.new(file, 5, 10 * 1024 * 1024)
            logger.level = log_level

            logger.formatter = proc do |severity, datetime, progname, msg|
              "#{datetime.strftime("%B %d %H:%M:%S")} #{severity} #{format(msg)}\n"
            end

            logger
          rescue Exception => e
            # If all else fails, use a STDOUT logger
            Logger.new(STDERR).error { "Failed to create logger; falling back to STDOUT: #{e.message}" }
            Logger.new(STDOUT)
          end
        end

      end
    end
  end
end
