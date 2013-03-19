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

require_relative '../../lib/openshift-origin-node/model/cartridge_repository'
require 'test/unit'
require 'mocha'
require 'yaml'
require 'pp'

class CartridgeRepositoryTest < Test::Unit::TestCase
  def setup
    @path = '/var/lib/openshift/.cartridge_repository'
  end

  def test_one_manifest
    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0]))

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        with(@path).
        yields("#{@path}/redhat-CRTEST/1.0/metadata/manifest.yml")

    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.load(@path)

    refute_nil cr
    e = cr.select('CRTest', '0.1', '1.0')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal "#{@path}/redhat-CRTest/1.0", e.repository_path
    assert_equal 'RedHat', e.cartridge_vendor

    e = cr.select('CRTest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version

    e = cr.select('CRTest')
    refute_nil e
    assert_equal '0.1', e.version

    assert_equal 'redhat-CRTest', e.directory
  end

  def test_each
    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0])).
        then.returns(YAML.load(MANIFESTS[1])).
        then.returns(YAML.load(MANIFESTS[2]))

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        with(@path).
        multiple_yields(["#{@path}/RedHat-CRTest/1.0/metadata/manifest.yml"],
                        ["#{@path}/RedHat-CRTest/1.1/metadata/manifest.yml"],
                        ["#{@path}/RedHat-CRTest/1.2/metadata/manifest.yml"],)

    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.load(@path)
    assert_equal 1, cr.inject(0) { |a, c| a += 1}
  end

  def test_three_manifest
    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0])).
        then.returns(YAML.load(MANIFESTS[1])).
        then.returns(YAML.load(MANIFESTS[2]))

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        with(@path).
        multiple_yields(["#{@path}/redhat-CRTest/1.0/metadata/manifest.yml"],
                        ["#{@path}/redhat-CRTest/1.1/metadata/manifest.yml"],
                        ["#{@path}/redhat-CRTest/1.2/metadata/manifest.yml"],)

    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.load(@path)

    e = cr.select('CRTest')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    cr = OpenShift::CartridgeRepository.instance
    e  = cr.select('CRTest', '0.3')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    e = cr['CRTest']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    cr = OpenShift::CartridgeRepository.instance
    e  = cr['CRTest', '0.3']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version
  end

  def test_not_found
    YAML.stubs(:load_file).
        returns(YAML.load(MANIFESTS[0])).
        then.returns(YAML.load(MANIFESTS[1])).
        then.returns(YAML.load(MANIFESTS[2]))

    OpenShift::CartridgeRepository.
        any_instance.
        stubs(:find_manifests).
        with(@path).
        multiple_yields(["#{@path}/redhat-CRTest/1.0/metadata/manifest.yml"],
                        ["#{@path}/tests/redhat-CRTest/1.1/metadata/manifest.yml"],
                        ["#{@path}/tests/redhat-CRTest/1.2/metadata/manifest.yml"],)

    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.load(@path)

    assert_raise(KeyError) do
      cr.select('CRTest', '0.4')
    end
  end

  MANIFESTS = [
      %q{#
        Name: CRTest
        Cartridge-Short-Name: CRTEST
        Version: 0.1
        Versions: [0.1]
        Cartridge-Version: 1.0
        Cartridge-Versions: [1.0]
        Cartridge-Vendor: RedHat
      },
      %q{#
        Name: CRTest
        Cartridge-Short-Name: CRTEST
        Version: 0.2
        Versions: [0.1, 0.2]
        Cartridge-Version: 1.1
        Cartridge-Versions: [1.0, 1.1]
        Cartridge-Vendor: RedHat
      },
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
