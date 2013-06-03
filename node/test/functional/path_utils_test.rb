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
require 'etc'

class PathUtilsTest < OpenShift::NodeTestCase
  MockStat = Struct.new(:gid, :uid)

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @uid = 5998
    @stat = MockStat.new(@uid, @uid)
  end

  def teardown
    # Do nothing
  end

  def test_oo_chown
    Etc.stubs(:getpwnam).never
    Etc.stubs(:getgrnam).never
    FileUtils.stubs(:chown).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    PathUtils.oo_chown(@uid, @uid, '/mocked/a')
  end

  def test_oo_chown_R
    Etc.stubs(:getpwnam).never
    Etc.stubs(:getgrnam).never
    FileUtils.stubs(:chown_R).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    PathUtils.oo_chown_R(@uid, @uid, '/mocked/a')
  end

  def test_BigInt
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = 4294967296
    PathUtils.oo_chown(id, id, "/mocked/a")
  end

  def test_oo_BigInt_recursive
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown_R).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = 4294967296
    PathUtils.oo_chown_R(id, id, "/mocked/a")
  end

  def test_HugeInt
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = 512101185004469122000065
    PathUtils.oo_chown(id, id, "/mocked/a")
  end

  def test_oo_HugeInt_recursive
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown_R).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = 512101185004469122000065
    PathUtils.oo_chown_R(id, id, "/mocked/a")
  end

  def test_mongoid
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = '512101185004469122000065'
    PathUtils.oo_chown(id, id, "/mocked/a")
  end

  def test_mongoid_recursive
    Etc.stubs(:getpwnam).with(kind_of(String)).returns(@stat).once
    Etc.stubs(:getgrnam).with(kind_of(String)).returns(@stat).once
    FileUtils.stubs(:chown_R).with(@uid, @uid, '/mocked/a', {}).returns(nil).once

    id = '512101185004469122000065'
    PathUtils.oo_chown_R(id, id, "/mocked/a")
  end

  def test_join
    actual = PathUtils.join('a')
    assert_equal(File.join('a'), actual)

    actual = PathUtils.join('a', 'b')
    assert_equal(File.join('a', 'b'), actual)

    actual = PathUtils.join('a', 'b', 'c')
    assert_equal(File.join('a', 'b', 'c'), actual)

    actual = PathUtils.join(%w(a b .. c))
    assert_equal('a/c', actual)
  end
end
