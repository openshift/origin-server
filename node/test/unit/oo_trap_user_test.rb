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
require "test/unit"
require "mocha"
require "base64"
require File.expand_path("../node/misc/bin/oo-trap-user.rb")

module OpenShift
  class TrapUserTest < Test::Unit::TestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      @uuid        = "a62d6dd9e6cd4be6841bedb5750a01fb"
      @gear_dir    = File.join("/tmp", @uuid)
      @runtime_dir = File.join(@gear_dir, "app-root", "runtime")
      @logs_dir    = File.join(@gear_dir, "app-root", "logs")

      FileUtils.mkpath(@runtime_dir)
      FileUtils.mkpath(@logs_dir)
    end

    # Called after every test method runs. Can be used to tear
    # down fixture information.

    def teardown
      FileUtils.rm_rf(File.join("/tmp", @uuid))
    end

    def test_unknown
      ENV['SSH_ORIGINAL_COMMAND'] = 'expected_error'
      rc                          = OpenShift::Application::TrapUser.new.apply
      assert_equal 2, rc
    end

    def test_rhcsh
      # env["PS1"] = "rhcsh> "
      Kernel.stubs(:exec).with(
          {"PS1" => "rhcsh> "},
          "/bin/bash",
          ["/bin/bash", "--init-file", "/usr/bin/rhcsh", "-i"]
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'rhcsh'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_cd
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash",
          ["/bin/bash", "-c", "cd /tmp"]
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'cd /tmp'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_tail
      `echo Hello, World > #@logs_dir/mock.log`
      tail_opts = Base64.encode64("-n 100")
      Kernel.stubs(:exec).with(
          {},
          "/usr/bin/tail",
          ["/usr/bin/tail", "-n", "100", "-f", "app-root/logs/mock.log"]
      ).returns(0)

      Dir.chdir(@gear_dir) do
        ENV['SSH_ORIGINAL_COMMAND'] = "tail --opts #{tail_opts} app-root/logs/mock.log"
        rc                          = OpenShift::Application::TrapUser.new.apply

        assert_equal 1, rc
      end
    end
  end
end
