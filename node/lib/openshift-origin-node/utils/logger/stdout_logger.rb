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

module OpenShift
  module Runtime
    module NodeLogger
      #
      # This NodeLogger implementation is backed by the Ruby stdlib +logger+ class.
      #
      # NOTE: The +trace+ method is unimplemented.
      #
      class StdoutLogger
        def initialize(config=nil)
          reinitialize
        end

        def reinitialize
          @logger = Logger.new(STDOUT)
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
          # not supported
        end
      end
    end
  end
end
