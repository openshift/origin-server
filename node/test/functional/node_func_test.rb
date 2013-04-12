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

require 'test_helper'
require 'openshift-origin-node/model/node'
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
        multiple_yields(["#{@path}/redhat-CRTest/1.2/metadata/manifest.yml"])

    OpenShift::CartridgeRepository.instance.clear
    OpenShift::CartridgeRepository.instance.load

    OpenShift::Utils::Sdk.stubs(:node_default_model).returns(:v2)
  end

  def teardown
    # Do nothing
  end

  def test_get_cartridge_list
    buffer = OpenShift::Node.get_cartridge_list(true, true, true)
    refute_nil buffer

    assert_equal %Q(CLIENT_RESULT: [\"---\\nName: CRTest-0.1\\nDisplay-Name: CRTest Unit Test\\nVersion: '0.1'\\nGroup-Overrides:\\n- components:\\n  - CRTest-0.1\\n  - web_proxy\\n\",\"---\\nName: CRTest-0.2\\nDisplay-Name: CRTest Unit Test\\nVersion: '0.2'\\nGroup-Overrides:\\n- components:\\n  - CRTest-0.2\\n  - web_proxy\\n\",\"---\\nName: CRTest-0.3\\nDisplay-Name: CRTest Unit Test\\nVersion: '0.3'\\nGroup-Overrides:\\n- components:\\n  - CRTest-0.2\\n  - web_proxy\\n\"]),
                 buffer
  end

  MANIFESTS = [
      %q{#
        Name: CRTest
        Display-Name: CRTest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: Red Hat
        Group-Overrides:
          - components:
            - CRTest-0.3
            - web_proxy
        Version-Overrides:
          '0.1':
            Group-Overrides:
              - components:
                - CRTest-0.1
                - web_proxy
          '0.2':
            Group-Overrides:
              - components:
                - CRTest-0.2
                - web_proxy
      },
  ]
end
