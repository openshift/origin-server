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

require 'test_helper'
require "rubygems"
require "etc"
require "test/unit"
require "mocha"
require "fileutils"
require "openshift-origin-node/utils/application_state"
require "openshift-origin-node/utils/shell_exec"

module OpenShift
  class ApplicationStateFunctionalTest < Test::Unit::TestCase

    def setup
      #skip "run_as tests require root permissions"  if 0 != Process.uid
      #File.chmod(0777, 'test/coverage')

      @uid = 1000
      @uuid = `uuidgen -r |sed -e s/-//g`.chomp
      @runtime_dir = File.join("/tmp", @uuid, %w{app-root runtime})
      Utils.oo_spawn("mkdir -p #@runtime_dir",
                  :uid => @uid)
    end

    def teardown
      FileUtils.rm_rf(File.join("/tmp", @uuid))
    end

    def test_set_get
      skip "run_as tests require root permissions"  if 0 != Process.uid

      config = mock('OpenShift::Config')
      config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")
      OpenShift::Config.stubs(:new).returns(config)

      # .state file is missing
      state = OpenShift::Utils::ApplicationState.new(@uuid)
      assert_equal State::UNKNOWN, state.value

      # .state file is created
      state.value = State::NEW
      assert_equal State::NEW, state.value

      # .state file is updated
      state.value = State::STARTED
      assert_equal State::STARTED, state.value

      stats = File.stat(File.join(@runtime_dir, ".state"))
      assert_equal @uid, stats.uid
    end
  end
end
