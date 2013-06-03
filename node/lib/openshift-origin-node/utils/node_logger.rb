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
require 'openshift-origin-node/utils/logger/split_trace_logger'
require 'openshift-origin-node/utils/logger/null_logger'
require 'openshift-origin-node/utils/logger/stdout_logger'

module OpenShift
  #
  # This class provides a central logging facility for all node operations.
  #
  # The specific logger implementation used is created lazily upon first reference
  # to +logger+. The logger implementation is obtained by reading the +PLATFORM_LOG_CLASS+
  # key from +OpenShift::Config+, which is assumed to be the string name of the logger
  # class to instantiate. The class is assumed to be in the +OpenShift::NodeLogger+ module.
  #
  # If no logger class is configured, the +OpenShift::NodeLogger::SplitTraceLogger+ will be
  # used by default.
  #
  # Logger implementations are expected to confirm to the following simple interface:
  #
  #   module OpenShift
  #     module NodeLogger
  #       class CustomLogger
  #         def initialize(config, context); end
  #
  #         def info(*args, &block); end
  #         def warn(*args, &block); end
  #         def error(*args, &block); end
  #         def fatal(*args, &block); end
  #         def debug(*args, &block); end
  #         def trace(*args, &block); end
  #
  #         def reinitialize; end
  #       end
  #     end
  #   end
  #
  # NodeLogger maintains a +context+ Hash which is passed to logger implementations. Callers
  # may set and remove keys from the context at-will, to provide information such as transaction
  # IDs or any other data which may be useful for loggers. The context object is NOT thread-safe.
  #
  # A +disable+ method is provided for convenience to initialize NodeLogger with the +NullLogger+,
  # effectively disabling logging. This is equivalent to using external configuration, but provides
  # a programmatic entrypoint.
  #
  # Example:
  #
  #   require 'node_logger'
  #
  #   NodeLogger.logger.warn "A warning"
  #   NodeLogger.logger.info { "A deferred-evaluation log message" }
  #
  #   NodeLogger.context[:tx_id] = 1234
  #   NodeLogger.context.delete(:tx_id)
  #
  #   class MyClass
  #     include NodeLogger
  #
  #     def fun
  #       logger.debug "A message"
  #     end
  #   end
  # 
  module NodeLogger
    DEFAULT_LOGGER_CLASS = "SplitTraceLogger"

    def self.create_logger
      config = self.load_config
      logger_class = config.get("PLATFORM_LOG_CLASS") || DEFAULT_LOGGER_CLASS

      begin
        logger = OpenShift::NodeLogger.const_get(logger_class).new(config, self.context)
      rescue => e
        raise "Couldn't create NodeLogger class #{logger_class}: #{e.message}"
      end

      logger
    end

    def self.load_config
      begin
        config = OpenShift::Config.new
      rescue => e
        raise "Couldn't load NodeLogger configuration: #{e.message}"
      end
    end

    def self.disable
      @logger = NullLogger.new
    end

    def logger
      NodeLogger.logger
    end

    def self.logger
      @logger ||= self.create_logger
    end

    def self.context
      @context ||= {}
    end
  end
end
