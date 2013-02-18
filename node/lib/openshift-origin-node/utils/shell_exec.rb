#--
# Copyright 2010-2013 Red Hat, Inc.
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
require 'timeout'
require 'open4'

module OpenShift
  module Utils
    class ShellExecutionException < Exception
      attr_accessor :rc, :stdout, :stderr
      def initialize(msg, rc=-1, stdout = nil, stderr = nil)
        super msg
        self.rc = rc 
        self.stdout = stdout
        self.stderr = stderr
      end
    end

    # Exception used to signal command overran it's timeout in seconds
    class TimeoutExceeded < RuntimeError
      attr_reader :seconds

      # seconds - integer of maximum seconds to wait on command
      def initialize(seconds)
        super 'Timeout exceeded'
        @seconds = seconds
      end

      def to_s
        super + " duration of #@seconds seconds"
      end
    end

    # oo_spawn(command, [, options]) -> [stdout, stderr, exit status]
    #
    # spawn executes specified command and return its stdout, stderr and exit status.
    # Or, raise exceptions if certain conditions are not met.
    #
    # command: command line string which is passed to the standard shell
    #
    # options: hash
    #   :env: hash
    #     name => val : set the environment variable
    #     name => nil : unset the environment variable
    #   :unsetenv_others => true   : clear environment variables except specified by :env
    #   :chdir => path             : set current directory when running command
    #   :expected_exitstatus       : An Integer value for the expected return code of command
    #                              : If not set spawn() returns exitstatus from command otherwise
    #                              : raise an error if exitstatus is not expected_exitstatus
    #   :timeout                   : Maximum number of seconds to wait for command to finish. default: 3600
    #   :uid                       : fork and spawn command as given user, :expected_exitstatus is not supported.
    #   :gid                       : fork and spawn command as given user's group, defaults to uid
    def self.oo_spawn(command, options = {})
      opts                   = {}
      opts[:chdir]           = (options[:chdir] ||= '.')
      opts[:unsetenv_others] = options[:unsetenv_others] ||= false
      opts[:close_others]    = true
      options[:env]          ||= {}
      options[:gid]          ||= options[:uid]
      options[:timeout]      ||= 3600
      options[:buffer_size]  ||= 32768

      IO.pipe { |read_stderr, write_stderr|
        IO.pipe { |read_stdout, write_stdout|
          opts[:in]    = :close
          opts[:out]   = write_stdout
          opts[:err]   = write_stderr

          fork_pid = nil
          pid      = 0
          if options[:uid]
            mcs_level, _, _ = oo_spawn("/usr/bin/oo-get-mcs-level #{options[:uid]}",
                                    :expected_exitstatus => 0,
                                    :timeout             => 3600)
            cmd             = "/usr/bin/runcon -r system_r -t openshift_t -l #{mcs_level.chomp} #{command}"

            fork_pid = fork {
              Process::GID.change_privilege(options[:gid].to_i)
              Process::UID.change_privilege(options[:uid].to_i)
              pid = Kernel.spawn(options[:env], cmd, opts)
            }
          else
            pid = Kernel.spawn(options[:env], command, opts)
            unless pid
              raise OpenShift::Utils::ShellExecutionException.new(
                        "Shell command '#{command}' fork failed in spawn().")
            end
          end

          begin
            write_stdout.close
            write_stderr.close
            out, err  = read_results(read_stdout, read_stderr, options)
            _, status = Process.wait2 pid

            exit status.exitstatus if options[:uid] && fork_pid.nil?

            if (!options[:expected_exitstatus].nil?) && (status.exitstatus != options[:expected_exitstatus])
              raise OpenShift::Utils::ShellExecutionException.new(
                        "Shell command '#{command}' returned an error. rc=#{status.exitstatus}",
                        status.exitstatus, out, err)
            end

            return [out, err, status.exitstatus]
          rescue TimeoutExceeded => e
            ShellExec.kill_process_tree(pid)
            raise OpenShift::Utils::ShellExecutionException.new(
                      "Shell command '#{command}'' exceeded timeout of #{e.seconds}", -1, out, err)
          end
        }
      }
    end

    private
    # read_results(stdout pipe, stderr pipe, options) -> [*standard out, *standard error]
    #
    # read stdout and stderr from spawned command until timeout
    #
    # options: hash
    #   :timeout     => seconds to wait for command to finish. Default: 3600
    #   :buffer_size => how many bytes to read from pipe per iteration. Default: 32768
    def self.read_results(stdout, stderr, options)
      out                   = ''
      err                   = ''
      readers               = [stdout, stderr]

      begin
        Timeout::timeout(options[:timeout]) do
          while readers.any?
            ready = IO.select(readers, nil, nil, options[:timeout])
            raise TimeoutError if ready.nil?

            ready[0].each do |fd|
              buffer = (fd == stdout) ? out : err
              begin
                buffer << fd.readpartial(options[:buffer_size])
              rescue Errno::EAGAIN, Errno::EINTR
              rescue EOFError
                readers.delete(fd)
                fd.close
              end
            end
          end
          [out, err]
        end
      rescue Timeout::Error
        raise TimeoutExceeded, options[:timeout]
      end
    end
  end
