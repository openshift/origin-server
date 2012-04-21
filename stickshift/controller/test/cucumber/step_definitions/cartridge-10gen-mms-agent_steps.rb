require 'fileutils'

$mms_agent_version = "0.1"
$mms_agent_cart_root = "/usr/libexec/stickshift/cartridges/embedded/10gen-mms-agent-#{$mms_agent_version}"
$mms_agent_hooks = $mms_agent_cart_root + "/info/hooks"
$mms_agent_config = $mms_agent_hooks + "/configure"
$mms_agent_config_format = "#{$mms_agent_config} %s %s %s"
$mms_agent_deconfig = $mms_agent_hooks + "/deconfigure"
$mms_agent_deconfig_format = "#{$mms_agent_deconfig} %s %s %s"

Given /^a new 10gen-mms-agent$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mms_agent_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

Given /^a settings.py file exists$/ do
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  system("mkdir -p /var/lib/stickshift/#{acct_name}/#{app_name}/repo/.openshift/mms > /dev/null")
  system("cp /usr/local/share/mms-agent/settings.py /var/lib/stickshift/#{acct_name}/#{app_name}/repo/.openshift/mms/settings.py > /dev/null")
  system("chown -R #{acct_name}:#{acct_name} /var/lib/stickshift/#{acct_name}/#{app_name}/repo/.openshift/mms/")

  filepath = "/var/lib/stickshift/#{acct_name}/#{app_name}/repo/.openshift/mms/settings.py"
  settingsfile = File.new filepath
  settingsfile.should be_a(File)
end

Given /^10gen-mms-agent is (running|stopped)$/ do | status |
  action = status == "running" ? "start" : "stop"

  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$mms_agent_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"

  agent_process_exists = system("ps -ef | grep #{acct_name}_agent.py | grep -qv grep > /dev/null 2>&1")
  outbuf = []

  case action
  when 'start'
    if ! agent_process_exists
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |tval| tval == true }
  when 'stop'
    if agent_process_exists
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |tval| tval == false }
  end

  # now loop a few times to give the process enough time to start
  max_tries = 5
  poll_rate = 1
  tries = 0
  while (not exit_test.call(agent_process_exists) and tries < max_tries)
    tries += 1
    sleep poll_rate
  end
  
  if not exit_test.call(system("ps -ef | grep #{acct_name}_agent.py | grep -qv grep > /dev/null 2>&1"))
    raise "Error: Failed to #{action} 10gen-mms-agent"
  end
end

When /^I configure 10gen-mms-agent$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mms_agent_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

When /^I deconfigure 10gen-mms-agent$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mms_agent_deconfig_format % [app_name, namespace, account_name]

  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

When /^I (start|stop|restart) 10gen-mms-agent$/ do |action|
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  outbuf = []
  command = "#{$mms_agent_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

Then /^the 10gen-mms-agent process will( not)? be running$/ do | negate |
  acct_name = @account['accountname']
  app_name = @app['name']
  namespace = @app['namespace']

  if not negate
    system("ps -ef | grep #{acct_name}_agent.py | grep -qv grep").should be_true
  else
    system("ps -ef | grep #{acct_name}_agent.py | grep -qv grep").should be_false
  end
end

Then /^the 10gen-mms-agent source directory will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mms_agent_dir_path = "#{$home_root}/#{account_name}/10gen-mms-agent-#{$mms_agent_version}/mms-agent"
  begin
    mms_agent_dir = Dir.new mms_agent_dir_path
  rescue Errno::ENOENT
    mms_agent_dir = nil
  end

  unless negate
    mms_agent_dir.should be_a(Dir)
  else
    mms_agent_dir.should be_nil
  end
end

Then /^the 10gen-mms-agent log directory will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']
  
  log_dir_path = "#{$home_root}/#{acct_name}/10gen-mms-agent-#{$mms_agent_version}/logs"
  begin
    log_dir = Dir.new log_dir_path
  rescue
    log_dir = nil
  end

  if not negate
    log_dir.should be_a(Dir)
  else
    log_dir.should be_nil
  end
end

Then /^the 10gen-mms-agent control script will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mms_agent_user_root = "#{$home_root}/#{account_name}/10gen-mms-agent-#{$mms_agent_version}"
  mms_agent_control_file = "#{mms_agent_user_root}/#{app_name}_10gen_mms_agent_ctl.sh"

  begin
    controlfile = File.new mms_agent_control_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    controlfile.should be_a(File)
  else
    controlfile.should be_nil
  end
end

Then /^the 10gen-mms-agent pid file will exist$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mms_agent_pid_file = "#{$home_root}/#{account_name}/10gen-mms-agent-#{$mms_agent_version}/run/mms-agent.pid"

  begin
    pidfile = File.new mms_agent_pid_file
  rescue Errno::ENOENT
    pidfile = nil
  end

  pidfile.should be_a(File)
end