#!/usr/bin/env oo-ruby
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
# Test the OpenShift unix_user model
#
require 'openshift-origin-node/model/unix_user'
require 'test/unit'

# Run unit test manually
# ruby -Iopenshift/node/lib/:openshift/common/lib/ openshift/node/test/unit/unix_user_test.rb
class TestUnixUserModel < Test::Unit::TestCase

  def assert_directory?(file)
    assert File.directory?(file), "Directory #{file} not found"
  end

  def assert_symlink?(link)
    assert File.symlink?(link), "Symlink #{link} not found"
  end

  def setup
    @gear_uuid = "1000"
    @user_uid = "1000"
    @app_name = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @verbose = false
  end

  def test_initialize
    FileUtils.rm_rf("/tmp/homedir", :verbose => @verbose) if File.directory?("/tmp/homedir")
    o = OpenShift::UnixUser.new(@gear_uuid, @gear_uuid, @user_uid, @app_name,
                                 @gear_name, @namespace,
                                 nil, nil, @verbose)
    assert_not_nil o

    o.initialize_homedir("/tmp/", "/tmp/homedir/", "cartridges/openshift-origin-cartridge-abstract/")
    assert_directory?("/tmp/homedir")
    assert ! File.symlink?("/tmp/homedir/data"), 'found deprecated data symlink'
    assert ! File.directory?("/tmp/homedir/app"), 'found deprecated app directory'
    assert_directory?("/tmp/homedir/app-root")
    assert_directory?("/tmp/homedir/app-root/runtime/")
    assert File.exist?("/tmp/homedir/app-root/runtime/.state"), '.state file missing'
    assert_symlink?("/tmp/homedir/app-root/repo")
    assert_directory?("/tmp/homedir/.tmp")
    assert_directory?("/tmp/homedir/.env")
    assert_directory?("/tmp/homedir/.sandbox")
  end

# This tests cannot be run because expected polyinstantiation of /tmp causes system /tmp to be chmod 760.
#  def test_authorized_keys
#    o = OpenShift::UnixUser.new(@gear_uuid, @gear_uuid, @user_uid, @app_name,
#                                 @gear_name, @namespace,
#                                 nil, nil, @verbose)
#    options  = 'command="/usr/bin/trap-user",no-X11-forwarding'
#    key_type = 'ssh-rsa'
#    key      = 'XXYYZZ=='
#    comment  = 'OPENSHIFT-47c106d0952f407ba3dea5f80b98eb2bdefault'
#    path = "/tmp/mock_authorized_keys"
#    File.open(path, File::WRONLY|File::TRUNC|File::CREAT, 0o0440) {|file|
#      file.write("#{options} #{key_type} #{key} #{comment}\n")
#    }
#
#    keys = o.read_ssh_keys(path)
#    assert_equal 1, keys.size
#    assert keys.include? comment
#
#    o.write_ssh_keys(path, keys)
#
#    keys = o.read_ssh_keys(path)
#    assert_equal 1, keys.size
#    assert keys.include? comment

    # @homedir private these tests cannot be run
    #o.add_ssh_key(key, key_type, comment)
    #keys = o.read_ssh_keys(path)
    #assert_equal 1, keys.size
    #assert keys.include? comment
#  end
end

