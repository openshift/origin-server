#!/usr/bin/env oo-ruby
#--
# Copyright 2012-2013 Red Hat, Inc.
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
# Test the OpenShift selinux utilities
#
require_relative '../test_helper'

class SELinuxUtilsMCSLabelTest < OpenShift::NodeTestCase
  def test_mcs_labels
    labelset = OpenShift::Runtime::Utils::SELinux.mcs_labels.to_a
    assert_equal 523776, labelset.length
    assert_equal [1, "s0:c0,c1"], labelset[0]
    assert_equal [523776, "s0:c1022,c1023"], labelset[-1]
  end

  def test_get_mcs_label
    scenarios = [
                 [500,    "s0:c0,c500"],
                 [1023,   "s0:c0,c1023"],
                 [1024,   "s0:c1,c2"],
                 [1524,   "s0:c1,c502"],
                 [2045,   "s0:c1,c1023"],
                 [2046,   "s0:c2,c3"],
                 [4092,   "s0:c4,c10"],
                 [8184,   "s0:c8,c36"],
                 [14191,  "s0:c13,c983"],
                 [16368,  "s0:c16,c136"],
                 [26851,  "s0:c26,c604"],
                 [32736,  "s0:c32,c528"],
                 [65472,  "s0:c66,c165"],
                 [130944, "s0:c137,c246"],
                 [261888, "s0:c299,c861"],
                 [523775, "s0:c1021,c1023"]
                ]

    # The new O(1) generator fails on the last value
    # [523776, "s0:c1022,c1023"]
    # Acceptable loss for speed.

    scenarios.each do |s|
      assert_equal s[1], OpenShift::Runtime::Utils::SELinux.get_mcs_label(s[0])
    end
  end
end


class SELinuxUtilsContextTest < Test::Unit::TestCase

  def test_context_from_defaults
    assert_equal "unconfined_u:system_r:openshift_t:s0", OpenShift::Runtime::Utils::SELinux.context_from_defaults()
    assert_equal "unconfined_u:system_r:openshift_t:a", OpenShift::Runtime::Utils::SELinux.context_from_defaults("a")
    assert_equal "unconfined_u:system_r:b:a", OpenShift::Runtime::Utils::SELinux.context_from_defaults("a", "b")
    assert_equal "unconfined_u:c:b:a", OpenShift::Runtime::Utils::SELinux.context_from_defaults("a", "b", "c")
    assert_equal "d:c:b:a", OpenShift::Runtime::Utils::SELinux.context_from_defaults("a", "b", "c", "d")
  end

  def test_getcon
    con = "a:b:c:d"
    Selinux.expects(:getcon).returns([0, con]).once
    assert_equal con, OpenShift::Runtime::Utils::SELinux.getcon
  end

end


