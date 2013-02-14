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
require "test/unit"
require "mocha"
require "openshift-origin-node/utils/shell_exec"

module OpenShift
  class UtilsSpawnTest < Test::Unit::TestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      # Do nothing
    end

    # Called after every test method runs. Can be used to tear
    # down fixture information.

    def teardown
      # Do nothing
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

    def test_timeout
      assert_raises OpenShift::Utils::ShellExecutionException do
        Utils.oo_spawn("sleep 15",
                       :timeout => 1)
      end
    end

    def test_chdir
      out, err, rc = Utils.oo_spawn("touch #{Process.pid}.a",
                                 :chdir => "/tmp")
      assert_equal 0, rc
      assert_empty err
      assert_empty out
      assert File.exist?(File.join("/tmp",  Process.pid.to_s + ".a"))
    end

    def test_jailed_env
      assert_not_empty ENV['HOME']
      out, err, rc = Utils.oo_spawn("echo ${HOME}xx",
                                 :env => {},
                                 :unsetenv_others => true)
      assert_equal 0, rc
      assert_empty err
      assert_equal "xx\n", out
    end
  end
end
