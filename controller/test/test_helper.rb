#--
# Copyright 2014 Red Hat, Inc.
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

require 'minitest/autorun'

require_relative '../../node/lib/openshift-origin-node'
require_relative '../../node/lib/openshift-origin-node/utils/node_logger'
require_relative '../../node/lib/openshift-origin-node/utils/logger/stdout_logger'
require_relative '../../node/lib/openshift-origin-node/model/ident'
require_relative '../../node/test/support/functional_api'


module OpenShift

  # A bare test case class for tests which need to start
  # without any previous stubs or setup
  class CartridgeTestCase < MiniTest::Unit::TestCase
    include Test::Unit::Assertions
    include OpenShift::Runtime::NodeLogger

    def before_setup
      OpenShift::Runtime::NodeLogger.set_logger(OpenShift::Runtime::NodeLogger::StdoutLogger.new)
      super
    end

  end

end
