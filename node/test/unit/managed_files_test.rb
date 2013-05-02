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
      @user = OpenStruct.new({
        :homedir =>  "#{Dir.mktmpdir}/"
      })

      @cartridge = OpenStruct.new({
        :name =>  'mock',
        :directory =>  'mock'
      })
      FileUtils.mkdir_p(File.join(@user.homedir,@cartridge.directory))

      # TODO: Don't actually need to create the files until we want to test globbing
=begin
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
=end

      good_files = %w(~/.good ~/app-root/good good ~/app-root/foo/good/) << "~/#{@cartridge.directory}/good"
      blacklist_files = %w(~/.ssh/bad)
      oob_files = %w(~/../bad)
      @managed_files = {
        :locked_files => good_files | blacklist_files | oob_files
      }

      File.join(@user.homedir,@cartridge.directory,'metadata','managed_files.yml').tap do |manifest_file|
        FileUtils.mkdir_p(File.dirname(manifest_file))
        File.open(manifest_file,'w') do |f|
          f.write(@managed_files.to_yaml)
        end
      end
    end

    def test_get_managed_files
      assert_equal @managed_files[:locked_files], managed_files(@cartridge, :locked_files, @user.homedir, false)
    end

    def test_get_locked_files
      # The lock_files are returned relative to the homedir without the ~/
      expected_files = %w(.good app-root/good mock/good mock/good).map{|x| File.join(@user.homedir,x) }
      expected_files << "#{File.join(@user.homedir,'app-root','foo','good')}/"
      assert_equal expected_files.sort, lock_files(@cartridge).sort
    end
  end
end
