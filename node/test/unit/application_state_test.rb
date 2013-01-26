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

require "rubygems"
require "test/unit"
require "mocha/setup"
require "fileutils"
require "openshift-origin-node/utils/application_state"

module OpenShift
  class ApplicationStateTest < Test::Unit::TestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      @uuid = "d0db4f85e531439c94e5263339203f95"
      FileUtils.mkpath(File.join("/tmp", @uuid, "app-root", "runtime"))


    end

    # Called after every test method runs. Can be used to tear
    # down fixture information.

    def teardown
      FileUtils.rm_rf(File.join("/tmp", @uuid))
    end

    def test_set
      config = mock('OpenShift::Config')
      config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")
      OpenShift::Config.stubs(:new).returns(config)

      # .state file is missing
      state = OpenShift::ApplicationState.new(@uuid)
      assert_equal State::UNKNOWN, state.get

      # .state file is created
      state.set(State::NEW)
      assert_equal State::NEW, state.get

      # .state file is updated
      state.set(State::STARTED)
      assert_equal State::STARTED, state.get
    end
  end
end