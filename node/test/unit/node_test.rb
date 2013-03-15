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
require_relative '../../lib/openshift-origin-node/model/node'
require 'openshift-origin-node/model/cartridge_repository'
require 'test/unit'
require 'mocha'

class NodeTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0]))

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        multiple_yields(["#{@path}/RedHat-CRTest/1.0/metadata/manifest.yml"])
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_get_cartridge_list
    OpenShift::Utils::Sdk.stubs(:node_default_model).returns(:v2)

    buffer = OpenShift::Node.get_cartridge_list
    refute_nil buffer

    assert_equal buffer, %Q(Cartridges:\n\tCRTest-0.1\n\tCRTest-0.2\n\tCRTest-0.3\n)
  end

  MANIFESTS = [
      %q{#
        Name: CRTest
        Cartridge-Short-Name: CRTEST
        Version: 0.3
        Versions: [0.1, 0.2, 0.3]
        Cartridge-Version: 1.2
        Cartridge-Vendor: Red Hat
      },
  ]
end