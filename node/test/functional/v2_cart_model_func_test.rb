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

require_relative '../../lib/openshift-origin-node/model/v2_cart_model'
require_relative '../../lib/openshift-origin-node/model/cartridge'
require_relative '../../lib/openshift-origin-node/utils/shell_exec'

require 'test/unit'
require 'mocha'
require 'pathname'

module OpenShift
  class V2CartridgeModelFuncTest < Test::Unit::TestCase
    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      @uuid    = `uuidgen -r |sed -e s/-//g`.chomp
      @homedir = "/tmp/tests/#@uuid"

      @files = %w{/tmp/a /tmp/b/}

      @user = mock('MockUser') do
        stubs(:get_mcs_label).returns('c0,c1000')
        stubs(:gid).returns(1000)
        stubs(:uid).returns(1000)
      end

      @model = V2CartridgeModel.new(nil, @user)
    end

    def teardown
      FileUtils.rm_rf(@files)
      FileUtils.rm_rf(@homedir)
    end

    def test_do_unlock_gear
      @model.do_unlock_gear(@files)

      assert File.file?('/tmp/a'), 'Unlock failed to create file'
      assert File.directory?('/tmp/b'), 'Unlock failed to create directory'
    end

    def test_do_lock_gear
      FileUtils.touch('/tmp/a')
      FileUtils.mkpath('/tmp/b')

      @model.do_lock_gear(@files)

      assert File.file?('/tmp/a'), 'Lock failed to create file'
      assert File.directory?('/tmp/b'), 'Lock failed to create directory'
    end

    def test_lock_files
      @user.stubs(:homedir).returns(@homedir)
      FileUtils.mkpath(File.join(@homedir, 'mock', 'metadata'))

      Dir.chdir(@homedir) do
        File.open('mock/metadata/locked_files.txt', 'w') do |f|
          f.write("\nmock/c\nmock/d/\n")
        end
        assert File.exists? File.join(@homedir, 'mock', 'metadata', 'locked_files.txt')

        files = @model.lock_files('mock')

        assert_equal(
            [File.join(@homedir, 'mock/c'), File.join(@homedir, 'mock/d/')],
            files)
      end
    end

    def test_unlock_gear
      @user.stubs(:homedir).returns(@homedir)
      FileUtils.mkpath(File.join(@homedir, 'mock', 'metadata'))

      Dir.chdir(@homedir) do
        File.open('mock/metadata/locked_files.txt', 'w') do |f|
          f.write("\nmock/c\nmock/d/\n")
        end
        assert File.exists? File.join(@homedir, 'mock', 'metadata', 'locked_files.txt')

        @model.unlock_gear('mock') do |actual|
          assert_equal 'mock', actual
        end
      end

      assert File.file?(File.join(@homedir, 'mock', 'c')), 'Unlock gear failed to create file'
      assert File.directory?(File.join(@homedir, 'mock', 'd')), 'Unlock gear failed to create directory'
    end
  end
end
