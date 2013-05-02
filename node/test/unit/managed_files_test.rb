#!/usr/bin/env oo-ruby
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
#
# Test the OpenShift managed_files helper module
#
require_relative '../test_helper'

module OpenShift
  class ManagedFilesTest < OpenShift::V2SdkTestCase
    include ManagedFiles
    def setup
      @homedir = Dir.mktmpdir + '/'
      @user = OpenStruct.new({
        :homedir =>  @homedir
      })

      @cartridge = OpenStruct.new({
        :name =>  'mock',
        :directory =>  'mock'
      })
      FileUtils.mkdir_p(File.join(@homedir,@cartridge.directory))

      %w(
        .good
        bad
        app-root/good
        mock/good
        .ssh/bad
        ../bad
      ).each do |path|
        full_path = File.join(@user.homedir,path)
        dir = File.dirname(full_path)
        FileUtils.mkdir_p(dir)
        FileUtils.touch(full_path)
      end
    end

    def set_managed_files(cart, homedir=nil)
      @good_files = %w(~/.good ~/app-root/good good) << "~/#{cart.directory}/good"
      blacklist_files = %w(~/.ssh/bad)
      oob_files = %w(~/../bad)
      @managed_files = {
        :locked_files => @good_files | blacklist_files | oob_files
      }
      manifest_file = File.join(homedir ? homedir : '',@cartridge.directory,'metadata','managed_files.yml')
      File.stubs(:exists?).with(manifest_file).returns(true)
      YAML.stubs(:load_file).with(manifest_file).returns(@managed_files)
    end

    def test_get_managed_files
      set_managed_files(@cartridge)
      assert_equal @managed_files[:locked_files], managed_files(@cartridge, :locked_files)
    end

    def test_get_locked_files
      set_managed_files(@cartridge, @homedir)
      # The lock_files are returned relative to the homedir without the ~/
      expected_files = ["#{@homedir}.good", "#{@homedir}app-root/good", "#{@homedir}mock/good", "#{@homedir}mock/good"]
      assert_equal expected_files, lock_files(@cartridge)
    end
  end
end