end

module OpenShift::Utils
  module ShellExec
    def shellCmd(cmd, pwd = ".", ignore_err = true, expected_rc = 0, timeout = 3600)
      OpenShift::Utils::ShellExec.shellCmd(cmd, pwd, ignore_err, expected_rc, timeout)
    end

    # Public: Execute shell command.
    #
    # iv - A String value for the IV file.
    # cmd - A String value of the command to run.
    # pwd - A String value of target working directory.
    # ignore_err - A Boolean value to determine if errors should be ignored.
    # expected_rc - A Integer value for the expected return code of cmd.
    #
    # Examples
    #   OpenShift::Utils::ShellExec.shellCmd('ls /etc/passwd')
    #   # => ["/etc/passwd\n","", 0]
    #
    # Returns An Array with [stdout, stderr, return_code]
    def self.shellCmd(cmd, pwd = ".", ignore_err = true, expected_rc = 0, timeout = 3600)
      out = err = rc = nil         
      begin
        # Using Open4 spawn with cwd isn't thread safe
        m_cmd = "cd #{pwd} && ( #{cmd} )"
        pid, stdin, stdout, stderr = Open4.popen4ext(true, m_cmd)
        begin
          stdin.close
          out = err = ""
          fds = [ stdout, stderr ]
          buffs = { stdout.fileno => out, stderr.fileno => err }
          Timeout::timeout(timeout) do
            while not fds.empty?
              rs, ws, es = IO.select(fds, nil, nil)
              rs.each do |f|
                begin
                  buffs[f.fileno] << f.read_nonblock(4096)
                rescue IO::WaitReadable, IO::WaitWritable # Wait in next select
                rescue EOFError
                  fds.delete_if { |item| item.fileno == f.fileno }
                end
              end
            end
          end
        rescue Timeout::Error
          kill_process_tree(pid)
          raise ShellExecutionException.new(
                    "Shell command '#{cmd}'' timed out (timeout is #{timeout})", -1, out, err)
        ensure
          stdout.close
          stderr.close  
          rc = Process::waitpid2(pid)[1].exitstatus
        end
      rescue Exception => e
        raise OpenShift::Utils::ShellExecutionException.new(e.message, rc, out, err
                                                      ) unless ignore_err
      end

      if !ignore_err and rc != expected_rc 
        raise OpenShift::Utils::ShellExecutionException.new(
          "Shell command '#{cmd}' returned an error. rc=#{rc}", rc, out, err)
      end
      return [out, err, rc]
    end

    # kill_process_tree 2199 -> fixnum
    #
    # Given a pid find it and KILL it and all it's children
    def self.kill_process_tree(pid)
      ps_results = `ps -e -opid,ppid --no-headers`.split("\n")

      ps_tree = Hash.new {|h, k| h[k] = [k]}
      ps_results.each { |pair|
        p, pp = pair.split(' ')
        ps_tree[pp.to_i] << p.to_i
      }
      Process.kill("KILL", *(ps_tree[pid].flatten))
    end

    def self.run_as(uid, gid, cmd, pwd = ".", ignore_err = true, expected_rc = 0, timeout = 3600)
      mcs_level, err, rc = OpenShift::Utils::ShellExec.shellCmd("/usr/bin/oo-get-mcs-level #{uid}", pwd, true, 0, timeout)
      raise OpenShift::Utils::ShellExecutionException.new(
        "Shell command '#{cmd}' returned an error. rc=#{rc}. output=#{err}", rc, mcs_level, err) if 0 != rc

      command = "/usr/bin/runcon -r system_r -t openshift_t -l #{mcs_level.chomp} #{cmd}"
      pid = fork {
        Process::GID.change_privilege(gid.to_i)
        Process::UID.change_privilege(uid.to_i)
        out, err, rc = OpenShift::Utils::ShellExec.shellCmd(command, pwd, true, 0, timeout)
        exit $?.exitstatus
      }

      if pid
        Process.wait(pid)
        rc = $?.exitstatus
        if !ignore_err and rc != expected_rc
          raise OpenShift::Utils::ShellExecutionException.new(
            "Shell command '#{command}' returned an error. rc=#{rc}", rc)
        end
        return rc
      else
        raise OpenShift::Utils::ShellExecutionException.new(
          "Shell command '#{command}' fork failed in run_as().")
      end
    end
  end
end
