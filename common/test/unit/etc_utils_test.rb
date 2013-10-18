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
# Test the OpenShift manifest model
#
require_relative '../test_helper'
require 'ostruct'
require 'mocha/setup'

class EtcUtilsTest < Test::Unit::TestCase
  def setup
    @pwent = OpenStruct.new(uid: 666, gid: 666)
  end

  def test_grpwname_bigint
    name = 921957316561229358039040
    Etc.expects(:getpwnam).with(name.to_s).returns(@pwent)
    assert_equal @pwent.uid, EtcUtils.getpwnam(name).uid
  end

  def test_getgrname_bigint
    name = 921957316561229358039040
    Etc.expects(:getgrnam).with(name.to_s).returns(@pwent)
    assert_equal @pwent.gid, EtcUtils.getgrnam(name).gid
  end

  def test_grpwname_fixnum
    uid = 666
    Etc.expects(:getpwnam).with(uid.to_s).returns(@pwent)
    assert_equal @pwent.uid, EtcUtils.getpwnam(uid).uid
  end

  def test_getgrname_fixnum
    uid = 666
    Etc.expects(:getgrnam).with(uid.to_s).returns(@pwent)
    assert_equal @pwent.gid, EtcUtils.getgrnam(uid).gid
  end

  def test_grpwname_string
    uid = "666"
    Etc.expects(:getpwnam).with(uid.to_s).returns(@pwent)
    assert_equal @pwent.uid, EtcUtils.getpwnam(uid).uid
  end

  def test_getgrname_string
    uid = "666"
    Etc.expects(:getgrnam).with(uid.to_s).returns(@pwent)
    assert_equal @pwent.gid, EtcUtils.getgrnam(uid).gid
  end
end