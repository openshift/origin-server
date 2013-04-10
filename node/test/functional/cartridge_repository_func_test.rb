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
require 'openshift-origin-node/model/cartridge_repository'
require 'test/unit'
require 'mocha'

SimpleCov.command_name 'func_test'

class CartridgeRepositoryFunctionalTest < Test::Unit::TestCase

  def setup
    @uuid       = %x(uuidgen -r |sed -e s/-//g).chomp
    @name = "CRFTest_#{@uuid}"
    @repo_dir   = File.join(OpenShift::CartridgeRepository::CARTRIDGE_REPO_DIR, "redhat-#{@name}")
    @source_dir = "/tmp/tests/src-#{@uuid}"

    FileUtils.mkpath(OpenShift::CartridgeRepository::CARTRIDGE_REPO_DIR)
    FileUtils.mkpath(@source_dir + '/metadata')
    FileUtils.mkpath(@source_dir + '/bin')
    File.open(@source_dir + '/metadata/manifest.yml', 'w') do |f|
      f.write(%Q{#
        Name: CRFTest_#{@uuid}
        Cartridge-Short-Name: CRFTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: RedHat
      }
      )
    end
  end

  def teardown
    FileUtils.rm_rf(@repo_dir)
    FileUtils.rm_rf(@source_dir)
  end

  def test_install_remove
    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.install(@source_dir)

    manifest_path = @repo_dir + '/1.2/metadata/manifest.yml'
    assert(File.file?(manifest_path), "Manifest missing: #{manifest_path}")

    bin_path = @repo_dir + '/1.2/bin'
    assert(File.directory?(bin_path), "Directory missing: #{bin_path}")

    # Will raise exception if missing...
    cr.select(@name, '0.3')

    assert_raise(KeyError) do
      cr.select('CRFTest', '0.4')
    end

    # Will raise exception if missing...
    cr.erase(@name, '0.3', '1.2')

    assert_raise(KeyError) do
      cr.select(@name)
    end

    bin_path = @repo_dir + '/1.2'
    assert(!File.directory?(bin_path), "Directory not deleted: #{bin_path}")
  end

  def test_reinstall
    cr = OpenShift::CartridgeRepository.instance
    cr.clear
    cr.install(@source_dir)

    bin_path = @repo_dir + '/1.2/bin'
    assert(File.directory?(bin_path), "Directory missing: #{bin_path}")

    # Will raise exception if missing...
    cr.select(@name, '0.3')

    FileUtils.rm_r(File.join(@source_dir, 'bin'))
    cr.clear
    cr.install(@source_dir)

    assert(!File.directory?(bin_path), "Unexpected directory found: #{bin_path}")
  end
end
