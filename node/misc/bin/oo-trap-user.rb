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

require 'rubygems'
require 'etc'
require 'base64'
require 'syslog'
require 'openshift-origin-common'
require 'openshift-origin-node/utils/environ'

module OpenShift
  module Application
    class TrapUser
      CGROUPS_CONTROLLERS = "cpu,cpuacct,memory,net_cls,freezer"
      CGROUPS_PATH_PREFIX = "/openshift/"

      def initialize
        Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_USER) unless Syslog.opened?

        @commands_map = {
            "git-receive-pack" => "/usr/bin/git-receive-pack",
            "git-upload-pack"  => "/usr/bin/git-upload-pack",
            "snapshot"         => "/bin/bash",
            "restore"          => "/bin/bash",
            "tail"             => "/usr/bin/tail",
            "rhcsh"            => "/bin/bash",
            "true"             => "/bin/true",
            "java"             => "/bin/bash",
            "scp"              => "/bin/bash",
            "cd"               => "/bin/bash",
            "set"              => "/bin/bash",
            "mkdir"            => "/bin/bash",
            "test"             => "/bin/bash",
            "rsync"            => "/bin/bash",
            "ctl_all"          => "/bin/bash",
            "deploy.sh"        => "/bin/bash",
            "rhc-list-ports"   => "/bin/bash",
            "post_deploy.sh"   => "/bin/bash",
            "quota"            => "/usr/bin/quota",
        }
      end

      # join current process to openshift cgoups if possible
      #
      # cgclassify -g cpu,cpuacct,memory,net_cls,freezer:/openshift/510fe9db6b61de4618000005 30608
      def join_cgroups
        name          = Etc.getpwuid(Process.uid).name
        pid           = Process.spawn("cgclassify", "-g", "#{CGROUPS_CONTROLLERS}:#{CGROUPS_PATH_PREFIX}/#{name} #{Process.pid}")
        _, exitstatus = Process.wait2(pid)
        Syslog.warning("user #{name}: cgroup classification failed: exitstatus = #{exitstatus}") if 0 != exitstatus
      end

      def apply
        join_cgroups

        config       = OpenShift::Config.new
        env          = OpenShift::Utils::Environ.for_gear("~")
        command_line = ENV['SSH_ORIGINAL_COMMAND'] || "rhcsh"
        Syslog.info(command_line)

        orig_argv    = command_line.split(' ')
        orig_command = orig_argv.shift

        canon_command = @commands_map[orig_command]
        canon_argv    = []
        case orig_command
          # rhc snapshot...
          when "snapshot"
            canon_argv.push('snapshot.sh')

          # rhc restore...
          when "restore"
            canon_argv.push('restore.sh')
            canon_argv.push('INCLUDE_GIT') if orig_argv.first == 'INCLUDE_GIT'

          # ssh {uuid}@{...}
          when "rhcsh"
            env['PS1'] = 'rhcsh> '
            canon_argv.concat %w(--init-file /usr/bin/rhcsh)
            if orig_argv.empty?
              canon_argv.push("-i")
            else
              canon_argv.push("-c")
              canon_argv.concat(orig_argv)
            end

          # ssh {uuid}@{...} ctl_all start app
          when 'ctl_all'
            canon_argv.push('-c')
            canon_argv.push(". /usr/bin/rhcsh > /dev/null ; ctl_all #{orig_argv.join(' ')}")

          #  ssh {uuid}@{...}...
          when 'java', 'set', 'scp', 'cd', 'test', 'mkdir', 'rsync', 'deploy.sh', 'post_deploy.sh', 'rhc-list-ports'
            canon_argv.push('-c')
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
                  print "All paths must be relative: " + arg
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
                    print "invalid character"
                    return 91
                  elsif File.symlink?(f)
                    print "links not supported"
                    return 94
                  elsif File.stat(f).uid != Process::UID.eid
                    print "not your file"
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
              print "Could not files any files matching glob"
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
            # defaults are good

          else
            # Catch all, just run the command as-is via bash.
            canon_command = "/bin/bash"
            canon_argv.push('-c')
            canon_argv.push(orig_command)
            canon_argv.concat(orig_argv)
        end

# FIXME: need libselinux-ruby for Ruby 1.9.3
#
# msc_level = OpenShift::UnixUser.get_mcs_label(Process::UID)
# target_context = "unconfined_u:system_r:openshift_t:#{msc_level}"
# actual_context = selinux.getcon() <- This is what we need
# if target_context != actual_context
#    runcon = '/usr/bin/runcon'
#    $stderr.puts "Invalid context"
#    sys.exit(40)
# This else is left in because at the time of writing this statement
# We have a patched pam 'openshift' module running.  Remove the exit above and it should
# work on other platforms.
# os.execv(runcon, [runcon, target_context, cmd] + allargs)
# exit(1)
# else

#puts "env: #{env} #{canon_command} #{canon_argv.inspect}"
        Kernel.exec(env, canon_command, *canon_argv)
        return 1
      end
    end
  end
end


if __FILE__ == $0
  exit_status = OpenShift::Application::TrapUser.new.apply

  # Will only reach here if exec fails
  exit exit_status
end
