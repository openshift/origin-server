#!/usr/bin/env oo-ruby
#--
# Copyright 2012-2013 Red Hat, Inc.
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

require 'etc'
require 'base64'
require 'syslog'
require 'openshift-origin-common/config'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/utils/selinux'
require 'pathname'

module OpenShift
  module Runtime
    class TrapUser

      def initialize
        Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_USER) unless Syslog.opened?

        @commands_map = {
            'git-receive-pack' => '/usr/bin/git-receive-pack',
            'git-upload-pack'  => '/usr/bin/git-upload-pack',
            'snapshot'         => :bash,
            'restore'          => :bash,
            'tail'             => '/usr/bin/tail',
            'rhcsh'            => :bash,
            'true'             => '/bin/true',
            'java'             => :bash,
            'scp'              => :bash,
            'cd'               => :bash,
            'set'              => :bash,
            'mkdir'            => :bash,
            'test'             => :bash,
            'rsync'            => :bash,
            'ctl_all'          => :bash,
            'deploy.sh'        => :bash,
            'rhc-list-ports'   => :bash,
            'post_deploy.sh'   => :bash,
            'quota'            => '/usr/bin/quota',
        }
      end

      def apply
        env          = OpenShift::Runtime::Utils::Environ.for_gear(ENV['HOME'])
        command_line = ENV['SSH_ORIGINAL_COMMAND'] || 'rhcsh'
        Syslog.info("#{ENV['OPENSHIFT_GEAR_UUID']}: rhcsh original command #{command_line}")

        orig_argv    = command_line.split(' ')
        orig_command = orig_argv.shift

        canon_command = @commands_map[orig_command]
        canon_argv    = []
        case orig_command
          # rhc snapshot...
          when 'snapshot'
            canon_argv.push('oo-snapshot')

          # rhc restore...
          when 'restore'
            canon_argv.push('oo-restore')
            canon_argv.push('INCLUDE_GIT') if orig_argv.first == 'INCLUDE_GIT'

          # ssh {uuid}@{...}
          when 'rhcsh'
            env['PS1']    = 'rhcsh> '
            canon_command = '/bin/bash'
            canon_argv.concat %w(--init-file /usr/bin/rhcsh)
            if orig_argv.empty?
              canon.argv.push '-i'
            else
              canon.argv.push '-c'
              canon_argv.concat orig_argv
            end

          # ssh {uuid}@{...} ctl_all start app
          when 'ctl_all'
            canon_argv.push(%Q(. /usr/bin/rhcsh > /dev/null ; ctl_all #{orig_argv.join(' ')}))

          #  ssh {uuid}@{...}...
          when 'java', 'set', 'scp', 'cd', 'test', 'mkdir', 'rsync', 'deploy.sh', 'post_deploy.sh', 'rhc-list-ports'
            canon_argv.push(orig_command)
            canon_argv.concat(orig_argv)

          #  rhc tail...
          when 'tail'
            canon_argv.push('-f')

            files_start_index = 0
            args              = []
            files             = []

            if orig_argv.first == '--opts'
              files_start_index = 2
              args_str          = Base64.decode64(orig_argv[1])
              args              = args_str.split()
              args.each do |arg|
                if arg.start_with?('..') || arg.start_with?('/')
                  print "All paths must be relative: #{arg}"
                  return 88
                elsif arg == '-f' or arg == '-F' or arg.start_with?('--follow')
                  canon_argv.delete('-f')
                end
              end
            end

            orig_argv[files_start_index..-1].each do |glob_list|
              Dir.glob(glob_list).each do |f|
                begin
                  # fail if '..' found in filename or starts with '/'
                  if !f[".."].nil? or f.start_with?("/")
                    print 'invalid character'
                    return 91
                  elsif File.symlink?(f)
                    print 'links not supported'
                    return 94
                  elsif File.stat(f).uid != Process::UID.eid
                    print 'not your file'
                    return 87
                  else
                    files.push(f)
                  end
                rescue SystemExit
                  raise
                rescue Exception => e
                  print "Error #{e.message}"
                  return 91
                end
              end
            end

            if files.length == 0
              print 'Could not files any files matching glob'
              return 32
            end

            canon_argv.concat(args)
            canon_argv.concat(files)

          when 'git-receive-pack', 'git-upload-pack'
            # git repositories need to be parsed specially
            git_argv = orig_argv.join(' ')
            git_argv.gsub!("'", "") if git_argv[0] == "'" and git_argv[-1] == "'"

            git_argv.gsub!("\\'", "")
            git_argv.gsub!("//", "/")

            config   = OpenShift::Config.new

            # replace leading tilde (~) with user's home path
            realpath = File.expand_path(git_argv)
            unless realpath.start_with?(config.get('GEAR_BASE_DIR'))
              Syslog.warning("Invalid repository: not in GEAR_BASE_DIR - #{config.get('GEAR_BASE_DIR')}: (#{realpath}) not in gear dir")
              $stderr.puts("Invalid repository #{git_argv}: not in gear dir")
              exit 3
            end

            unless File.directory?(realpath)
              Syslog.warning("Invalid repository #{git_argv} (#{realpath}) not a directory")
              $stderr.puts("Invalid repository #{git_argv}: not a directory")
              exit 3
            end

            canon_argv.push(git_argv)

          when 'quota'
            canon_argv.push('--always-resolve')

          else
            # Catch all, just run the command as-is via bash.
            canon_command = :bash
            canon_argv.push(orig_command)
            canon_argv.concat(orig_argv)
        end

        mcs_label      = OpenShift::Runtime::Utils::SELinux.get_mcs_label(Process.uid)
        target_context = OpenShift::Runtime::Utils::SELinux.context_from_defaults(mcs_label)
        actual_context = OpenShift::Runtime::Utils::SELinux.getcon

        if target_context != actual_context
          $stderr.puts "Invalid context: #{actual_context}, expected #{target_context}"
          return 40
          # This path is left in because at the time of writing this statement
          # We have a patched ssh running.  Remove the return above and it should
          # work on other platforms.
          canon_argv.unshift(target_context, canon_command)
          Kernel.exec(env, '/usr/bin/runcon', *canon_argv)
          return 1
        end

        if :bash == canon_command
          Syslog.info("#{ENV['OPENSHIFT_GEAR_UUID']}: rhcsh cooked command = /bin/bash -c #{canon_argv.join(' ')}")
          Kernel.exec(env, '/bin/bash', '-c', canon_argv.join(' '))
        else
          Syslog.info("#{ENV['OPENSHIFT_GEAR_UUID']}: rhcsh cooked command = #{canon_command}, #{canon_argv.join(',')}")
          Kernel.exec(env, canon_command, *canon_argv)
        end
        return 1
      end
    end
  end
end


if __FILE__ == $0
  exit_status = OpenShift::Runtime::TrapUser.new.apply

  # Will only reach here if exec fails
  exit exit_status
end
