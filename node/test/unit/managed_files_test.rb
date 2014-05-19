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
# Test the OpenShift managed_files helper module
#
require_relative '../test_helper'

module OpenShift
  class ManagedFilesTest < OpenShift::NodeTestCase
    include OpenShift::Runtime::ManagedFiles

    def setup
      @container_dir = "#{Dir.mktmpdir}/"

      @cartridge = OpenStruct.new({
        :name =>  'mock',
        :directory =>  'mock',
        :short_name =>  'MOCK'
      })
      FileUtils.mkdir_p(File.join(@container_dir,@cartridge.directory))
    end

    # Set the managed_files hash
    def set_managed_files(hash)
      File.join(@container_dir,@cartridge.directory,'metadata','managed_files.yml').tap do |manifest_file|
        FileUtils.mkdir_p(File.dirname(manifest_file))
        File.open(manifest_file,'w') do |f|
          f.write(hash.to_yaml)
        end
      end
    end

    # Create files for globbing
    def touch_files(files)
      files.each do |path|
        full_path = File.join(@container_dir,@cartridge.directory,path)
        dir = File.dirname(full_path)
        FileUtils.mkdir_p(dir)
        FileUtils.touch(full_path)
      end
    end

    # create symlink in @cartridge.directory
    # 'files' should be a Hash {link => target, ...}
    def symlink_files(files)
      files.each do |link, path|
        target = File.join(@container_dir, @cartridge.directory, path)
        sl = File.join(@container_dir, @cartridge.directory, link)
        dir = File.dirname(target)
        linkdir = File.dirname(sl)
        FileUtils.mkdir_p(dir)
        FileUtils.mkdir_p(linkdir)
        FileUtils.ln_sf(target, sl)
      end
    end

    # Transform relative file paths
    def chroot_files(files)
      files.map do |x|
        x = "~/#{@cartridge.name}/#{x}" unless x.start_with?("~")
        x.sub(/^~\//,@container_dir)
      end
    end

    def test_missing_managed_files
      logger = mock()
      logger.expects(:info).with { |x| x =~ /.yml is missing$/ }
      ::OpenShift::Runtime::NodeLogger.expects(:logger).returns(logger)
      assert_empty managed_files(@cartridge, :foo, @container_dir)
    end

    def test_empty_managed_files
      FileUtils.mkdir_p(File.join(@container_dir, @cartridge.directory, 'metadata'))
      IO.write(File.join(@container_dir, @cartridge.directory, 'metadata', 'managed_files.yml'), '')
      logger = mock()
      logger.expects(:info).with { |x| x =~ /.yml is empty/ }
      ::OpenShift::Runtime::NodeLogger.expects(:logger).returns(logger)
      assert_empty managed_files(@cartridge, :foo, @container_dir)
    end

    # Ensure that managed_files does not attempt to render the values in any way
    def test_get_managed_files
      %w(a ./b /c ~/d e/f/g).tap do |expected|
        set_managed_files({:foo => expected})
        assert_equal expected, managed_files(@cartridge, :foo, @container_dir, false)
      end
    end

    def test_block_immutable_files
      %w(metadata/manifest.yml metadata/managed_files.yml env/OPENSHIFT_MOCK_IDENT env/OPENSHIFT_MOCK_DIR a).tap do |expected|
        set_managed_files({:foo => expected})

        assert_equal %w(mock/a), managed_files(@cartridge, :foo, @container_dir)
      end
    end

    def test_setup_rewritten
      src = 'this/file'
      link = 'this/link'
      dotfile = 'this/.foo'
      deep = 'this/is/a/file'
      touch_files [src, dotfile, deep]
      symlink_files link => src

      set_managed_files({:setup_rewritten => ['this/**/*']})

      expected_files = %w(
        mock/this/file
        mock/this/link
        mock/this/.foo
        mock/this/is
        mock/this/is/a
        mock/this/is/a/file
      )
      assert_equal expected_files.sort, setup_rewritten(@cartridge).sort
    end

    # Ensure locked_files does not return bad entries
    def test_get_locked_files_static
      good_files = %w(~/.good ~/app-root/good good ~/app-root/foo/good/) << "~/#{@cartridge.directory}/good"
      blacklist_files = %w(~/.ssh/bad)
      oob_files = %w(~/../bad)
      set_managed_files({:locked_files => good_files | blacklist_files | oob_files })

      expected_files = chroot_files(good_files)
      assert_equal expected_files.sort, locked_files(@cartridge).sort
    end

    # Ensure the glob doesn't return unexpected files
    def test_get_locked_files_glob
      files = %w(
        glob/foo/bar/good
        glob/foo/good
        glob/bar/baz/good
        glob/bar/bad/bad
        conf/foo/bar/good.erb
      )
      touch_files(files)
      expected_files = chroot_files(files).select{|x| x =~ /good/ }

      glob_files = %w(glob/foo/**/* glob/bar/baz/* conf/**/*.erb)

      set_managed_files({:locked_files => glob_files})
      assert_equal expected_files.sort, locked_files(@cartridge).sort
    end

    # Ensure that the restore transforms are returned verbatim
    def test_restore_transforms
      ['s|${OPENSHIFT_GEAR_NAME}/data|app-root/data|'].tap do |expected|
        set_managed_files({:restore_transforms => expected})
        assert_equal expected, restore_transforms(@cartridge)
      end
    end
  end
end
