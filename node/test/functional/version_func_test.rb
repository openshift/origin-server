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
# Test the OpenShift VERSION string
#
require_relative '../test_helper'

class VersionFunctionalTest < OpenShift::NodeTestCase

  def test_leading_space
    refute_match(/^\s+/, 
                    OpenShift::VERSION, 
                    'Version string must not have leading white space'
                    )
  end

  def test_trailing_space
    refute_match(/\s+$/,
                    OpenShift::VERSION,
                    'Version string must not have trailing white space'
                    )
  end
end
