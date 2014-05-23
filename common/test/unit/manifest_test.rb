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

class ManifestTest < Test::Unit::TestCase

  def teardown
    YAML.unstub(:load_file)
    File.unstub(:exist?)
  end

  def test_manifest_no_overrides
    YAML.stubs(:safe_load_file).with('mock_manifest').returns(YAML.load(MANIFEST))
    File.stubs(:exist?).with('mock_manifest').returns(true)

    cart       = OpenShift::Runtime::Manifest.new('mock_manifest', nil, :file)
    components = cart.manifest['Group-Overrides'].first['components']

    assert_equal 'mock', cart.name
    assert_equal '0.1', cart.version
    assert_equal 'MOCK', cart.short_name
    assert_equal 5, cart.endpoints.length
    assert_equal 1, components.length
    assert_equal "mock", components[0]
  end

  def test_manifest_overrides
    YAML.stubs(:safe_load_file).with('mock_manifest').returns(YAML.load(MANIFEST))
    File.stubs(:exist?).with('mock_manifest').returns(true)

    cart       = OpenShift::Runtime::Manifest.new('mock_manifest', '0.2', :file)
    components = cart.manifest['Group-Overrides'].first['components']

    assert_equal 'mock', cart.name
    assert_equal '0.2', cart.version
    assert_equal 'MOCK', cart.short_name
    assert_equal 5, cart.endpoints.length
    assert_equal 2, components.length
    assert_equal "mock", components[0]
    assert_equal "web_proxy", components[1]
  end

  def test_manifest_url_good
    manifest               = YAML.load(MANIFEST)
    url                    = 'http://www.example.com/killer-cartridge.zip'
    manifest['Source-Url'] = url

    cart = OpenShift::Runtime::Manifest.new(manifest.to_yaml)

    refute_nil cart
    assert_equal url, cart.source_url
  end


  def test_manifest_url_bad
    manifest               = YAML.load(MANIFEST)
    manifest['Source-Url'] = 'Bad Url'

    assert_raise OpenShift::InvalidElementError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
  end

  def test_autocorrect_frontend
    manifest               = YAML.load(MANIFEST)
    manifest['Source-Url'] = 'http://www.example.com/killer-cartridge.zip'

    manifest['Endpoints'] = \
    [
        {"Private-IP-Name"   => "EXAMPLE_IP1",
         "Private-Port-Name" => "EXAMPLE_PORT1",
         "Private-Port"      => 8080,
         "Public-Port-Name"  => "EXAMPLE_PUBLIC_PORT1",
         "Mappings"          =>
             [
                 {"Frontend" => "front1a", "Backend" => "back1a"}
             ]
        }
    ]

    actual = OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    assert_equal '/front1a', actual.endpoints.first.mappings.first.frontend
    assert_equal '/back1a', actual.endpoints.first.mappings.first.backend
  end

  def test_missing_ip_name
    manifest               = YAML.load(MANIFEST)
    manifest['Source-Url'] = 'http://www.example.com/killer-cartridge.zip'

    manifest['Endpoints'] = \
    [
        {
            'Private-Port-Name' => 'EXAMPLE_PORT1',
            'Private-Port'      => 8080,
        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-IP-Name is a required element/, error.message)

    manifest['Endpoints'] = \
    [
        {
            'Private-IP-Name'   => '',
            'Private-Port-Name' => 'EXAMPLE_PORT1',
            'Private-Port'      => 8080,
        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-IP-Name is a required element/, error.message)
  end

  def test_missing_port_name
    manifest               = YAML.load(MANIFEST)
    manifest['Source-Url'] = 'http://www.example.com/killer-cartridge.zip'

    manifest['Endpoints'] = \
    [
        {'Private-IP-Name' => 'EXAMPLE_IP1',
         'Private-Port'    => 8080,
        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-Port-Name is a required element/, error.message)

    manifest['Endpoints'] = \
    [
        {
            'Private-IP-Name'   => 'EXAMPLE_IP1',
            'Private-Port-Name' => '',
            'Private-Port'      => 8080,
        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-Port-Name is a required element/, error.message)
  end

  def test_missing_port
    manifest               = YAML.load(MANIFEST)
    manifest['Source-Url'] = 'http://www.example.com/killer-cartridge.zip'

    manifest['Endpoints'] = \
    [
        {
            'Private-IP-Name'   => 'EXAMPLE_IP1',
            'Private-Port-Name' => 'EXAMPLE_PORT1',
        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-Port is a required element/, error.message)

    manifest['Endpoints'] = \
    [
        {
            'Private-IP-Name'   => 'EXAMPLE_IP1',
            'Private-Port-Name' => 'EXAMPLE_PORT1',
            'Private-Port'      => '',

        }
    ]
    error                 = assert_raises RuntimeError do
      OpenShift::Runtime::Manifest.new(manifest.to_yaml)
    end
    assert_match(/Private-Port is not valid/, error.message)
  end

  MANIFEST = %q{#
Name: mock
Cartridge-Short-Name: MOCK
Cartridge-Version: '1.0'
Cartridge-Vendor: unit_test
Display-Name: Mock
Description: "A mock cartridge for development use only."
Version: '0.1'
Versions: ['0.1', '0.2']
License: "None"
Vendor: Red Hat
Categories:
- service
Provides:
- mock
Scaling:
Min: 1
Max: -1
Group-Overrides:
- components:
  - mock
Endpoints:
  - Private-IP-Name:   EXAMPLE_IP1
    Private-Port-Name: EXAMPLE_PORT1
    Private-Port:      8080
    Public-Port-Name:  EXAMPLE_PUBLIC_PORT1
    Mappings:
      - Frontend:      "/front1a"
        Backend:       "/back1a"
        Options:       { websocket: true, tohttps: true }
      - Frontend:      "/front1b"
        Backend:       "/back1b"
        Options:       { noproxy: true }

  - Private-IP-Name:   EXAMPLE_IP1
    Private-Port-Name: EXAMPLE_PORT2
    Private-Port:      8081
    Public-Port-Name:  EXAMPLE_PUBLIC_PORT2
    Mappings:
      - Frontend:      "/front2"
        Backend:       "/back2"
        Options:       { file: true }

  - Private-IP-Name:   EXAMPLE_IP1
    Private-Port-Name: EXAMPLE_PORT3
    Private-Port:      8082
    Public-Port-Name:  EXAMPLE_PUBLIC_PORT3
    Mappings:
      - Frontend:      "/front3"
        Backend:       "/back3"

  - Private-IP-Name:   EXAMPLE_IP2
    Private-Port-Name: EXAMPLE_PORT4
    Private-Port:      9090
    Public-Port-Name:  EXAMPLE_PUBLIC_PORT4
    Mappings:
      - Frontend:      "/front4"
        Backend:       "/back4"

  - Private-IP-Name:   EXAMPLE_IP2
    Private-Port-Name: EXAMPLE_PORT5
    Private-Port:      9091
Version-Overrides:
  '0.2':
    Group-Overrides:
    - components:
      - mock
      - web_proxy
}
end
