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
    @uuid      = 'f5586d7e690e4a7ea71da1507d60c192'
    @gear_env  = File.join('/tmp', @uuid, '.env')
    @user_env  = File.join(@gear_env, 'user_vars')

    @cart_name = 'mock'
    @cart_env  = File.join('/tmp', @uuid, @cart_name, 'env')

    FileUtils.mkpath(@user_env)
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
             when :user
               @user_env
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

    OpenShift::Runtime::Utils::Environ.load(@gear_env).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  def test_load_error_permission
    file_name = write_uuid

    err_msg = "Permission denied"
    IO.stubs(:read).with(any_parameters).raises(Errno::EACCES.new(file_name))
    OpenShift::Runtime::NodeLogger.logger.expects(:info).once().with(all_of(
                                                                regexp_matches(/^Failed to process: #{@gear_env}/),
                                                                regexp_matches(/#{Regexp.escape(err_msg)}$/)
                                                            ))
    OpenShift::Runtime::Utils::Environ.load(@gear_env)
  end

  # Verify can read a gear and cartridge environment variables
  def test_gear_env
    write_uuid
    write_var(:cart, 'OPENSHIFT_MOCK_IP', '127.0.0.666')

    # Ensure gear inherits cartridge variables
    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
      assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
      assert_nil env['OPENSHIFT_APP_NAME']
    end
  end

  def test_collect_elements
    mock_env = {
      'OPENSHIFT_MOCK_LD_LIBRARY_PATH_ELEMENT' => '/usr/lib/mock',
      'OPENSHIFT_CART_LD_LIBRARY_PATH_ELEMENT' => '/usr/lib/cart',
      'OPENSHIFT_SECONDCART_LD_LIBRARY_PATH_ELEMENT' => '/usr/lib/second_cart',
      'OPENSHIFT_MOCK_PATH_ELEMENT' => '/usr/mock/bin',
      'OPENSHIFT_CART_PATH_ELEMENT' => '/usr/cart/bin'
    }

    elements = OpenShift::Runtime::Utils::Environ.collect_elements_from(
      mock_env,
      'LD_LIBRARY_PATH',
      'MOCK'
    )

    assert_equal "/usr/lib/cart:/usr/lib/second_cart:/usr/lib/mock", elements.join(':')

    elements = OpenShift::Runtime::Utils::Environ.collect_elements_from(
      mock_env,
      'PATH',
      'MOCK'
    )

    assert_equal "/usr/mock/bin:/usr/cart/bin", elements.join(':')
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

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal "#{@cart_name}/bin:mock-plugin/bin:/bin:/usr/bin:/usr/sbin", env['PATH']
      assert_equal 'java7', env['JDK_HOME']
    end

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal "#{@cart_name}/bin:mock-plugin/bin:/bin:/usr/bin:/usr/sbin", env['PATH']
      assert_equal 'java7', env['JDK_HOME']
    end
  end

  # Verify cartridge overrides gear
  def test_override
    write_var(:gear, 'DEFAULT_LABEL', 'bogus')

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'bogus', env['DEFAULT_LABEL']
    end

    write_var(:cart, 'DEFAULT_LABEL', 'VIP')

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'VIP', env['DEFAULT_LABEL']
    end
  end

  # Verify update user variables
  def test_update
    write_var(:user, 'UPDATE_VAR1', 'VAR')

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'VAR', env['UPDATE_VAR1']
    end

    for varid in 2..50
      write_var(:user, "UPDATE_VAR#{varid}", "VAR")
    end

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'VAR', env['UPDATE_VAR50']
    end

    write_var(:user, 'UPDATE_VAR50', 'Thisisatest')

    # Test for bug 1073725
    # Verify update user variables when reach user variables maximum value.
    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'Thisisatest', env['UPDATE_VAR50']
    end
  end

  # Verify nulls removed from user variables
  def test_nulls
    write_var(:user, 'EMBEDDED_NULL', "This\000is\000a\000test")

    OpenShift::Runtime::Utils::Environ.for_gear(File.join('/tmp', @uuid)).tap do |env|
      assert_equal 'Thisisatest', env['EMBEDDED_NULL']
    end
  end
end
