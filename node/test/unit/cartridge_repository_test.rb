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

class CartridgeRepositoryTest < OpenShift::NodeTestCase
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

  def populate_manifest(manifests = [])
    manifests.each_with_index do |m, i|
      FileUtils.mkpath File.dirname(m)
      File.open(m, 'w') {|file| file << MANIFESTS[i]}
    end
  end

  def test_single_insert
    populate_manifest(%W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml))

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load
    refute_nil cr

    e = cr.select('crtest', '0.1', '0.0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal 'redhat', e.cartridge_vendor
    assert_equal '0.0.1', e.cartridge_version
    assert_equal "#{@path}/redhat-crtest/0.0.1", e.repository_path

    e = cr.select('crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal '0.0.1', e.cartridge_version
  end

  def test_multiple_inserts
    paths = ["#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml",
             "#{@path}/redhat-crtest/0.0.2/metadata/manifest.yml"]
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    e = cr.select('crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal '0.0.2', e.cartridge_version
    assert e.categories.include?('service')
    assert e.versions.include?('0.1')

    e = cr.select('crtest', '0.2')
    refute_nil e
    assert_equal '0.2', e.version
    assert_equal '0.0.2', e.cartridge_version
  end

  def test_each
    populate_manifest(["#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/0.0.2/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/0.0.3/metadata/manifest.yml"])

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert_equal 5, cr.count
  end

  def test_three_manifest
    paths = ["#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml",
             "#{@path}/redhat-crtest/0.0.2/metadata/manifest.yml",
             "#{@path}/redhat-crtest/0.0.3/metadata/manifest.yml"]
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load
    
    e = cr.select('crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal '0.0.2', e.cartridge_version

    assert_raise(KeyError) do
      cr.select('crtest', '0.1', '0.0.3')
    end

    e = cr.select('crtest', '0.2')
    refute_nil e
    assert_equal '0.2', e.version
    assert_equal '0.0.3', e.cartridge_version
    
    e  = cr.select('crtest', '0.3')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '0.0.3', e.cartridge_version

    e  = cr['crtest', '0.3']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '0.0.3', e.cartridge_version

    lookup = {'0.1' => '0.0.2', '0.2' => '0.0.3', '0.3' => '0.0.3'}

    latest = cr.latest_versions
    latest.delete_if do |cart|
      cart.cartridge_version == lookup[cart.version]
    end

    assert latest.empty?
  end

  def test_not_found
    populate_manifest(["#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/0.0.2/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/0.0.3/metadata/manifest.yml"])

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert_raise(KeyError) do
      cr.select('crtest', '0.4')
    end
  end

  MANIFESTS = [
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.1'
        Versions: ['0.1']
        Cartridge-Version: '0.0.1'
        Compatible-Versions: ['1.0']
        Cartridge-Vendor: redhat
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.2'
        Versions: ['0.1', '0.2']
        Cartridge-Version: '0.0.2'
        Compatible-Versions: ['1.0', '1.1']
        Cartridge-Vendor: redhat
        Source-Url: http://example.com
        Version-Overrides:
          '0.1':
            Categories:
              - service
            Versions: ['0.2']
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.3'
        Versions: ['0.2', '0.3']
        Cartridge-Version: '0.0.3'
        Cartridge-Vendor: redhat
      },
  ]
end
