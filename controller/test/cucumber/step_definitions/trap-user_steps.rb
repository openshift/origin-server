require 'pty'
require 'digest/md5'

def ssh_command(command) 
  "ssh 2>/dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -tt #{@gear.uuid}@#{@app.name}-#{@account.domain}.#{$cloud_domain} " + command
end

Then /^I can run "([^\"]*)" with exit code: (\d+)$/ do |cmd, code|
  command = ssh_command("rhcsh #{cmd}")
  
  $logger.debug "Running #{command}"

  output = `#{command}`

  $logger.debug "Output: #{output}"

  assert_equal code.to_i, $?.exitstatus  
end

When /^I tail the logs via ssh$/ do
  ssh_cmd = ssh_command("tail -f */logs/\\*")
  stdout, stdin, pid = PTY.spawn ssh_cmd

  @ssh_cmd = {
    :pid => pid,
    :stdin => stdin,
    :stdout => stdout,
  }
end

When /^I stop tailing the logs$/ do
  begin
    Process.kill('KILL', @ssh_cmd[:pid])
    exit_code = -1

    # Don't let a command run more than 1 minute
    Timeout::timeout(60) do
      ignored, status = Process::waitpid2 @ssh_cmd[:pid]
      exit_code = status.exitstatus
    end
  rescue PTY::ChildExited
    # Completed as expected
  end
end

Then /^I can obtain disk quota information via SSH$/ do
  cmd = ssh_command('/usr/bin/quota')

  $logger.debug "Running: #{cmd}"

  out = `#{cmd}`

  $logger.debug "Output: #{out}"

  if out.index("Disk quotas for user ").nil?
    raise "Could not obtain disk quota information"
  end  
end
