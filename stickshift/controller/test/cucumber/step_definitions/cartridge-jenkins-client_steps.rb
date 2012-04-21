require 'fileutils'

$jenkins_client_version = "1.4"
$jenkins_client_cart_root = "/usr/libexec/stickshift/cartridges/embedded/jenkins-client-#{$jenkins_client_version}"
$jenkins_client_hooks = $jenkins_client_cart_root + "/info/hooks"
$jenkins_client_config = $jenkins_client_hooks + "/configure"
$jenkins_client_config_format = "#{$jenkins_client_config} %s %s %s"
$jenkins_client_deconfig = $jenkins_client_hooks + "/deconfigure"
$jenkins_client_deconfig_format = "#{$jenkins_client_deconfig} %s %s %s"



When /^I try to configure jenkins-client it will fail$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $jenkins_client_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code == 0
    raise "Command didn't fail #{command}: returned #{exit_code}"
  end
end

Given /^a new jenkins-client$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $jenkins_client_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

When /^I configure jenkins-client$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $jenkins_client_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

When /^I deconfigure jenkins-client$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $jenkins_client_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the jenkins-client directory will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  jenkins_client_user_root = "#{$home_root}/#{account_name}/jenkins-client-#{$jenkins_client_version}"
  begin
    jenkins_client_dir = Dir.new jenkins_client_user_root
  rescue Errno::ENOENT
    jenkins_client_dir = nil
  end

  unless negate
    jenkins_client_dir.should be_a(Dir)
  else
    jenkins_client_dir.should be_nil
  end
end