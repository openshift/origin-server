#--
# Copyright 2010 Red Hat, Inc.
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

require 'active_support/core_ext/class/attribute'

require 'openshift-origin-frontend-apachedb'
require 'test_helper'

require 'tmpdir'
require 'fileutils'

module OpenShift

  class ApacheDBTestCase < NodeBareTestCase

    def setup
      @basedir = Dir.mktmpdir
      @lockfilebase = File.join(@basedir, "lock")

      @config = mock('OpenShift::Config')
      @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns(@basedir)
      OpenShift::Config.stubs(:new).returns(@config)

      @mutex_mock = mock('Mutex')

      @dbname = "mock_apachedb"

      @dbclass = ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
      @dbclass.any_instance.stubs(:LOCKFILEBASE).returns(@lockfilebase)
      @dbclass.any_instance.stubs(:LOCK).returns(@mutex_mock)
      @dbclass.any_instance.stubs(:MAPNAME).returns(@dbname)

      @dbfile = File.join(@basedir, @dbname + ".txt")
      @dbfile_db = File.join(@basedir, @dbname + ".db")
      @lockfile = @lockfilebase + "." + @dbname + ".txt.lock"
    end

    def test_writeable
      @mutex_mock.expects(:lock)
      @mutex_mock.expects(:unlock)
      @mutex_mock.expects(:locked?).returns(true)

      assert @dbclass::WRCREAT, "ApacheDB does not have a WRCREAT flag"

      assert (not File.exists?(@lockfile)), "Lock file should not exist until the db is open."

      ::OpenShift::Runtime::Utils.expects(:oo_spawn).with() do |cmd|
        if cmd =~ /^.*httxt2dbm -f DB -i #{@dbfile} -o (.*)$/
          File.open($~[1], "w") do |f|
            f.write("blah")
          end
        end
      end

      File.open(@dbfile, "w")

      @dbclass.open(@dbclass::WRCREAT) do |d|
        d["foo"] = "bar"
        d["bar"] = "baz"
        d["baz"] = "foo"
        assert File.exists?(@lockfile), "Lock file does not exist."
      end

      assert File.exists?(@dbfile), "Database file does not exist"
      assert_equal "foo bar\nbar baz\nbaz foo\n", File.read(@dbfile)
      assert_equal "blah", File.read(@dbfile_db)
    end

    def test_reader
      @mutex_mock.expects(:lock)
      @mutex_mock.expects(:unlock)
      @mutex_mock.expects(:locked?).returns(true)

      assert @dbclass::READER,  "ApacheDB does not have a READER flag"

      File.open(@dbfile, "w") do |f|
        f.write("foo bar\n")
        f.write("bar baz\n")
        f.write("baz foo\n")
      end

      @dbclass.open(@dbclass::READER) do |d|
        assert_equal "bar", d["foo"], "Parse error reading database"
        assert_equal "baz", d["bar"], "Parse error reading database"
        assert_equal "foo", d["baz"], "Parse error reading database"
      end

    end

    def teardown
      FileUtils.rm_rf(@basedir)
    end

  end

end
