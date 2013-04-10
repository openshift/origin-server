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
require 'test_helper'
require 'openshift-origin-node/utils/selinux'
require 'test/unit'
require 'mocha'

class SELinuxUtilsTest < Test::Unit::TestCase
  # Use a precomputed static table to be sure these are correct.
  def test_mcs_label
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
                 [523776, "s0:c1022,c1023"],
                ]
    scenarios.each do |s|
      assert_equal OpenShift::Utils::SELinux.get_mcs_label(s[0]), s[1]
    end
  end
end
