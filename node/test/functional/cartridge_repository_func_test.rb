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

SimpleCov.command_name 'func_test'

class Object
  class << self
    def with_constants(constants, &block)
      old_constants         = Hash.new
      old_verbose, $VERBOSE = $VERBOSE, nil
      begin
        constants.each do |constant, val|
          old_constants[constant] = const_get(constant)
          const_set(constant, val)
        end
      ensure
        $VERBOSE = old_verbose
      end

      error = nil
      begin
        block.call
      rescue Exception => e
        error = e
      end

      begin
        $VERBOSE = nil
        old_constants.each do |constant, val|
          const_set(constant, val)
        end
      ensure
        $VERBOSE = old_verbose
      end

      raise error unless error.nil?
    end
  end
end

class CartridgeRepositoryFunctionalTest < Test::Unit::TestCase

  def setup
    @uuid = %x(uuidgen -r |sed -e s/-//g).chomp
    @repo_dir = "/tmp/tests/repo-#{@uuid}"
    @source_dir = "/tmp/tests/src-#{@uuid}"

    FileUtils.mkpath(@repo_dir)
    FileUtils.mkpath(@source_dir + '/metadata')
    FileUtils.mkpath(@source_dir + '/bin')
    File.open(@source_dir + '/metadata/manifest.yml', 'w') do |f|
      f.write(%q{#
        Name: CRFTest
        Cartridge-Short-Name: CRFTEST
        Version: 0.3
        Versions: [0.1, 0.2, 0.3]
        Cartridge-Version: 1.2
        Cartridge-Vendor: RedHat
      }
      )
    end
  end

  def teardown
    FileUtils.rm_r(@repo_dir)
    FileUtils.rm_r(@source_dir)
  end

  def test_install_remove
    OpenShift::CartridgeRepository.with_constants(CARTRIDGE_REPO_DIR: @repo_dir) do
      cr = OpenShift::CartridgeRepository.instance
      cr.install(@source_dir)

      manifest_path = @repo_dir + '/RedHat-CRFTest/1.2/metadata/manifest.yml'
      assert(File.file?(manifest_path), "Manifest missing: #{manifest_path}")

      bin_path = @repo_dir + '/RedHat-CRFTest/1.2/bin'
      assert(File.directory?(bin_path), "Directory missing: #{bin_path}")

      # Will raise exception if missing...
      cr.select('CRFTest', '0.3')

      assert_raise(KeyError) do
        cr.select('CRFTest', '0.4')
      end

      # Will raise exception if missing...
      cr.erase('CRFTest', '0.3', '1.2')

      assert_raise(KeyError) do
        cr.select('CRFTest')
      end

      bin_path = @repo_dir + '/RedHat-CRFTest/1.2'
      assert(!File.directory?(bin_path), "Directory not deleted: #{bin_path}")
    end
  end
end
