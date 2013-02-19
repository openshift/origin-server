#--
# Copyright 2010 Red Hat, Inc.
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

require File.expand_path('../coverage_helper.rb', __FILE__)

#require File.expand_path('../../lib/openshift-origin-node', __FILE__)
require 'rubygems'
require 'test/unit'
require 'mocha'

require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module NodeLogger

    def logger
      NodeLogger.logger
    end

    def self.logger
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = Logger::DEBUG
        logger
      end
    end

    def trace_logger
      NodeLogger.trace_logger
    end

    def self.trace_logger
      @trace_logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end
    end
  end
end
