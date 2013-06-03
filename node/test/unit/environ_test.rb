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
require "fileutils"

class EnvironTest < OpenShift::NodeTestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @uuid         = 'f5586d7e690e4a7ea71da1507d60c192'
    @cart_name    = 'mock'
    @gear_env     = File.join('/tmp', @uuid, '.env')
    @cart_env     = File.join('/tmp', @uuid, @cart_name, 'env')
    FileUtils.mkpath(@gear_env)
    FileUtils.mkpath(@cart_env)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    FileUtils.rm_rf(File.join('/tmp', @uuid))
  end

  # Helper to directly write values to ENV files
  # Send raw = true to manually set file contents
  def write_var(where, name, value, raw = true)
    base = case where
             when :gear
               @gear_env
             when :cart
               @cart_env
           end

    File.join(base, name).tap { |filename| IO.write(filename, value) }
  end

  # Helper to write gear UUID to ENV file
  def write_uuid
    write_var(:gear, "OPENSHIFT_GEAR_UUID", @uuid)
  end

  # Verify can read one directory of environment variables
  def test_single_directory
    write_uuid

    OpenShift::Utils::Environ.load(@gear_env).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  def test_load_error_permission
    file_name = write_uuid

    err_msg = "Permission denied"
    IO.stubs(:read).with(any_parameters).raises(Errno::EACCES.new(file_name))
    OpenShift::NodeLogger.logger.expects(:info).once().with(all_of(
                                                                regexp_matches(/^Failed to process: #{@gear_env}/),
                                                                regexp_matches(/#{Regexp.escape(err_msg)}$/)
                                                            ))
    OpenShift::Utils::Environ.load(@gear_env)
  end

  # Verify can read a gear and cartridge environment variables
  def test_gear_env
    write_uuid
    write_var(:cart, 'OPENSHIFT_MOCK_IP', '127.0.0.666')

    # Ensure gear inherits cartridge variables
    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  def test_path
    write_uuid

    # Mock up a second cartridge for overriding JDK_HOME
    second_cartridge = File.join('/tmp', @uuid, 'mock_more', 'env')
    FileUtils.mkpath(second_cartridge)
    IO.write(File.join(second_cartridge, 'JDK_HOME'), 'java6')

    write_var(:gear, 'OPENSHIFT_MOCK_PLUGIN_PATH_ELEMENT', 'mock-plugin/bin')
    write_var(:cart, 'OPENSHIFT_MOCK_PATH_ELEMENT', "#{@cart_name}/bin")
    write_var(:gear, 'OPENSHIFT_PRIMARY_CARTRIDGE_DIR', "/tmp/#{@uuid}/#{@cart_name}/")
    write_var(:cart, 'JDK_HOME', 'java7')

    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal "#{@cart_name}/bin:mock-plugin/bin:/bin:/usr/bin:/usr/sbin", env['PATH']
      assert_equal 'java7', env['JDK_HOME']
    end

    OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal "#{@cart_name}/bin:mock-plugin/bin:/bin:/usr/bin:/usr/sbin", env['PATH']
      assert_equal 'java7', env['JDK_HOME']
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
