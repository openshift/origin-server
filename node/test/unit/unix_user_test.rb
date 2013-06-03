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
# Test the OpenShift unix_user model
#
require_relative '../test_helper'

class UnixUserModelTest < OpenShift::NodeTestCase
  # Tests a variety of UID/host ID to IP address conversions.
  #
  # TODO: Is there a way to do this algorithmically?
  def test_get_ip_addr_success
    scenarios = [
      [501, 1, "127.0.250.129"],
      [501, 10, "127.0.250.138"],
      [501, 20, "127.0.250.148"],
      [501, 100, "127.0.250.228"],
      [540, 1, "127.1.14.1"],
      [560, 7, "127.1.24.7"]
    ]

    scenarios.each do |s|
      assert_equal OpenShift::UnixUser.get_ip_addr(s[0], s[1]), s[2]
    end
  end
end
