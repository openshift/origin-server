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

class V1CartridgeModelFunctionalTest < Test::Unit::TestCase
  MockUser = Struct.new(:uuid)

  def test_get_cartridge
    @config = mock('OpenShift::Config')
    @config.stubs(:get).returns(nil)
    @config.stubs(:get).with('CARTRIDGE_BASE_PATH').returns('/usr/libexec/openshift/cartridges')
    OpenShift::Config.stubs(:new).returns(@config)
    
    m = OpenShift::V1CartridgeModel.new(@config, MockUser.new("unit test"))
    cartridge = m.get_cartridge('php-5.3')
    refute_nil cartridge
  end
end
