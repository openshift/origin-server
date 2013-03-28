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
require "test/unit"
require "mocha"
require "fileutils"
require "openshift-origin-node/utils/application_state"

class ApplicationStateTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @uuid     = 'f5586d7e690e4a7ea71da1507d60c192'
    @state_file = File.join('/tmp', @uuid, 'app-root', 'runtime', '.state')
    @state_dir  = File.dirname(@state_file).tap{ |dir|
      FileUtils.mkdir_p( dir )
    }

    config    = mock('OpenShift::Config')
    config.stubs(:get).with('GEAR_BASE_DIR').returns('/tmp')

    @good_state     = "building"
    @bad_state      = "asdf"
    @unknown_state  = "unknown"

    OpenShift::Config.stubs(:new).returns(config)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    FileUtils.rm_rf(File.join('/tmp', @uuid))
  end

  def new_state(uuid)
    OpenShift::Utils::ApplicationState.new(uuid)
  end

  def get_state
    File.read(@state_file).chomp
  end

  def set_state(state)
    File.open(@state_file, File::WRONLY|File::TRUNC|File::CREAT, 0640) { |file|
      file.write(state)
    }
  end

  def test_initialize
    new_state(@uuid).tap { |state|
      assert_equal @uuid, state.uuid
      assert_equal @state_file, state.instance_variable_get("@state_file")
    }
  end

  def test_set_value
    OpenShift::Utils.expects(:oo_spawn).once().returns(0).with(all_of(
      regexp_matches(/^chown --reference #{@state_dir} #{@state_file};/),
      regexp_matches(/chcon --reference #{@state_dir} #{@state_file}$/)
    ))
    new_state(@uuid).tap { |state|
      state.value = @good_state
    }
    assert_equal @good_state, get_state
  end

  def test_set_invalid_value
    err = assert_raises ArgumentError do
      new_state(@uuid).value = @bad_state
    end

    assert_equal "Invalid state '#{@bad_state}' specified", err.message
  end

  def test_get_value
    set_state(@good_state)

    new_state(@uuid).tap { |state|
      assert_equal @good_state, state.value
    }
  end

  def test_get_value_error_permission
    OpenShift::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^#{Regexp.escape("Failed to get state: #{@uuid} [#{@state_file}]")}/),
      regexp_matches(/Permission denied$/)
    ))

    File.stubs(:open).raises(Errno::EACCES.new(@state_file))
    new_state(@uuid).tap { |state|
      assert_equal @unknown_state, state.value
    }
  end

  def test_get_value_error_runtime
    OpenShift::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^#{Regexp.escape("Failed to get state: #{@uuid} [#{@state_file}]")}/),
      regexp_matches(/asdf$/)
    ))

    File.stubs(:open).raises("asdf")
    new_state(@uuid).tap { |state|
      assert_equal @unknown_state, state.value
    }
  end

end
