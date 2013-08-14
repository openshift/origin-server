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
require 'fakefs/safe'
require 'yaml'
require 'pp'

class NodeTest < OpenShift::NodeTestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear

    @path = '/var/lib/openshift/.cartridge_repository'
    OpenShift::Runtime::CartridgeRepository.instance.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def populate_manifest(manifests = {})
    manifests.each_pair do |manifest_file, manifest|
      FileUtils.mkpath File.dirname(manifest_file)
      File.open(manifest_file, 'w') { |file| file << manifest }
    end
  end

  def test_get_cartridge_list
    manifest = %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '0.0.1'
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
      }

    populate_manifest({"#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml" => manifest})

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    buffer = OpenShift::Runtime::Node.get_cartridge_list(true, true, true)
    refute_nil buffer
    
    assert_equal %Q(CLIENT_RESULT: [\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.1'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.1\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.2'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.3'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCartridge-Vendor: redhat\\nGroup-Overrides:\\n- components:\\n  - crtest-0.3\\n  - web_proxy\\n\"]),
                 buffer
  end
end
