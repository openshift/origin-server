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

  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear

    OpenShift::Runtime::CartridgeRepository.instance.clear
    @path = OpenShift::Runtime::CartridgeRepository::CARTRIDGE_REPO_DIR
  end

  def teardown
    FakeFS.deactivate!
  end

  def populate_manifest(manifests = [])
    manifests.each_with_index do |m, i|
      FileUtils.mkpath File.dirname(m)
      File.open(m, 'w') { |file| file << MANIFESTS[i] }
    end
  end

  def populate_manifest_special(manifests = {})
    manifests.each_pair do |manifest_file, manifest|
      FileUtils.mkpath File.dirname(manifest_file)
      File.open(manifest_file, 'w') { |file| file << manifest }
    end
  end

  def test_insert
    populate_manifest(%W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml))

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load
    refute_nil cr

    assert cr.exist?('redhat', 'crtest', '0.1', '0.0.1')
    assert !cr.exist?('redhat', 'crtest', '0.2', '0.0.1')

    e = cr.select('redhat', 'crtest', '0.1', '0.0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal 'redhat', e.cartridge_vendor
    assert_equal '0.0.1', e.cartridge_version
    assert_equal "#{@path}/redhat-crtest/0.0.1", e.repository_path

    e = cr.select('redhat', 'crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal '0.0.1', e.cartridge_version
  end

  def test_version_overrides
    paths = %W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
    )
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert cr.exist?('redhat', 'crtest', '0.1', '0.0.2')
    assert cr.exist?('redhat', 'crtest', '0.2', '0.0.2')

    e = cr.select('redhat', 'crtest', '0.1')
    refute_nil e
    assert_equal 'crtest', e.name
    assert_equal 'crtest', e.manifest['Name']
    assert_equal 'crtest', e.manifest['Display-Name']
    assert_equal '0.1', e.version
    assert_equal '0.0.2', e.cartridge_version
    assert e.categories.include?('service')
    assert e.versions.include?('0.1')
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.1')

    e = cr.select('redhat', 'crtest', '0.2')
    refute_nil e
    assert_equal 'crtest', e.name
    assert_equal 'crtest', e.manifest['Name']
    assert_equal 'crtest2', e.manifest['Display-Name']
    assert_equal '0.2', e.version
    assert_equal '0.0.2', e.cartridge_version
    assert !e.categories.include?('service')
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.2')
  end

  def test_erase
    paths = %W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
    )
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load
    puts "initial load:\n#{cr.to_s}"

    assert cr.exist?('redhat', 'crtest', '0.1', '0.0.2')
    assert cr.exist?('redhat', 'crtest', '0.2', '0.0.2')

    cr.expects(:installed_in_base_path?).with('crtest', '0.2', '0.0.2').returns(false)
    cr.erase('redhat', 'crtest', '0.2', '0.0.2')
    puts "after erase:\n#{cr.to_s}"

    refute cr.exist?('redhat', 'crtest', '0.2', '0.0.2')
    puts "after exist:\n#{cr.to_s}"

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.2', '0.0.2')
    end

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.2')
    end

    e = cr.select('redhat', 'crtest', '0.1')
    assert_equal '0.0.1', e.cartridge_version

    cr.expects(:installed_in_base_path?).with('crtest', '0.1', '0.0.1').returns(false)
    cr.erase('redhat', 'crtest', '0.1', '0.0.1')

    refute cr.exist?('redhat', 'crtest', '0.1', '0.0.1')

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.1', '0.0.1')
    end

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.1')
    end
  end

  def test_erase_base_cartridge_path
    paths = %W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
    )
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert cr.exist?('redhat', 'crtest', '0.1', '0.0.2')
    assert cr.exist?('redhat', 'crtest', '0.2', '0.0.2')

    cr.expects(:installed_in_base_path?).with('crtest', '0.2', '0.0.2').returns(true)

    assert_raise(ArgumentError) do
      cr.erase('redhat', 'crtest', '0.2', '0.0.2')
    end

    e = cr.select('redhat', 'crtest', '0.2')
    assert_equal '0.0.2', e.cartridge_version
  end

  def test_each
    populate_manifest(%W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.3/metadata/manifest.yml)
    )

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert_equal 5, cr.count
  end

  def test_latest_cartridge_version
    paths = %W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
    )
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert cr.exist?('redhat', 'crtest', '0.1', '0.0.2')
    assert cr.exist?('redhat', 'crtest', '0.2', '0.0.2')

    e = cr.select('redhat', 'crtest', '0.1')
    refute_nil e

    e = cr.select('redhat', 'crtest', '0.2')
    refute_nil e
    assert cr.latest_cartridge_version?('redhat', 'crtest', '0.2', '0.0.2')
    assert !cr.latest_cartridge_version?('redhat', 'crtest', '0.2', '0.0.1')
    assert !cr.latest_cartridge_version?('redhat', 'crtest', '0.1', '0.0.3')

    assert_equal '0.0.2', cr.latest_cartridge_version('redhat', 'crtest')
  end

  def test_latest_versions
    paths = %W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
               #{@path}/redhat-crtest/0.0.3/metadata/manifest.yml
    )
    populate_manifest(paths)

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    e = cr.select('redhat', 'crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal '0.0.2', e.cartridge_version

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.1', '0.0.3')
    end

    e = cr.select('redhat', 'crtest', '0.2')
    refute_nil e
    assert_equal '0.2', e.version
    assert_equal '0.0.3', e.cartridge_version
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.2')

    e = cr.select('redhat', 'crtest', '0.3')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '0.0.3', e.cartridge_version
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.3')

    e = cr['redhat', 'crtest', '0.3']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '0.0.3', e.cartridge_version

    lookup = {'0.1' => '0.0.2', '0.2' => '0.0.3', '0.3' => '0.0.3'}

    latest = cr.latest_versions

    latest.each do |cart|
      assert_equal 'crtest', cart.name
      assert_equal 'crtest', cart.manifest['Name']
    end

    assert_equal 2, latest.length

    latest.delete_if do |cart|
      cart.cartridge_version == lookup[cart.version]
    end

    assert latest.empty?
  end

  def test_not_found
    populate_manifest(%W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.3/metadata/manifest.yml)
    )

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    assert_raise(KeyError) do
      cr.select('redhat', 'crtest', '0.4')
    end
  end

  def test_vendor
    populate_manifest(%W(#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.2/metadata/manifest.yml
                         #{@path}/redhat-crtest/0.0.3/metadata/manifest.yml
                         #{@path}/example-crtest/0.0.1/metadata/manifest.yml)
    )

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    cartridge = cr.select('example', 'crtest', '0.1')
    assert_equal('example', cartridge.cartridge_vendor)
    assert_equal('crtest', cartridge.name)
    assert_equal('0.1', cartridge.version)
    assert_equal('0.0.1', cartridge.cartridge_version)

    cartridge = cr.select('example', 'crtest', '0.1', '0.0.1')
    assert_equal('example', cartridge.cartridge_vendor)
    assert_equal('crtest', cartridge.name)
    assert_equal('0.1', cartridge.version)
    assert_equal('0.0.1', cartridge.cartridge_version)
  end

  def test_insane_node_func_case
    manifest = %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '0.0.1'
        Cartridge-Vendor: redhat
        Categories:
          - web_framework
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

    populate_manifest_special({"#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml" => manifest})

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    e = cr.select('redhat', 'crtest', '0.1')
    refute_nil e
    assert_equal 'crtest', e.name
    assert_equal '0.1', e.version
    assert_equal '0.0.1', e.cartridge_version
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.1')

    e = cr.select('redhat', 'crtest', '0.2')
    refute_nil e
    assert_equal 'crtest', e.name
    assert_equal '0.2', e.version
    assert_equal '0.0.1', e.cartridge_version
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.2')

    e = cr.select('redhat', 'crtest', '0.3')
    refute_nil e
    assert_equal 'crtest', e.name
    assert_equal '0.3', e.version
    assert_equal '0.0.1', e.cartridge_version
    assert e.manifest['Group-Overrides'][0]['components'].include?('crtest-0.3')
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
        Categories:
          - web_framework
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Display-Name: crtest2
        Version: '0.2'
        Versions: ['0.1', '0.2']
        Cartridge-Version: '0.0.2'
        Compatible-Versions: ['0.0.1']
        Cartridge-Vendor: redhat
        Categories:
          - embedded
        Source-Url: http://example.com
        Group-Overrides:
          - components:
            - crtest-0.2
            - web_proxy
        Version-Overrides:
          '0.1':
            Display-Name: crtest
            Categories:
              - service
            Versions: ['0.2']
            Group-Overrides:
              - components:
                - crtest-0.1
                - web_proxy
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.3'
        Versions: ['0.2', '0.3']
        Cartridge-Version: '0.0.3'
        Cartridge-Vendor: redhat
        Categories:
          - web_framework
        Group-Overrides:
          - components:
            - crtest-0.3
            - web_proxy
        Version-Overrides:
          '0.2':
            Group-Overrides:
              - components:
                - crtest-0.2
                - web_proxy
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.1'
        Versions: ['0.1']
        Cartridge-Version: '0.0.1'
        Cartridge-Vendor: example
        Categories:
          - web_framework
      },
  ]
end
