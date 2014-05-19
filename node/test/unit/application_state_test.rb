#--
# Copyright 2013-2014 Red Hat, Inc.
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
require 'fileutils'
require 'yaml'

class ApplicationStateTest < OpenShift::NodeTestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @uuid     = 'f5586d7e690e4a7ea71da1507d60c192'
    @state_file = File.join('/tmp', @uuid, 'app-root', 'runtime', '.state')
    @state_dir  = File.dirname(@state_file).tap{ |dir|
      FileUtils.mkdir_p( dir )
    }

    @config.stubs(:get).with('GEAR_BASE_DIR').returns('/tmp')

    @good_state     = "building"
    @bad_state      = "asdf"
    @unknown_state  = "unknown"

    # Set up the container
    @uid  = 5502
    @app_name  = 'ApplicatioStateTestCase'
    @gear_name = @uuid
    @namespace = 'jwh201204301647'
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    FileUtils.rm_rf(File.join('/tmp', @uuid))
  end

  def new_state(uuid)
    Etc.stubs(:getpwnam).returns(
      OpenStruct.new(
        uid: @uid.to_i,
        gid: @uid.to_i,
        gecos: "OpenShift guest",
        dir: "/tmp/#{@uuid}"
      )
    )

    container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, @app_name, @uuid, @namespace, nil, nil, nil)
    OpenShift::Runtime::Utils::ApplicationState.new(container)
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
    PathUtils.expects(:oo_chown).with(@uid, @uid, @state_file).once()
    instance = mock()
    instance.expects(:get_mcs_label).with(@uid).once().returns('test label')
    instance.expects(:set_mcs_label).with('test label', @state_file).once()
    OpenShift::Runtime::Utils::SelinuxContext.stubs(:instance).returns(instance)

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
    OpenShift::Runtime::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^#{Regexp.escape("Failed to get state: #{@uuid} [#{@state_file}]")}/),
      regexp_matches(/Permission denied$/)
    ))

    File.stubs(:open).raises(Errno::EACCES.new(@state_file))
    new_state(@uuid).tap { |state|
      assert_equal @unknown_state, state.value
    }
  end

  def test_get_value_error_runtime
    OpenShift::Runtime::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^#{Regexp.escape("Failed to get state: #{@uuid} [#{@state_file}]")}/),
      regexp_matches(/asdf$/)
    ))

    File.stubs(:open).raises("asdf")
    new_state(@uuid).tap { |state|
      assert_equal @unknown_state, state.value
    }
  end

end
