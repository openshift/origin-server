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

module OpenShift
  module Runtime
    module NodeLogger
      #
      # This NodeLogger implementation discards all log messages.
      #
      class NullLogger
        def reinitialize
        end

        def drop(*args, &block)
        end

        alias :info :drop
        alias :debug :drop
        alias :warn :drop
        alias :error :drop
        alias :fatal :drop
        alias :trace :drop
      end
    end
  end
end
