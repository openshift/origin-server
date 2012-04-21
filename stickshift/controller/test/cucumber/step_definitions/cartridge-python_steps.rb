# Controller cartridge command paths
$cartridge_root ||= "/usr/libexec/stickshift/cartridges"
$python_cartridge = "#{$cartridge_root}/python-2.6"
$python_common_conf_path = "#{$python_cartridge}/info/configuration/etc/conf/httpd_nolog.conf"
$python_hooks = "#{$python_cartridge}/info/hooks"
$python_config_path = "#{$python_hooks}/configure"
# app_name namespace acct_name
$python_config_format = "#{$python_config_path} '%s' '%s' '%s'"
$python_deconfig_path = "#{$python_hooks}/deconfigure"
$python_deconfig_format = "#{$python_deconfig_path} '%s' '%s' '%s'"

$python_start_path = "#{$python_hooks}/start"
$python_start_format = "#{$python_start_path} '%s' '%s' '%s'"

$python_stop_path = "#{$python_hooks}/stop"
$python_stop_format = "#{$python_stop_path} '%s' '%s' '%s'"

$python_status_path = "#{$python_hooks}/status"
$python_status_format = "#{$python_status_path} '%s' '%s' '%s'"

$libra_httpd_conf_d ||= "/etc/httpd/conf.d/stickshift"

When /^I configure a python application$/ do
  account_name = @account['accountname']
  namespace = "ns1"
  app_name = "app1"
  @app = {
    'name' => app_name,
    'namespace' => namespace
  }
  command = $python_config_format % [app_name, namespace, account_name]
  runcon command,  $selinux_user, $selinux_role, $selinux_type
end

Then /^a python application http proxy file will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  app_name = @app['name']
  namespace = @app['namespace']

  conf_file_name = "#{acct_name}_#{namespace}_#{app_name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  if not negate
    File.exists?(conf_file_path).should be_true
  else
    File.exists?(conf_file_path).should be_false
  end
end

Then /^a python application git repo will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  app_name = @app['name']

  git_repo = "#{$home_root}/#{acct_name}/git/#{app_name}.git"
  status = (File.exists? git_repo and File.directory? git_repo)
  # TODO - need to check permissions and SELinux labels

  if not negate
    status.should be_true
  else
    status.should be_false
  end

end

Then /^a python application source tree will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  app_name = @app['name']

  app_root = "#{$home_root}/#{acct_name}/#{app_name}"
  status = (File.exists? app_root and File.directory? app_root) 
  # TODO - need to check permissions and SELinux labels

  if not negate
    status.should be_true
  else
    status.should be_false
  end

end

Then /^a python application httpd will( not)? be running$/ do | negate |
  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 7
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_httpds = num_procs acct_name, 'httpd'
  while (not exit_test.call(num_httpds) and tries < max_tries)
    tries += 1
    sleep poll_rate
    found = exit_test.call num_httpds
  end

  if not negate
    num_httpds.should be > 0
  else
    num_httpds.should be == 0
  end
end

Then /^python application log files will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']
  log_dir_path = "#{$home_root}/#{acct_name}/#{app_name}/logs"
  begin
    log_dir = Dir.new log_dir_path
    status = (log_dir.count > 2)
  rescue
    status = false
  end

  if not negate
    status.should be_true
  else
    status.should be_false
  end

end

Given /^a new python application$/ do
  account_name = @account['accountname']
  app_name = 'app1'
  namespace = 'ns1'
  @app = {
    'namespace' => namespace,
    'name' => app_name
  }
  command = $python_config_format % [app_name, namespace, account_name]
  runcon command, $selinux_user, $selinux_role, $selinux_type
end

When /^I deconfigure the python application$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $python_deconfig_format % [app_name, namespace, account_name]
  runcon command,  $selinux_user, $selinux_role, $selinux_type
end

Given /^the python application is (running|stopped)$/ do | start_state |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  case start_state
  when 'running':
      fix_action = 'start'
      good_exit = 0
  when 'stopped':
      fix_action = 'stop'
      good_exit = 0
  end

  # check
  status_command = $python_status_format %  [app_name, namespace, account_name]
  exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type

  if exit_status != good_exit
    # fix it
    fix_command = "#{$python_hooks}/%s %s %s %s" % [fix_action, app_name, namespace, account_name]
    exit_status = runcon fix_command, $selinux_user, $selinux_role, $selinux_type
    if exit_status != 0
      raise "Unable to %s for %s %s %s" % [fix_action, app_name, namespace, account_name]
    end
    sleep 5
    
    # check exit status
    exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type
    if exit_status != good_exit
      raise "Received bad status after %s for %s %s %s" % [fix_action, app_name, namespace, account_name]
    end
  end
  # check again
end

When /^I (start|stop) the python application$/ do |action|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$python_hooks}/%s %s %s %s" % [action, app_name, namespace, account_name]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
  if exit_status != 0
    raise "Unable to %s for %s %s %s" % [action, app_name, namespace, account_name]
  end
  sleep 5
end

Then /^the python application will( not)? be running$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  good_status = negate ? 0 : 0

  command = "#{$python_hooks}/status %s %s %s" % [app_name, namespace, account_name]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
  exit_status.should == good_status
end
