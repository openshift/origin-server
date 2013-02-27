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
           MockUser = Struct.new(:gid, :uid, :homedir) do
         def get_mcs_label(uid)
           's0:c0,c1000'
         end
       end
    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      @uuid    = `uuidgen -r |sed -e s/-//g`.chomp
      @homedir = "/tmp/tests/#@uuid"
      FileUtils.mkpath(File.join(@homedir, 'mock', 'metadata'))

      @files = [File.join(@homedir, 'mock/a'), File.join(@homedir, '.mocking_bird')]
      @dirs = [File.join(@homedir, 'mock/b/')]

      user = MockUser.new(1000, 1000, @homedir.to_s)
      @model = V2CartridgeModel.new(nil, user)
    end

    def teardown
      FileUtils.rm_rf(@homedir)
    end

    def test_do_unlock_gear
      @model.do_unlock(@files + @dirs)

      @files.each do |f|
        assert File.file?(f), "Unlock failed to create file #{f}"
      end

      @dirs.each do |d|
        assert File.directory?(d), "Unlock failed to create directory #{d}"
      end
    end

    def test_do_lock_gear
      @files.each do |f|
        FileUtils.touch(f)
      end
      @dirs.each do |d|
        FileUtils.mkpath(d)
      end

      @model.do_lock(@files + @dirs)

      @files.each do |f|
        assert File.file?(f), "Lock deleted file #{f}"
      end

      @dirs.each do |d|
        assert File.directory?(d), "Lock deleted directory #{d}"
      end
    end

    def test_lock_files
      Dir.chdir(@homedir) do
        File.open('mock/metadata/locked_files.txt', 'w') do |f|
          f.write("\nmock/c\nmock/d/\n")
        end
        assert File.exists? File.join(@homedir, 'mock', 'metadata', 'locked_files.txt')

        files = @model.lock_files('mock')

        expected = [File.join(@homedir, 'mock/c'), File.join(@homedir, 'mock/d/')]
        assert_equal(expected, files)
      end
    end

    def test_unlock_gear
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