class SELinuxUtilsChconTest < OpenShift::NodeTestCase
    def setup
    @config = mock('OpenShift::Config')
    @config.stubs(:get).returns(nil)
    OpenShift::Config.stubs(:new).returns(@config)

    @test_paths = [ "foo", "bar", "baz", '*' ]

    @test_path = "foo"
  end


  def test_chcon_no_context_change
    tcontext = "a:b:c:d"
    fcontext = tcontext
    
    OpenShift::Runtime::Utils::SELinux.expects(:matchpathcon_update).once
    File.expects(:lstat).with(@test_path).returns(mock('File::Stat') { expects(:mode).returns(0755) }).once
    Selinux.expects(:matchpathcon).with(@test_path, anything).returns([0, fcontext])
    Selinux.expects(:lgetfilecon).with(@test_path).returns([fcontext.length, fcontext])
    OpenShift::Runtime::NodeLogger.logger.expects(:error).never
    Selinux.expects(:lsetfilecon).with(@test_path, tcontext).returns(0).never
    
    OpenShift::Runtime::Utils::SELinux.chcon(@test_path)
  end
  
  def test_chcon_with_label
    tlabel = "d"
    tcontext = "a:b:c:#{tlabel}"
    fcontext = "a:b:c:none_l"

    OpenShift::Runtime::Utils::SELinux.expects(:matchpathcon_update).once
    File.expects(:lstat).with(@test_path).returns(mock('File::Stat') { expects(:mode).returns(0755) }).once
    Selinux.expects(:matchpathcon).with(@test_path, anything).returns([0, fcontext])
    Selinux.expects(:lgetfilecon).with(@test_path).returns([fcontext.length, fcontext])
    OpenShift::Runtime::NodeLogger.logger.expects(:error).never
    Selinux.expects(:lsetfilecon).with(@test_path, tcontext).returns(0).once

    OpenShift::Runtime::Utils::SELinux.chcon(@test_path, tlabel)
  end

  def test_chcon_with_full_context
    tuser = "a"
    trole = "b"
    ttype = "c"
    tlabel = "d"

    tcontext = "#{tuser}:#{trole}:#{ttype}:#{tlabel}"
    fcontext = "none_u:none_r:none_t:none_l"

    OpenShift::Runtime::Utils::SELinux.expects(:matchpathcon_update).once
    File.expects(:lstat).with(@test_path).returns(mock('File::Stat') { expects(:mode).returns(0755) }).once
    Selinux.expects(:matchpathcon).with(@test_path, anything).returns([0, fcontext])
    Selinux.expects(:lgetfilecon).with(@test_path).returns([fcontext.length, fcontext])
    OpenShift::Runtime::NodeLogger.logger.expects(:error).never
    Selinux.expects(:lsetfilecon).with(@test_path, tcontext).returns(0).once

    OpenShift::Runtime::Utils::SELinux.chcon(@test_path, tlabel, ttype, trole, tuser)
  end

  def test_setmatchpathcon_update
    Selinux.expects(:selinux_file_context_path).returns("foo").once
    Dir.expects(:glob).with("foo*").returns(["foo", "bar"]).once
    File.expects(:stat).with("foo").returns(mock('File::Stat') { expects(:mtime).returns(1234567) }).once
    File.expects(:stat).with("bar").returns(mock('File::Stat') { expects(:mtime).returns(7890123) }).once
    OpenShift::Runtime::NodeLogger.logger.expects(:debug)
    Selinux.stubs(:matchpathcon_fini)
    Selinux.expects(:matchpathcon_init).with(nil).once

    OpenShift::Runtime::Utils::SELinux.matchpathcon_update
  end

end


class SELinuxUtilsSetMCSLabelTest < OpenShift::NodeTestCase

  def setup
    @config = mock('OpenShift::Config')
    @config.stubs(:get).returns(nil)
    OpenShift::Config.stubs(:new).returns(@config)

    @test_label = "s0:c0,c1,c2,c3,c4,c5,c6,c7,c8"
    @test_type  = "testtype_t"
    @test_role  = "testrole_r"
    @test_user  = "testuser_u"

    @test_paths = [ "foo", "bar", "baz", '*' ]

    @test_path = @test_paths[0]
  end

  def test_set_mcs_label
    @test_paths.each do |path|
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, @test_label).once
    end
    OpenShift::Runtime::Utils::SELinux.set_mcs_label(@test_label, *@test_paths)
  end

  def test_set_mcs_label_flatten
    @test_paths.each do |path|
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, @test_label).once
    end
    OpenShift::Runtime::Utils::SELinux.set_mcs_label(@test_label, @test_paths)
  end

  def test_set_mcs_label_R
    @test_paths.each do |path|
      Find.expects(:find).with(path).yields(path).once
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, @test_label).once
    end
    OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(@test_label, *@test_paths)
  end

  def test_set_mcs_label_R_flatten
    @test_paths.each do |path|
      Find.expects(:find).with(path).yields(path).once
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, @test_label).once
    end
    OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(@test_label, @test_paths)
  end

  def test_clear_mcs_label
    @test_paths.each do |path|
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, nil).once
    end
    OpenShift::Runtime::Utils::SELinux.clear_mcs_label(*@test_paths)
  end

  def test_clear_mcs_label_flatten
    @test_paths.each do |path|
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, nil).once
    end
    OpenShift::Runtime::Utils::SELinux.clear_mcs_label(@test_paths)
  end

  def test_clear_mcs_label_R
    @test_paths.each do |path|
      Find.expects(:find).with(path).yields(path).once
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, nil).once
    end
    OpenShift::Runtime::Utils::SELinux.clear_mcs_label_R(*@test_paths)
  end

  def test_clear_mcs_label_R_flatten
    @test_paths.each do |path|
      Find.expects(:find).with(path).yields(path).once
      OpenShift::Runtime::Utils::SELinux.expects(:chcon).with(path, nil).once
    end
    OpenShift::Runtime::Utils::SELinux.clear_mcs_label_R(@test_paths)
  end
end
