require 'etc'
$temp="/tmp/rhc/cartridge-php/"
# Controller cartridge command paths
$cartridge_root ||= "/usr/libexec/stickshift/cartridges"
$php_cartridge = "#{$cartridge_root}/php-5.3"
$php_common_conf_path = "#{$php_cartridge}/info/configuration/etc/conf/httpd_nolog.conf"
$php_hooks = "#{$php_cartridge}/info/hooks"
$php_config_path = "#{$php_hooks}/configure"
# app_name namespace acct_name
$php_config_format = "#{$php_config_path} '%s' '%s' '%s'"
$php_deconfig_path = "#{$php_hooks}/deconfigure"
$php_deconfig_format = "#{$php_deconfig_path} '%s' '%s' '%s'"

$php_start_path = "#{$php_hooks}/start"
$php_start_format = "#{$php_start_path} '%s' '%s' '%s'"

$php_stop_path = "#{$php_hooks}/stop"
$php_stop_format = "#{$php_stop_path} '%s' '%s' '%s'"

$php_status_path = "#{$php_hooks}/status"
$php_status_format = "#{$php_status_path} '%s' '%s' '%s'"

$libra_httpd_conf_d ||= "/etc/httpd/conf.d/stickshift"


When /^I configure a php application$/ do
  account_name = @account['accountname']
  namespace = @account['namespace']
  app_name = @account['appnames'][0]
  @app = {
    'name' => app_name,
    'namespace' => namespace
  }
  command = $php_config_format % [app_name, namespace, account_name]
  exitcode = runcon command,  $selinux_user, $selinux_role, $selinux_type, nil, 10
  raise "Non zero exit code: #{exitcode}" unless exitcode == 0
end

Then /^the file permissions are correct/ do
  gear_uuid = @account['accountname']
  app_home = "/var/lib/stickshift/#{gear_uuid}"
  uid = Etc.getpwnam(gear_uuid).uid
  gid = Etc.getpwnam(gear_uuid).gid
  mcs = libra_mcs_level(uid)
  # Configure files (relative to app_home)
  configure_files = { "#{@app['name']}" => ['root', 'root', '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                     "php-5.3/" => ['root', 'root', '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/#{@app['name']}_ctl.sh" => ['root', 'root', '100755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    ".pearrc" => ['root', 'root', '100644', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/conf/" => ['root', 'root', '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/conf/php.ini" => ['root', 'root', '100644', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/conf/magic" => ['root', 'root', '100644', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/conf.d/" => ['root', 'root', '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/conf.d/stickshift.conf" => ['root', 'root', '100644', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "app/data/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "#{@app['name']}/logs/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/phplib/pear/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "app/data/" => [gear_uuid, gear_uuid, '40750', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "app/repo/" => [gear_uuid, gear_uuid, '40750', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/run/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/run/httpd.pid" => [gear_uuid, gear_uuid, '100644', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "app/repo/php/index.php" => [gear_uuid, gear_uuid, '100664', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/sessions/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"],
                    "php-5.3/tmp/" => [gear_uuid, gear_uuid, '40755', "unconfined_u:object_r:libra_var_lib_t:#{mcs}"]
                    }
  configure_files.each do | file, permissions |
    raise "Invalid permissions for #{file}" unless mode?("#{app_home}/#{file}", permissions[2])
    raise "Invalid context for #{file}" unless context?("#{app_home}/#{file}", permissions[3])
    target_uid = Etc.getpwnam(permissions[0]).uid.to_i
    target_gid = Etc.getgrnam(permissions[1]).gid.to_i
    raise "Invalid ownership for #{file}" unless owner?("#{app_home}/#{file}", target_uid, target_gid)
  end
end

Then /^a php application http proxy file will( not)? exist$/ do | negate |
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

Then /^a php application git repo will( not)? exist$/ do | negate |
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

Then /^a php application source tree will( not)? exist$/ do | negate |
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

Then /^a php application httpd will( not)? be running$/ do | negate |
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

Then /^php application log files will( not)? exist$/ do | negate |
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

Given /^a new php application$/ do
  account_name = @account['accountname']
  app_name = @account['appnames'][0]
  namespace = @account['namespace']
  @app = {
    'namespace' => namespace,
    'name' => app_name
  }
  command = $php_config_format % [app_name, namespace, account_name]
  exitcode = runcon command,  $selinux_user, $selinux_role, $selinux_type, nil, 10
  raise "Non zero exit code: #{exitcode}" unless exitcode == 0

end

When /^I deconfigure the php application$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $php_deconfig_format % [app_name, namespace, account_name]
  exitcode = runcon command,  $selinux_user, $selinux_role, $selinux_type, nil, 15
  raise "Non zero exit code: #{exitcode}" unless exitcode == 0
end

Given /^the php application is (running|stopped)$/ do | start_state |
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
  status_command = $php_status_format %  [app_name, namespace, account_name]
  exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type, nil, 2

  if exit_status != good_exit
    # fix it
    fix_command = "#{$php_hooks}/%s %s %s %s" % [fix_action, app_name, namespace, account_name]
    exit_status = runcon fix_command, $selinux_user, $selinux_role, $selinux_type, nil, 2
    if exit_status != 0
      raise "Unable to %s for %s %s %s" % [fix_action, app_name, namespace, account_name]
    end
    sleep 5
    
    # check exit status
    exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type, nil, 2
    if exit_status != good_exit
      raise "Received bad status after %s for %s %s %s" % [fix_action, app_name, namespace, account_name]
    end
  end
  # check again
end

When /^I (add-alias|remove-alias) the php application$/ do |action|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  server_alias = "#{@app['name']}-#{@account['accountname']}.#{$alias_domain}"

  command = "#{$php_hooks}/%s %s %s %s %s" % [action, app_name, namespace, account_name, server_alias]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type, nil, 10
  if exit_status != 0
    raise "Unable to %s for %s %s %s %s" % [action, app_name, namespace, account_name, server_alias]
  end
end

When /^I (start|stop|status|restart) the php application$/ do |action|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$php_hooks}/%s %s %s %s" % [action, app_name, namespace, account_name]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type, nil, 10
  if exit_status != 0
    raise "Unable to %s for %s %s %s" % [action, app_name, namespace, account_name]
  end
end

Then /^the php application will( not)? be aliased$/ do | negate |
  good_status = negate ? 1 : 0

  command = "/usr/bin/curl -H 'Host: #{@app['name']}-#{@account['accountname']}.#{$alias_domain}' -s http://localhost/health_check.php | /bin/grep -q -e '^1$'"
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
  exit_status.should == good_status
end

Then /^the php application will( not)? be running$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  good_status = negate ? 0 : 0

  command = "#{$php_hooks}/status %s %s %s" % [app_name, namespace, account_name]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type, nil, 10
  exit_status.should == good_status
end
