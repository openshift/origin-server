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

require 'logger'
require 'fileutils'
require 'openshift-origin-common/config'

module OpenShift
  module NodeLogger
    PROFILES = {
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

    def self.build_logger(profile)
      begin
        # Use defaults
        log_file  = profile[:default_file]
        log_level = profile[:default_level]

        # Override defaults with configs if possible
        begin
          config           = OpenShift::Config.new
          config_log_file  = config.get(profile[:file_config])
          config_log_level = config.get(profile[:level_config])

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
        logger
      rescue Exception => e
        # If all else fails, use a STDOUT logger
        Logger.new(STDERR).error { "Failed to create logger; falling back to STDOUT: #{e.message}" }
        Logger.new(STDOUT)
      end
    end

    def logger
      NodeLogger.logger
    end

    def self.logger
      @logger ||= self.build_logger(PROFILES[:standard])
    end

    def self.logger_rebuild
      @logger = self.build_logger(PROFILES[:standard])
    end

    def trace_logger
      NodeLogger.trace_logger
    end

    def self.trace_logger
      @trace_logger ||= self.build_logger(PROFILES[:trace])
    end

    def self.trace_rebuild
      @trace_logger = self.build_logger(PROFILES[:trace])
    end

  end
end
