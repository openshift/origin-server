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

require_relative '../test_helper'

require 'date'
require 'active_support/core_ext/numeric/time'
require 'openshift-origin-node/model/watchman/watchman_plugin'

load Pathname.new(__FILE__).dirname + '../../../node-util/sbin/oo-watchman'

class WatchmanFuncTest < OpenShift::NodeTestCase
  def before_setup
    super

    @uuid = '1f97f91d1e684a52ad29d44bffa8acb3'
    @path = '/tmp/WatchmanFuncTest'
    FileUtils.mkpath(@path)

    create_plugins(@path, @uuid)
  end

  def setup
    @config.stubs(:get).with('WATCHMAN_PLUGIN_DIR', any_parameters).returns(@path)
    @config.stubs(:get).with('RETRY_DELAY', any_parameters).returns(0)
    @config.stubs(:get).with('GEAR_BASE_DIR', '/var/lib/openshift').returns('/var/lib/openshift')

    @gears = mock()
    @gears.stubs(:each).yields(@uuid)
    @gears.stubs(:empty?).returns(false)
  end

  def after_teardown
    FileUtils.rm_r(@path)
    super
  end

  def create_plugins(path, uuid)
    File.open("#{path}/restart.rb", 'w') do |file|
      file.puts %Q(
        require 'date'
        require 'openshift-origin-node/model/watchman/watchman_plugin'

        class RestartPlugin < OpenShift::Runtime::WatchmanPlugin
          def apply(iteration)
            restart("#{uuid}")
          end
        end
      )
    end

    File.open("#{path}/bad_contract.rb", 'w') do |file|
      file.puts %Q(
        require 'openshift-origin-node/model/watchman/watchman_plugin'
        class NoApplyPlugin < OpenShift::Runtime::WatchmanPlugin
        end
      )
    end


    File.open("#{path}/bad_format.rb", 'w') do |file|
      file.puts %Q(
        require 'openshift-origin-node/model/watchman/watchman_plugin'
        class BrokenApplyPlugin < OpenShift::Runtime::WatchmanPlugin
          def apply(iteration)
            raise %Q(Expected Exception: BrokenApplyPlugin)
          end
        end
      )
    end
  end

  def test_one_cache
    watcher = OpenShift::Runtime::Watchman.new(@config, @gears)
    watcher.expects(:cache_incident).with(any_parameters).once
    watcher.apply(false)
  end

  def test_two_cache_one_restart
    watcher = OpenShift::Runtime::Watchman.new(@config, @gears)
    watcher.expects(:restart).with(any_parameters).once
    watcher.apply(false)
    watcher.apply(false)
  end

  def test_two_cache_two_restart
    watcher = OpenShift::Runtime::Watchman.new(@config, @gears)
    watcher.expects(:restart).with(any_parameters).twice
    watcher.retry_delay = 0
    watcher.apply(false)
    watcher.apply(false)
  end

  def test_two_cache_two_restart_with_retries
    watcher = OpenShift::Runtime::Watchman.new(@config, @gears)
    watcher.expects(:restart).with(any_parameters).twice
    watcher.retry_delay = 1
    watcher.apply(false)
    watcher.apply(false)
    sleep 2
    watcher.apply(false)
  end

  def test_five_cache_two_restart_over_period
    watcher = OpenShift::Runtime::Watchman.new(@config, @gears)
    watcher.expects(:restart).with(any_parameters).twice
    watcher.retry_delay  = 1
    watcher.retry_period = 2
    watcher.apply(false)
    watcher.apply(false)
    watcher.apply(false)
    watcher.apply(false)
    sleep 2
    watcher.apply(false)
  end
end
