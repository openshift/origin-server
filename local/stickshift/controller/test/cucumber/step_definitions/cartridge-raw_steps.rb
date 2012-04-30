# Controller cartridge command paths
$cartridge_root ||= "/usr/libexec/stickshift/cartridges"
$raw_cartridge = "#{$cartridge_root}/diy-0.1"
$raw_hooks = "#{$raw_cartridge}/info/hooks"
$raw_config_path = "#{$raw_hooks}/configure"
# app_name namespace acct_name
$raw_config_format = "#{$raw_config_path} '%s' '%s' '%s'"
$raw_deconfig_path = "#{$raw_hooks}/deconfigure"
$raw_deconfig_format = "#{$raw_deconfig_path} '%s' '%s' '%s'"

$raw_start_path = "#{$raw_hooks}/start"
$raw_start_format = "#{$raw_start_path} '%s' '%s' '%s'"

$raw_stop_path = "#{$raw_hooks}/stop"
$raw_stop_format = "#{$raw_stop_path} '%s' '%s' '%s'"

$raw_status_path = "#{$raw_hooks}/status"
$raw_status_format = "#{$raw_status_path} '%s' '%s' '%s'"

$libra_httpd_conf_d ||= "/etc/httpd/conf.d/stickshift"

When /^I configure a raw application$/ do
  account_name = @account['accountname']
  namespace = "ns1"
  app_name = "app1"
  @app = {
    'name' => app_name,
    'namespace' => namespace
  }
  command = $raw_config_format % [app_name, namespace, account_name]
  runcon command,  $selinux_user, $selinux_role, $selinux_type
end

Then /^a raw application http proxy file will( not)? exist$/ do | negate |
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

Then /^a raw application git repo will( not)? exist$/ do | negate |
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

Then /^a raw application source tree will( not)? exist$/ do | negate |
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

Given /^a new raw application$/ do
  account_name = @account['accountname']
  app_name = 'app1'
  namespace = 'ns1'
  @app = {
    'namespace' => namespace,
    'name' => app_name
  }
  command = $raw_config_format % [app_name, namespace, account_name]
  runcon command, $selinux_user, $selinux_role, $selinux_type
end

When /^I deconfigure the raw application$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $raw_deconfig_format % [app_name, namespace, account_name]
  runcon command,  $selinux_user, $selinux_role, $selinux_type
end
