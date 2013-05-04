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

class CartridgeRepositoryTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear

    @path = '/var/lib/openshift/.cartridge_repository'
    OpenShift::CartridgeRepository.instance.clear
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

  def test_one_manifest
    populate_manifest(%W(#{@path}/redhat-crtest/1.0/metadata/manifest.yml))

    cr = OpenShift::CartridgeRepository.instance
    cr.load
    refute_nil cr

    e = cr.select('crtest', '0.1', '1.0')
    refute_nil e
    assert_equal '0.1', e.version
    assert_equal "#{@path}/redhat-crtest/1.0", e.repository_path
    assert_equal 'redhat', e.cartridge_vendor

    e = cr.select('crtest', '0.1')
    refute_nil e
    assert_equal '0.1', e.version

    e = cr.select('crtest')
    refute_nil e
    assert_equal '0.1', e.version

    assert_equal "#{@path}/redhat-crtest/1.0", e.repository_path
  end

  def test_each
    populate_manifest(["#{@path}/redhat-crtest/1.0/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.1/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.2/metadata/manifest.yml"])

    cr = OpenShift::CartridgeRepository.instance
    cr.load

    assert_equal 3, cr.count
  end

  def test_three_manifest
    populate_manifest(["#{@path}/redhat-crtest/1.0/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.1/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.2/metadata/manifest.yml"])

    cr = OpenShift::CartridgeRepository.instance
    cr.load

    e = cr.select('crtest')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    cr = OpenShift::CartridgeRepository.instance
    e  = cr.select('crtest', '0.3')
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    e = cr['crtest']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version

    cr = OpenShift::CartridgeRepository.instance
    e  = cr['crtest', '0.3']
    refute_nil e
    assert_equal '0.3', e.version
    assert_equal '1.2', e.cartridge_version
  end

  def test_not_found
    populate_manifest(["#{@path}/redhat-crtest/1.0/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.1/metadata/manifest.yml",
                       "#{@path}/redhat-crtest/1.2/metadata/manifest.yml"])

    cr = OpenShift::CartridgeRepository.instance
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
        Cartridge-Version: '1.0'
        Cartridge-Versions: ['1.0']
        Cartridge-Vendor: redhat
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.2'
        Versions: ['0.1', '0.2']
        Cartridge-Version: '1.1'
        Cartridge-Versions: ['1.0', '1.1']
        Cartridge-Vendor: redhat
      },
      %q{#
        Name: crtest
        Cartridge-Short-Name: crtest
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: redhat
      },
  ]
end
