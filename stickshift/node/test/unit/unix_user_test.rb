#!/usr/bin/ruby
#--
# Copyright 2012 Red Hat, Inc.
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
# Test the StickShift unix_user model
#
require 'stickshift-node/model/unix_user'
require 'test/unit'

# Run unit test manually
# ruby -Istickshift/node/lib/:stickshift/common/lib/ stickshift/node/test/unit/unix_user_test.rb 
class TestUnixUserModel < Test::Unit::TestCase

  def assert_directory?(file)
    assert File.directory?(file), "Directory #{file} not found"
  end

  def assert_symlink?(link)
    assert File.symlink?(link), "Symlink #{link} not found"
  end

  def test_initialize
    gear_uuid = Process.euid.to_s
    user_uid = Process.euid.to_s
    app_name = 'UnixUserTestCase'
    gear_name = app_name
    namespace = 'jwh201204301647'
    verbose = false

    FileUtils.rm_rf("/tmp/homedir", :verbose => verbose) if File.directory?("/tmp/homedir")
    o = StickShift::UnixUser.new(gear_uuid, gear_uuid, user_uid, app_name,
                                 gear_name, namespace,
                                 nil, nil, verbose)
    assert_not_nil o

    o.initialize_homedir("/tmp/", "/tmp/homedir/", "stickshift/abstract/")
    assert_directory?("/tmp/homedir")
    assert ! File.symlink?("/tmp/homedir/data"), 'found deprecated data symlink'
    assert ! File.directory?("/tmp/homedir/app"), 'found deprecated app directory'
    assert_directory?("/tmp/homedir/app-root")
    assert File.exist?("/tmp/homedir/app-root/runtime/.state"), '.state file missing'
    assert_directory?("/tmp/homedir/app-root/runtime/")
    assert_symlink?("/tmp/homedir/app-root/repo")
    assert_directory?("/tmp/homedir/.tmp")
    assert_directory?("/tmp/homedir/.env")
    assert_directory?("/tmp/.httpd.d")
    assert_directory?("/tmp/.httpd.d/#{gear_uuid}_#{namespace}_#{app_name}")
  end
end

