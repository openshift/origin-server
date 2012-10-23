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
require 'open4'

module OpenShift::Utils
  class ShellExecutionException < Exception
    attr_accessor :rc
    def initialize(msg, rc=-1)
      super msg
      self.rc = rc 
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
        Timeout::timeout(timeout) do
          out = stdout.read
          err = stderr.read
        end
      rescue Timeout::Error
        pstree = Hash.new{|a,b| a[b]=[b]}
        pppids = Hash[*`ps -e -opid,ppid --no-headers`.map{|p| p.to_i}]
        pppids.each do |l_pid, l_ppid|
          pstree[l_ppid] << pstree[l_pid]
        end
        Process.kill("KILL", *(pstree[pid].flatten))
        raise OpenShift::Utils::ShellExecutionException.new("command timed out")
      ensure
        stdout.close
        stderr.close  
        rc = Process::waitpid2(pid)[1].exitstatus
      end
    rescue Exception => e
      raise OpenShift::Utils::ShellExecutionException.new(e.message
                                                    ) unless ignore_err
    end

    if !ignore_err and rc != expected_rc 
      raise OpenShift::Utils::ShellExecutionException.new(
        "Shell command '#{cmd}' returned an error. rc=#{rc}", rc)
    end
    return [out, err, rc]
  end
end
