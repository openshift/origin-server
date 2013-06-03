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

class NodeTest < OpenShift::NodeTestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    super

    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0]))
    File.stubs(:exist?).returns(true)

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        multiple_yields(["#{@path}/redhat-crtest/1.2/metadata/manifest.yml"])

    OpenShift::CartridgeRepository.instance.clear
    OpenShift::CartridgeRepository.instance.load
  end

  def test_get_cartridge_list
    buffer = OpenShift::Node.get_cartridge_list(true, true, true)
    refute_nil buffer

    assert_equal %Q(CLIENT_RESULT: [\"---\\nName: crtest-0.1\\nDisplay-Name: crtest Unit Test\\nVersion: '0.1'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.1\\n  - web_proxy\\n\",\"---\\nName: crtest-0.2\\nDisplay-Name: crtest Unit Test\\nVersion: '0.2'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\",\"---\\nName: crtest-0.3\\nDisplay-Name: crtest Unit Test\\nVersion: '0.3'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\"]),
                 buffer
  end

  MANIFESTS = [
      %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: redhat
        Group-Overrides:
          - components:
            - crtest-0.3
            - web_proxy
        Version-Overrides:
          '0.1':
            Group-Overrides:
              - components:
                - crtest-0.1
                - web_proxy
          '0.2':
            Group-Overrides:
              - components:
                - crtest-0.2
                - web_proxy
      },
  ]
end
