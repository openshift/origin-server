#!/usr/bin/env oo-ruby

require 'rubygems'
require 'base64'
require 'syslog'
require 'openshift-origin-common'
require 'openshift-origin-node/utils/environ'

module OpenShift
  module Application
    class TrapUser

      def initialize
        @commands_map = {
            "cd"               => "/bin/bash",
            "ctl_all"          => "/bin/bash",
            "deploy.sh"        => "/bin/bash",
            "git-receive-pack" => "/usr/bin/git-receive-pack",
            "git-upload-pack"  => "/usr/bin/git-upload-pack",
            "java"             => "/bin/bash",
            "mkdir"            => "/bin/bash",
            "post_deploy.sh"   => "/bin/bash",
            "restore"          => "/bin/bash",
            "rhc-list-ports"   => "/bin/bash",
            "rhcsh"            => "/bin/bash",
            "rsync"            => "/bin/bash",
            "scp"              => "/bin/bash",
            "set"              => "/bin/bash",
            "snapshot"         => "/bin/bash",
            "tail"             => "/usr/bin/tail",
            "test"             => "/bin/bash",
            "true"             => "/bin/true",
        }
      end

      def apply
        Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_USER) unless Syslog.opened?

        env      = OpenShift::Utils::Environ.for_gear("~")
        orig_cmd = ENV['SSH_ORIGINAL_COMMAND'] || "rhcsh"
        Syslog.info(orig_cmd)

        config = OpenShift::Config.new

        allargs = orig_cmd.split(' ')
        basecmd = allargs[0]
        cmd     = @commands_map[basecmd]
        if cmd.nil?
          Syslog.err("Invalid command #{orig_cmd}")
          $stderr.puts("Invalid command #{orig_cmd}")
          return 2
        end

        case basecmd
          when "snapshot" # This gets called with "snapshot"
            allargs = ['snapshot.sh']

          when "restore" # This gets called with "restore <INCLUDE_GIT>"
            include_git = false
            if allargs.length > 1 and allargs[1] == 'INCLUDE_GIT'
              include_git = true
            end
            allargs = ['restore.sh']
            allargs.push('INCLUDE_GIT') if include_git

          when "rhcsh"
            env["PS1"] = "rhcsh> "
            if allargs.length < 2
              allargs = ['--init-file', '/usr/bin/rhcsh', '-i']
            else
              str     = allargs[1..-1].join(' ')
              allargs = ['--init-file', '/usr/bin/rhcsh', '-c', str]
            end

          when 'ctl_all'
            allargs = ['-c', ". /usr/bin/rhcsh > /dev/null ; ctl_all #{allargs[-1]}"]

          when 'java', 'set', 'scp', 'cd', 'test', 'mkdir', 'rsync', 'deploy.sh', 'post_deploy.sh', 'rhc-list-ports'
            str     = allargs.join(' ')
            allargs = ['-c', str]

          when 'tail'
            files = []

            files_start_index = 1
            args              = []
            add_follow        = true

            if allargs[1] == '--opts'
              files_start_index = 3
              args_str          = Base64.decode64(allargs[2])
              args              = args_str.split()
              args.each do |arg|
                if arg.start_with?('..') || arg.start_with?('/')
                  print "All paths must be relative: " + arg
                  return 88
                elsif arg == '-f' or arg == '-F' or arg.start_with?('--follow')
                  add_follow = false
                end
              end
            end

            allargs[files_start_index..-1].each do |glob_list|
              Dir.glob(glob_list).each do |f|
                begin
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

            allargs = Array.new(args)
            allargs.push('-f') if add_follow
            allargs += files
          when 'git-receive-pack', 'git-upload-pack'
            thearg = allargs[1..-1].join(' ')
            if thearg[0] == "'" and thearg[-1] == "'"
              thearg.gsub!("'", "")
              thearg.gsub!("\\'", "")
              thearg.gsub!("//", "/")

              # replace leading tilde (~) with user's home path
              realpath = File.absolute_path(thearg)
              unless realpath.start_with?(config.get('GEAR_BASE_DIR'))
                Syslog.alert("Invalid repository: not in GEAR_BASE_DIR - #{thearg}: (#{realpath}) not in gear dir")
                $stderr.puts("Invalid repository #{thearg}: not in gear dir")
                exit 3
              end

              unless File.directory?(realpath)
                Syslog.alert("Invalid repository #{thearg} (#{realpath}) not a directory")
                $stderr.puts("Invalid repository #{thearg}: not a directory")
                exit(3)
              end
              allargs = [thearg]
            end
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

        Kernel.exec(env, cmd, [cmd] + allargs)
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