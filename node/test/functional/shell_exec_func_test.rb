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

require "openshift-origin-node/utils/shell_exec"
require 'test_helper'
require "test/unit"
require "mocha"

module OpenShift
  class UtilsSpawnFunctionalTest < Test::Unit::TestCase

    def setup
      @uid     = 1000
      @homedir = "/tmp/tests/#@uid"

      # polyinstantiation makes creating the homedir a pain...
      FileUtils.rm_r @homedir if File.exist?(@homedir)
      FileUtils.mkpath(@homedir)
      %x{useradd -u #@uid -d #@homedir #@uid 1>/dev/null 2>&1}
      %x{chown -R #@uid:#@uid #@homedir}
      FileUtils.mkpath(File.join(@homedir, '.tmp', @uid.to_s))
      FileUtils.chmod(0, File.join(@homedir, '.tmp'))
    end

    def teardown
      %x{userdel #@uid 1>/dev/null}
      %x{rm -rf #@homedir}
    end

    def test_run_as
      skip 'run_as tests require root permissions' if 0 != Process.uid

      out, err, rc = Utils.oo_spawn("touch #{Process.pid}.b",
                                    chdir: '/tmp',
                                    uid:   @uid)
      assert_equal 0, rc
      assert_empty err
      assert_empty out
      stats = File.stat(File.join('/tmp', Process.pid.to_s + ".b"))
      assert_equal @uid, stats.uid

      c = File.join(@homedir, Process.pid.to_s + ".c")
      FileUtils.touch c
      stats = File.stat(c)
      assert_equal Process.uid, stats.uid
    end

    def test_run_as_with_error
      skip 'run_as tests require root permissions' if 0 != Process.uid

      _, _, rc = Utils.oo_spawn("/bin/false",
                                chdir: @homedir,
                                uid:   @uid)
      assert_equal 1, rc
    end

    def test_run_as_with_stderr
      skip 'run_as tests require root permissions' if 0 != Process.uid

      out, err, rc = Utils.oo_spawn("/bin/echo 'Good bye, Cruel World' 1>&2; /bin/false",
                                    chdir: @homedir,
                                    uid:   @uid)
      assert_equal 1, rc
      assert_empty out
      assert_equal "Good bye, Cruel World\n", err
    end

    def test_run_as_with_exitstatus
      skip 'run_as tests require root permissions' if 0 != Process.uid

      assert_raise(Utils::ShellExecutionException) do
        Utils.oo_spawn("/bin/false",
                       chdir:               @homedir,
                       uid:                 @uid,
                       expected_exitstatus: 0)
      end
    end

    def test_run_as_stdout
      skip "run_as tests require root permissions" if 0 != Process.uid

      out, err, rc = Utils.oo_spawn("echo Hello, World",
                                    uid: @uid)
      assert_equal 0, rc
      assert_empty err
      assert_equal "Hello, World\n", out
    end

    def test_expected_exitstatus_zero
      out, err, rc = Utils.oo_spawn('/bin/true',
                                    chdir:               @homedir,
                                    expected_exitstatus: 0)
      assert_equal 0, rc
      assert_empty err
      assert_empty out
    end

    def test_expected_exitstatus
      out, err, rc = Utils.oo_spawn('/bin/false',
                                    chdir:               @homedir,
                                    expected_exitstatus: 1)
      assert_equal 1, rc
      assert_empty err
      assert_empty out
    end

    def test_expected_exception
      assert_raise(Utils::ShellExecutionException) do
        Utils.oo_spawn('/bin/false',
                       chdir:               @homedir,
                       expected_exitstatus: 0)
      end
    end

    def test_timeout
      assert_raises OpenShift::Utils::ShellExecutionException do
        Utils.oo_spawn("sleep 15",
                       timeout: 1)
      end
    end

    def test_stdout
      out, err, rc = Utils.oo_spawn("echo Hello, World")
      assert_equal 0, rc
      assert_empty err
      assert_equal "Hello, World\n", out
    end

    def test_stderr
      out, err, rc = Utils.oo_spawn("echo Hello, World 1>&2")
      assert_equal 0, rc
      assert_empty out
      assert_equal "Hello, World\n", err
    end

    def test_chdir
      out, err, rc = Utils.oo_spawn("touch #{Process.pid}.a",
                                    chdir: @homedir)
      assert_equal 0, rc
      assert_empty err
      assert_empty out

      expected = File.join(@homedir, Process.pid.to_s + '.a')
      assert File.exist?(expected), "#{expected} is missing"
    end

    def test_jailed_env
      assert_not_empty ENV['HOME']
      out, err, rc = Utils.oo_spawn('echo ${HOME}xx',
                                    env:             {},
                                    unsetenv_others: true)
      assert_equal 0, rc
      assert_empty err
      assert_equal "xx\n", out
    end

    def test_env
      assert_not_empty ENV['HOME']
      out, err, rc = Utils.oo_spawn('echo ${HOME}xx')
      assert_equal 0, rc
      assert_empty err
      assert_equal "#{ENV['HOME']}xx\n", out
    end

    def test_run_as_env
      assert_not_empty ENV['HOME']
      out, err, rc = Utils.oo_spawn('echo ${HOME}xx',
                                    uid: @uid)
      assert_equal 0, rc
      assert_empty err
      assert_equal "#{ENV['HOME']}xx\n", out
    end
  end
end
