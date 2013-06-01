#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
require_relative '../test_helper'
require_relative '../../misc/bin/oo-trap-user'
require 'base64'

module OpenShift
  class TrapUserFunctionalTest < OpenShift::NodeTestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      skip "Support for ruby oo-trap-user pushed to post Summit 2013"

      @uuid        = 'a62d6dd9e6cd4be6841bedb5750a01fb'
      @gear_dir    = File.join('/tmp', @uuid)
      @runtime_dir = File.join(@gear_dir, 'app-root', 'runtime')
      @logs_dir    = File.join(@gear_dir, 'app-root', 'logs')


      @env = Utils::Environ.load('/etc/openshift/env')
      FileUtils.mkpath(@runtime_dir)
      FileUtils.mkpath(@logs_dir)

      OpenShift::Utils::SELinux.stubs(:get_mcs_label).with(0).returns('s0-s0:c0.c1023')
      OpenShift::Utils::SELinux.stubs(:getcon).returns('unconfined_u:system_r:openshift_t:s0-s0:c0.c1023')

      ## default env from /etc/openshift/env
      #@env = {'OPENSHIFT_CLOUD_DOMAIN'       => @env['OPENSHIFT_CLOUD_DOMAIN'],
      #        'OPENSHIFT_BROKER_HOST'        => @env['OPENSHIFT_BROKER_HOST'],
      #        'OPENSHIFT_CARTRIDGE_SDK_BASH' => @env['OPENSHIFT_CARTRIDGE_SDK_BASH'],
      #        'OPENSHIFT_CARTRIDGE_SDK_RUBY' => @env['OPENSHIFT_CARTRIDGE_SDK_RUBY'],
      #        'PATH'                         => @env['PATH'],
      #}
    end

    # Called after every test method runs. Can be used to tear
    # down fixture information.

    def teardown
      FileUtils.rm_rf(File.join('/tmp', @uuid))
    end

    def skip_unknown
      ENV['SSH_ORIGINAL_COMMAND'] = 'unknown'

      Kernel.stubs(:exec).with(@env, '/bin/bash', '-c', 'unknown').returns(0)
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_rhcsh
      # env['PS1'] = 'rhcsh> '
      Kernel.stubs(:exec).with(@env.merge({'PS1' => 'rhcsh> '}),
                               '/bin/bash', '--init-file', '/usr/bin/rhcsh', '-i'
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'rhcsh'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_rhcsh_argvs
      # env['PS1'] = 'rhcsh> '
      Kernel.stubs(:exec).with(@env.merge({'PS1' => 'rhcsh> '}),
                               '/bin/bash', '--init-file', '/usr/bin/rhcsh', '-c', 'ls', '/tmp'
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'rhcsh ls /tmp'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_ctl_all
      Kernel.stubs(:exec).with(@env,
                               '/bin/bash', '-c', '. /usr/bin/rhcsh > /dev/null ; ctl_all start app001'
      ).returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'ctl_all start app001'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_snapshot
      Kernel.stubs(:exec).with(@env, '/bin/bash', 'oo-snapshot').returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'snapshot'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_restore
      Kernel.stubs(:exec).with(@env, '/bin/bash', 'oo-restore').returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'restore'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_restore_include_git
      Kernel.stubs(:exec).with(@env, '/bin/bash', 'oo-restore', 'INCLUDE_GIT').returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'restore INCLUDE_GIT'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_cd
      Kernel.stubs(:exec).with(@env, '/bin/bash', '-c', 'cd', '/tmp').returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'cd /tmp'
      OpenShift::Application::TrapUser.new.apply
    end

    def skip_tail
      `echo Hello, World > #@logs_dir/mock.log`
      tail_opts = Base64.encode64('-n 100')
      Kernel.stubs(:exec).with(@env, '/usr/bin/tail', '-f', '-n', '100', 'app-root/logs/mock.log').returns(0)

      Dir.chdir(@gear_dir) do
        ENV['SSH_ORIGINAL_COMMAND'] = "tail --opts #{tail_opts} app-root/logs/mock.log"
        OpenShift::Application::TrapUser.new.apply
      end
    end

    def skip_tail_with_follow
      `echo Hello, World > #@logs_dir/mock.log`
      tail_opts = Base64.encode64('-n 100 -f')
      Kernel.stubs(:exec).with(@env, '/usr/bin/tail', '-n', '100', '-f', 'app-root/logs/mock.log').returns(0)

      Dir.chdir(@gear_dir) do
        ENV['SSH_ORIGINAL_COMMAND'] = "tail --opts #{tail_opts} app-root/logs/mock.log"
        OpenShift::Application::TrapUser.new.apply
      end
    end

    def skip_git_receive_pack
      home_dir      = File.join('/tmp', Process.pid.to_s)
      git_directory = File.join(home_dir, 'git')
      FileUtils.mkpath(git_directory)

      config = mock('OpenShift::Config')
      config.stubs(:get).returns(nil)
      config.stubs(:get).with('GEAR_BASE_DIR').returns('/tmp')
      OpenShift::Config.stubs(:new).returns(config)

      old_home_dir = ENV['HOME']
      ENV['HOME']  = home_dir
      begin
        Kernel.stubs(:exec).with(@env, '/usr/bin/git-receive-pack', '~/git').returns(0)

        ENV['SSH_ORIGINAL_COMMAND'] = 'git-receive-pack ~/git'
        OpenShift::Application::TrapUser.new.apply
      ensure
        FileUtils.rm_rf(home_dir)
        ENV['HOME'] = old_home_dir
      end
    end

    def skip_quota
      Kernel.stubs(:exec).with(@env, '/usr/bin/quota', '--always-resolve').returns(0)

      ENV['SSH_ORIGINAL_COMMAND'] = 'quota'
      OpenShift::Application::TrapUser.new.apply
    end
  end
end
