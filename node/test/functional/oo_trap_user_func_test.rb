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

require_relative '../../misc/bin/oo-trap-user'

require 'test_helper'
require "test/unit"
require "mocha"
require "base64"

module OpenShift
  class TrapUserFunctionalTest < Test::Unit::TestCase

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
      ENV['SSH_ORIGINAL_COMMAND'] = 'unknown'
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "-c", "unknown"
      ).returns(0)
      OpenShift::Application::TrapUser.new.apply
    end

    def test_rhcsh
      # env["PS1"] = "rhcsh> "
      Kernel.stubs(:exec).with(
          {"PS1" => "rhcsh> "},
          "/bin/bash", "--init-file", "/usr/bin/rhcsh", "-i"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'rhcsh'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_rhcsh_argvs
      # env["PS1"] = "rhcsh> "
      Kernel.stubs(:exec).with(
          {"PS1" => "rhcsh> "},
          "/bin/bash", "--init-file", "/usr/bin/rhcsh", "-c", "ls", "/tmp"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'rhcsh ls /tmp'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_ctl_all
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "-c", ". /usr/bin/rhcsh > /dev/null ; ctl_all start app001"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'ctl_all start app001'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_snapshot
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "snapshot.sh"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'snapshot'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_restore
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "restore.sh"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'restore'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_restore_include_git
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "restore.sh", "INCLUDE_GIT"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'restore INCLUDE_GIT'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_cd
      Kernel.stubs(:exec).with(
          {},
          "/bin/bash", "-c", "cd", "/tmp"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'cd /tmp'
      OpenShift::Application::TrapUser.new.apply
    end

    def test_tail
      `echo Hello, World > #@logs_dir/mock.log`
      tail_opts = Base64.encode64("-n 100")
      Kernel.stubs(:exec).with(
          {},
          "/usr/bin/tail", "-f", "-n", "100", "app-root/logs/mock.log"
      ).returns(0)

      Dir.chdir(@gear_dir) do
        ENV['SSH_ORIGINAL_COMMAND'] = "tail --opts #{tail_opts} app-root/logs/mock.log"
        OpenShift::Application::TrapUser.new.apply
      end
    end

    def test_tail_with_follow
      `echo Hello, World > #@logs_dir/mock.log`
      tail_opts = Base64.encode64("-n 100 -f")
      Kernel.stubs(:exec).with(
          {},
          "/usr/bin/tail", "-n", "100", "-f", "app-root/logs/mock.log"
      ).returns(0)

      Dir.chdir(@gear_dir) do
        ENV['SSH_ORIGINAL_COMMAND'] = "tail --opts #{tail_opts} app-root/logs/mock.log"
        OpenShift::Application::TrapUser.new.apply
      end
    end

    def test_git_receive_pack
      home_dir      = File.join("/tmp", Process.pid.to_s)
      git_directory = File.join(home_dir, "git")
      FileUtils.mkpath(git_directory)

      config = mock('OpenShift::Config')
      config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")
      OpenShift::Config.stubs(:new).returns(config)

      old_home_dir = ENV['HOME']
      ENV['HOME']  = home_dir
      begin
        Kernel.stubs(:exec).with(
            {},
            "/usr/bin/git-receive-pack", '~/git'
        ).returns(0)

        ENV['SSH_ORIGINAL_COMMAND'] = "git-receive-pack ~/git"
        OpenShift::Application::TrapUser.new.apply
      ensure
        FileUtils.rm_rf(home_dir)
        ENV['HOME'] = old_home_dir
      end
    end

    def test_quota
      Kernel.stubs(:exec).with(
          {},
          "/usr/bin/quota"
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = "quota"
      OpenShift::Application::TrapUser.new.apply
    end
  end
end
