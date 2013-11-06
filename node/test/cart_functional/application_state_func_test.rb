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
require_relative '../test_helper'
require "etc"
require "fileutils"

module OpenShift
  class ApplicationStateFunctionalTest < NodeTestCase
    def setup
      @uid     = 5907
      @homedir = "/var/tmp-tests/#@uid"
      @runtime_dir = File.join(@homedir, %w{app-root runtime})

      # polyinstantiation makes creating the homedir a pain...
      FileUtils.rm_r @homedir if File.exist?(@homedir)
      FileUtils.mkpath(@runtime_dir)
      FileUtils.mkdir_p @homedir
      %x{useradd -u #@uid -d #@homedir #@uid 1>/dev/null 2>&1}
      %x{chown -R #@uid:#@uid #@homedir}
      FileUtils.mkpath(File.join(@homedir, '.tmp', @uid.to_s))
      FileUtils.chmod(0, File.join(@homedir, '.tmp'))

      @container = ::OpenShift::Runtime::ApplicationContainer.new(@uid.to_s, @uid.to_s, @uid,
                                                                  @uid.to_s, @uid.to_s, "xyz", nil, nil, nil)
    end

    def teardown
      %x{userdel #@uid 1>/dev/null}
      %x{rm -rf #@homedir}
    end

    def test_set_get
      skip "#{__method__} requires root permissions"  if 0 != Process.uid

      config = mock('OpenShift::Config')
      config.stubs(:get).returns(nil)
      config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp/tests")
      ::OpenShift::Config.stubs(:new).returns(config)



      # .state file is missing
      state = ::OpenShift::Runtime::Utils::ApplicationState.new(@container)
      assert_equal ::OpenShift::Runtime::State::UNKNOWN, state.value

      # .state file is created
      state.value = ::OpenShift::Runtime::State::NEW
      assert_equal ::OpenShift::Runtime::State::NEW, state.value

      # .state file is updated
      state.value = ::OpenShift::Runtime::State::STARTED
      assert_equal ::OpenShift::Runtime::State::STARTED, state.value

      stats = File.stat(File.join(@runtime_dir, ".state"))
      assert_equal @uid, stats.uid
    end
  end
end
