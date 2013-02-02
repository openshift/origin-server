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
    @uuid     = 'f5586d7e690e4a7ea71da1507d60c192'
    @gear_env = File.join('/tmp', @uuid, '.env')
    @cart_env = File.join('/tmp', @uuid, 'mock-0.0', 'env')
    FileUtils.mkpath(@gear_env)
    FileUtils.mkpath(@cart_env)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    FileUtils.rm_rf(File.join('/tmp', @uuid))
  end

  # Verify can read one directory of environment variables
  def test_single_directory
    File.open(File.join(@gear_env, 'OPENSHIFT_GEAR_UUID'), 'w') { |fd|
      fd.write(%Q{export OPENSHIFT_GEAR_UUID="#@uuid"})
    }
    env = OpenShift::Utils::Environ.load(@gear_env)
    assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
    assert_nil env['OPENSHIFT_APP_NAME']
  end

  # Verify can read a gear and cartridge environment variables
  def test_two_directories
    File.open(File.join(@gear_env, 'OPENSHIFT_GEAR_UUID'), 'w') { |fd|
      fd.write(%Q{export OPENSHIFT_GEAR_UUID="#@uuid"})
    }
    File.open(File.join(@cart_env, 'OPENSHIFT_MOCK_IP'), 'w') { |fd|
      fd.write('export OPENSHIFT_MOCK_IP="127.0.0.666"')
    }

    env = OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid))
    assert_equal @uuid, env['OPENSHIFT_GEAR_UUID']
    assert_equal "127.0.0.666", env['OPENSHIFT_MOCK_IP']
    assert_nil env['OPENSHIFT_APP_NAME']
  end

  # Verify cartridge overrides gear
  def test_override
    File.open(File.join(@gear_env, 'DEFAULT_LABEL'), 'w') { |fd|
      fd.write('export DEFAULT_LABEL="bogus"')
    }
    env = OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid))
        assert_equal 'bogus', env['DEFAULT_LABEL']
    
    File.open(File.join(@cart_env, 'DEFAULT_LABEL'), 'w') { |fd|
      fd.write('export DEFAULT_LABEL="VIP"')
    }
    env = OpenShift::Utils::Environ.for_gear(File.join('/tmp', @uuid))
    assert_equal 'VIP', env['DEFAULT_LABEL']
  end
end
