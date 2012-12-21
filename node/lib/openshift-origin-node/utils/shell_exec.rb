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

require 'rubygems'
require 'timeout'
require 'open4'

module OpenShift::Utils
  class ShellExecutionException < Exception
    attr_accessor :rc, :stdout, :stderr
    def initialize(msg, rc=-1, stdout = nil, stderr = nil)
      super msg
      self.rc = rc 
      self.stdout = stdout
      self.stderr = stderr
    end
  end
end

module OpenShift::Utils::ShellExec

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
        pstree = Hash.new{|a,b| a[b]=[b]}
        pppids = Hash[*`ps -e -opid,ppid --no-headers`.map{|p| p.to_i}]
        pppids.each do |l_pid, l_ppid|
          pstree[l_ppid] << pstree[l_pid]
        end
        Process.kill("KILL", *(pstree[pid].flatten))
        raise OpenShift::Utils::ShellExecutionException.new(
          "Shell command '#{cmd}'' timed out (timeout is #{timeout})", -1. out, err)
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
