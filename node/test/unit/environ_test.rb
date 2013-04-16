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
require "openshift-origin-node/utils/environ"

class EnvironTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @uuid         = 'f5586d7e690e4a7ea71da1507d60c192'
    @cart_name    = 'mock-0.0'
    @gear_env     = File.join('/tmp', @uuid, '.env')
    @uservars_env = File.join('/tmp', @uuid, '.env', '.uservars')
    @cart_env     = File.join('/tmp', @uuid, @cart_name, 'env')
    FileUtils.mkpath(@gear_env)
    FileUtils.mkpath(@uservars_env)
    FileUtils.mkpath(@cart_env)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    FileUtils.rm_rf(File.join('/tmp', @uuid))
  end

  # Helper to directly write values to ENV files
  # Send raw = true to manually set file contents
  def write_var(where, name, value, raw = false)
    base = case where
           when :gear
             @gear_env
           when :uservars
             @uservars_env
           when :cart
             @cart_env
           end

    val_str = raw ? value : %Q{export #{name}="#{value}"}
    File.join(base, name).tap{ |file_name|
      File.open(file_name, 'w') { |fd|
        fd.write(val_str)
      }
    }
  end

  # Helper to write gear UUID to ENV file
  def write_uuid
    write_var(:gear, "OPENSHIFT_GEAR_UUID",@uuid)
  end

  # Verify can read one directory of environment variables
  def test_single_directory
    write_uuid

    OpenShift::Utils::Environ.load(@gear_env).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  # Verify we are calling our logger properly if there's a problem loading a file
  def test_load_error_exception
    val_str = %Q{export OPENSHIFT_GEAR_UUID"#@uuid"}
    file_name = write_var(:gear, 'OPENSHIFT_GEAR_UUID', val_str, true)

    # Make sure we get the proper message for NoMethodError
    err = assert_raises NoMethodError do
      nil + 1
    end

    OpenShift::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^Failed to process: #{file_name}/),
      regexp_matches(/\[#{val_str}\]/),
      regexp_matches(/#{Regexp.escape(err.message)}$/)
    ))
    OpenShift::Utils::Environ.load(@gear_env)
  end

  def test_load_error_permission
    file_name = write_uuid

    err_msg = "Permission denied"
    File.stubs(:open).with(any_parameters).raises(Errno::EACCES.new(file_name))
    OpenShift::NodeLogger.logger.expects(:info).once().with(all_of(
      regexp_matches(/^Failed to process: #{file_name}/),
      regexp_matches(/#{Regexp.escape(err_msg)}$/)
    ))
    OpenShift::Utils::Environ.load(@gear_env)
  end

  # Verify can read a gear and cartridge environment variables
  def test_gear_env_v2
    OpenShift::Utils::Sdk.expects(:new_sdk_app?).returns(true)

    write_uuid
    write_var(:uservars, 'OPENSHIFT_USERVAR', 'foo')
    write_var(:cart, 'OPENSHIFT_MOCK_IP', '127.0.0.666')

    # Ensure gear inherits cartridge variables
    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_equal "foo", env['OPENSHIFT_USERVAR']
      assert_nil env['OPENSHIFT_APP_NAME']
    end

    # Ensure cartridge inherits gear variables
    OpenShift::Utils::Environ.for_cartridge(File.join('/tmp', @uuid, @cart_name)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  # Verify can read a gear and cartridge environment variables
  def test_gear_env_v1
    OpenShift::Utils::Sdk.expects(:new_sdk_app?).returns(false)

    write_uuid
    write_var(:uservars, 'OPENSHIFT_USERVAR', 'foo', true)
    write_var(:cart, 'OPENSHIFT_MOCK_IP', '127.0.0.666')

    # Ensure gear inherits cartridge variables
    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_nil env['OPENSHIFT_USERVAR']
      assert_nil env['OPENSHIFT_APP_NAME']
    end

    # Ensure cartridge inherits gear variables
    OpenShift::Utils::Environ.for_cartridge(File.join('/tmp', @uuid, @cart_name)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  # Verify cartridge overrides gear
  def test_override
    write_var(:gear, 'DEFAULT_LABEL', 'bogus')

    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'bogus', env['DEFAULT_LABEL']
    end

    write_var(:cart, 'DEFAULT_LABEL', 'VIP')

    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'VIP', env['DEFAULT_LABEL']
    end
  end
end
