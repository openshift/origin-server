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
require 'webmock'
require 'webmock/minitest'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-common/models/manifest'
require 'digest'
require 'securerandom'

module OpenShift
  class CartridgeRepositoryFunctionalTest < NodeTestCase

    def before_setup

      @uuid = SecureRandom.uuid.gsub('-', '')[0..15]

      @test_home      = "/data/tests/#{@uuid}"
      @tgz_file       = File.join(@test_home, 'mock_plugin.tar.gz')
      @zip_file       = File.join(@test_home, 'mock_plugin.zip')
      @tar_file       = File.join(@test_home, 'mock_plugin.tar')
      @malformed_file = File.join(@test_home, 'malformed.zip')

      FileUtils.mkpath(@test_home)
      ::OpenShift::Runtime::CartridgeRepository.instance.load()
      @cartridge = ::OpenShift::Runtime::CartridgeRepository.instance.select('redhat', 'mock-plugin', '0.1')
      %x(shopt -s dotglob;
         cd #{@cartridge.repository_path};
         zip -r #{@zip_file} *;
         tar zcf #{@tgz_file} ./*;
         tar cf #{@tar_file} ./*;
         zip  #{@malformed_file} README.md;
      )

      @tgz_hash = %x(md5sum #{@tgz_file} |cut -d' ' -f1)
      @tar_hash = %x(md5sum #{@tar_file} |cut -d' ' -f1)
      @zip_hash = %x(md5sum #{@zip_file} |cut -d' ' -f1)

      stub_request(:get, 'https://www.example.com/mock-plugin.tar.gz').
          with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => File.new(@tgz_file), :headers => {})

      stub_request(:get, 'http://www.example.com/mock-plugin.tar').
          with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => File.new(@tar_file), :headers => {})

      stub_request(:get, 'https://www.example.com/mock-plugin.zip').
          with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => File.new(@zip_file), :headers => {})

      stub_request(:get, 'https://www.example.com/malformed.zip').
          with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => File.new(@malformed_file), :headers => {})
    end

    def after_teardown
      FileUtils.rm_rf @test_home
    end

    def setup
      WebMock.disable_net_connect! allow_localhost: true

      @name       = "crftest_#{@uuid}"
      @repo_dir   = File.join(::OpenShift::Runtime::CartridgeRepository::CARTRIDGE_REPO_DIR, "redhat-#{@name}")
      @source_dir = "#{@test_home}/src-#{@uuid}"

      FileUtils.mkpath(::OpenShift::Runtime::CartridgeRepository::CARTRIDGE_REPO_DIR)
      FileUtils.mkpath(@source_dir + '/metadata')
      FileUtils.mkpath(@source_dir + '/bin')
      File.open(@source_dir + '/metadata/manifest.yml', 'w') do |f|
        f.write(%Q{#
        Name: crftest_#{@uuid}
        Cartridge-Short-Name: CRFTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '1.2'
        Cartridge-Vendor: redhat
        Categories:
          - web_framework
      }
        )
      end
    end

    def teardown
      WebMock.allow_net_connect!

      FileUtils.rm_rf(@repo_dir)
      FileUtils.rm_rf(@source_dir)
      FileUtils.rm_rf(@test_home)
    end

    def test_install_erase
      cr = ::OpenShift::Runtime::CartridgeRepository.instance
      cr.clear
      cr.install(@source_dir)

      manifest_path = @repo_dir + '/1.2/metadata/manifest.yml'
      assert(File.file?(manifest_path), "Manifest missing: #{manifest_path}")

      bin_path = @repo_dir + '/1.2/bin'
      assert(File.directory?(bin_path), "Directory missing: #{bin_path}")

      # Will raise exception if missing...
      cr.select('redhat', @name, '0.3')

      assert_raise(KeyError) do
        cr.select('redhat', 'crftest', '0.4')
      end

      # Will raise exception if missing...
      cr.erase('redhat', @name, '0.3', '1.2')

      bin_path = @repo_dir + '/1.2'
      assert(!File.directory?(bin_path), "Directory not deleted: #{bin_path}")
    end

    def test_reinstall
      cr = ::OpenShift::Runtime::CartridgeRepository.instance
      cr.clear
      cr.install(@source_dir)

      bin_path = @repo_dir + '/1.2/bin'
      assert(File.directory?(bin_path), "Directory missing: #{bin_path}")

      # Will raise exception if missing...
      cr.select('redhat', @name, '0.3')

      FileUtils.rm_r(File.join(@source_dir, 'bin'))
      cr.clear
      cr.install(@source_dir)

      assert(!File.directory?(bin_path), "Unexpected directory found: #{bin_path}")
    end

    def test_load_zero_length_manifest
      cr = ::OpenShift::Runtime::CartridgeRepository.instance
      cr.clear
      cr.install(@source_dir)

      cr.select('redhat', @name, '0.3')
      cr.select('redhat', @name, '0.2')
      cr.select('redhat', @name, '0.1')

      manifest_path = @repo_dir + '/1.2/metadata/manifest.yml'
      File.truncate(manifest_path, 0)  # YAML.load does not like zero-size files and will return 'false'

      cr.clear()
      cr.load()

      assert_raise(KeyError) do
        cr.select('redhat', @name, '0.3')
      end

      assert_raise(KeyError) do
        cr.select('redhat', @name, '0.2')
      end

      assert_raise(KeyError) do
        cr.select('redhat', @name, '0.1')
      end
    end

    def test_instantiate_cartridge_git
      cuckoo_repo, cuckoo_source = build_cuckoo_home()

      Dir.chdir(File.dirname(cuckoo_repo)) do
        %x(git </dev/null clone --bare --no-hardlinks #{cuckoo_repo} #{cuckoo_repo}.git 2>&1)
      end

      # Point manifest at "remote" repository
      manifest = IO.read(File.join(cuckoo_source, 'metadata', 'manifest.yml'))
      manifest << ('Source-Url: file://' + cuckoo_repo + '.git') << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      with_detail_output do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      assert_path_exist(cartridge_home)
      assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
      refute File.symlink?(File.join(cartridge_home, 'usr'))
    end


    def test_instantiate_cartridge_file
      _, cuckoo_source = build_cuckoo_home()

      needs_escape = File.join(cuckoo_source, '; touch test;')
      FileUtils.touch(needs_escape)

      # Point manifest at "remote" repository
      manifest         = IO.read(File.join(cuckoo_source, 'metadata', 'manifest.yml'))
      manifest << ('Source-Url: file://' + cuckoo_source) << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      with_detail_output do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      assert_path_exist(cartridge_home)
      assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
      assert_path_exist(needs_escape)
      refute File.symlink?(File.join(cartridge_home, 'usr'))
    end

    def test_instantiate_cartridge_zip
      # Point manifest at "remote" URL
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << 'Source-Url: https://www.example.com/mock-plugin.zip' << "\n"
      manifest << "Source-Md5: #{@zip_hash}" << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      with_detail_output do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      assert_path_exist(cartridge_home)
      assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
    end

    def test_instantiate_cartridge_zip_bad_md5
      # Point manifest at "remote" URL
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << 'Source-Url: https://www.example.com/mock-plugin.zip' << "\n"
      manifest << 'Source-Md5: 666' << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      assert_raise (IOError) do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      refute_path_exist(cartridge_home)
    end

    def test_instantiate_cartridge_malformed
      # Point manifest at "remote" URL
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << 'Source-Url: https://www.example.com/malformed.zip' << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      e = assert_raise (::OpenShift::Runtime::MalformedCartridgeError) do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      refute_empty e.details, 'Details of malformed cartridge missing'
      refute_path_exist(cartridge_home)
    end

    def test_invalid_vendor_name
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << "Cartridge-Vendor: 0a_" << "\n"
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}"

      err = assert_raise(::OpenShift::InvalidElementError) do
        cartridge = ::OpenShift::Runtime::Manifest.new(manifest)
      end

      assert_match 'Cartridge-Vendor', err.message
    end

    def test_vendor_name_too_long
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << "Cartridge-Vendor: #{'a'* (::OpenShift::Runtime::Manifest::MAX_VENDOR_NAME + 1)}\n"
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}"

      err = assert_raise(::OpenShift::InvalidElementError) do
        cartridge = ::OpenShift::Runtime::Manifest.new(manifest)
      end

      assert_match 'Cartridge-Vendor', err.message
    end

    def test_invalid_cartridge_name
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << "Name: 0a-" << "\n"
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}"
      manifest = change_cartridge_vendor_of manifest

      err = assert_raise(::OpenShift::InvalidElementError) do
        cartridge = ::OpenShift::Runtime::Manifest.new(manifest)
      end

      assert_match /\bName\b/, err.message
    end

    def test_cartridge_name_too_long
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << "Name: #{'a'* (::OpenShift::Runtime::Manifest::MAX_CARTRIDGE_NAME + 1)}\n"
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}"
      manifest = change_cartridge_vendor_of manifest

      err = assert_raise(::OpenShift::InvalidElementError) do
        cartridge = ::OpenShift::Runtime::Manifest.new(manifest)
      end

      assert_match 'Name', err.message
    end

    def test_reserved_cartridge_name
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << "Name: git" << "\n"
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}"
      manifest = change_cartridge_vendor_of manifest

      err = assert_raise(::OpenShift::InvalidElementError) do
        cartridge = ::OpenShift::Runtime::Manifest.new(manifest)
      end

      assert_match /Name 'git' is reserved\./, err.message
    end

    def test_instantiate_cartridge_tgz
      # Point manifest at "remote" URL
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << 'Source-Url: https://www.example.com/mock-plugin.tar.gz' << "\n"
      manifest << "Source-Md5: #{@tgz_hash}" << "\n"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      with_detail_output do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      assert_path_exist(cartridge_home)
      assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
    end

    def test_instantiate_cartridge_tar
      # Point manifest at "remote" URL
      manifest = IO.read(File.join(@cartridge.manifest_path))
      manifest << 'Source-Url: http://www.example.com/mock-plugin.tar' << "\n"
      manifest << "Source-Md5: #{@tar_hash}"
      manifest = change_cartridge_vendor_of manifest

      cartridge      = ::OpenShift::Runtime::Manifest.new(manifest)
      cartridge_home = "#{@test_home}/gear/mock-plugin"

      with_detail_output do
        ::OpenShift::Runtime::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
      end

      assert_path_exist(cartridge_home)
      assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
    end

    def test_cartridge_update
      build_multi_versions()

      name = "crftest_#{@uuid}"
      cr   = ::OpenShift::Runtime::CartridgeRepository.instance
      cr.clear

      cr.install(@source_dir + '/2')
      m = cr.select('redhat', name, '0.3')
      assert_equal '0.0.2', m.cartridge_version

      cr.install(@source_dir + '/3')
      m = cr.select('redhat', name, '0.3')
      assert_equal '0.0.3', m.cartridge_version
    end

    def with_detail_output
      begin
        yield
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        NodeLogger.logger.debug(e.message + "\n" +
                                    e.stdout + "\n" +
                                    e.stderr + "\n" +
                                    e.backtrace.join("\n")
        )
      end
    end

    def build_cuckoo_home
      cuckoo_source = "#{@test_home}/cuckoo"
      FileUtils.mkpath(cuckoo_source)
      %x(shopt -s dotglob; cp -ad #{@cartridge.repository_path}/* #{cuckoo_source})

      # build our "remote" cartridge repository
      cuckoo_repo = File.join("#{@test_home}/cuckoo_repo")
      FileUtils.mkpath cuckoo_repo

      Dir.chdir(cuckoo_repo) do
        %x(git init;
          shopt -s dotglob;
          cp -ad #{cuckoo_source}/* .;
          git add -f .;
          git </dev/null commit -a -m "Creating cuckoo template" 2>&1;
        )
      end

      return cuckoo_repo, cuckoo_source
    end

    def build_multi_versions
      (1..3).each do |i|
        target = File.join(@source_dir, i.to_s)
        FileUtils.mkpath(target + '/metadata')
        FileUtils.mkpath(target + '/bin')
        IO.write(target + '/metadata/manifest.yml', %Q{#
        Name: crftest_#{@uuid}
        Cartridge-Short-Name: CRFTEST
        Version: '0.3'
        Cartridge-Version: '0.0.#{i}'
        Cartridge-Vendor: redhat
        Categories:
          - web_framework
      }
        )
      end
    end
  end
end
