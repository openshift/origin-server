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
require 'open3'

module StickShift::Utils
  class ShellExecutionException < Exception
    attr_accessor :rc
    def initialize(msg, rc=-1)
      super msg
      self.rc = rc 
    end
  end
end

module StickShift::Utils::ShellExec
  def shellCmd(cmd, pwd=".", ignore_err=true, expected_rc=0)
    StickShift::Utils::ShellExec.shellCmd(cmd, pwd, ignore_err, expected_rc)
  end
  
  def self.shellCmd(cmd, pwd=".", ignore_err=true, expected_rc=0)
    out = err = rc = nil         
    begin
      rc_file = "/var/tmp/#{Process.pid}.#{rand}"
      m_cmd = "cd #{pwd}; #{cmd}; echo $? > #{rc_file}"
      stdin, stdout, stderr = Open3.popen3(m_cmd){ |stdin,stdout,stderr,thr|
        stdin.close
        out = stdout.read
        err = stderr.read          
        stdout.close
        stderr.close  
      }
      f_rc_file = File.open(rc_file,"r")
      rc = f_rc_file.read.to_i
      f_rc_file.close
      `rm -f #{rc_file}`
    rescue Exception => e
      raise StickShift::Utils::ShellExecutionException.new(e.message) unless ignore_err
    end
    
    if !ignore_err and rc != expected_rc 
      raise StickShift::Utils::ShellExecutionException.new("Shell command '#{cmd}' returned an error. rc=#{rc}", rc)
    end
     
    return [out, err, rc]
  end
end