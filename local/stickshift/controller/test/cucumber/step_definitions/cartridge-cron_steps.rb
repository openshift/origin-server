require 'fileutils'

$cron_version = "1.4"
$cron_cart_root = "/usr/libexec/stickshift/cartridges/embedded/cron-#{$cron_version}"
$cron_hooks = $cron_cart_root + "/info/hooks"
$cron_config = $cron_hooks + "/configure"
$cron_config_format = "#{$cron_config} %s %s %s"
$cron_deconfig = $cron_hooks + "/deconfigure"
$cron_deconfig_format = "#{$cron_deconfig} %s %s %s"

Given /^a new cron$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $cron_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

Given /^cron is (running|stopped)$/ do | status |
  action = status == "running" ? "start" : "stop"

  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$cron_hooks}/#{action} #{app_name} #{namespace} #{account_name}"

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  outbuf = []

  case action
  when 'start'
    if marker_file.nil?
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |marker| marker.is_a? File }
  when 'stop'
    if marker_file.is_a? File
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |marker| marker == nil }
  # else
  #   raise an exception
  end

  # now loop until it's true
  max_tries = 10
  poll_rate = 3
  tries = 0

  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  while (not exit_test.call(marker_file) and tries < max_tries)
    tries += 1
    sleep poll_rate
    begin
      marker_file = File.new jobs_enabled_file
    rescue Errno::ENOENT
      marker_file = nil
    end
  end
end

When /^I configure cron$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $cron_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Error running #{command}: returned #{exit_code}"
  end
end

When /^I deconfigure cron$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $cron_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

When /^I (start|stop|restart) cron$/ do |action|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"

  outbuf = []
  command = "#{$cron_hooks}/#{action} #{app_name} #{namespace} #{account_name}"
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the cron directory will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  begin
    cron_dir = Dir.new cron_user_root
  rescue Errno::ENOENT
    cron_dir = nil
  end

  unless negate
    cron_dir.should be_a(Dir)
  else
    cron_dir.should be_nil
  end
end

Then /^the cron control script will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  cron_startup_file = "#{cron_user_root}/#{app_name}_cron_ctl.sh"

  begin
    startfile = File.new cron_startup_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    startfile.should be_a(File)
  else
    startfile.should be_nil
  end
end

Then /^the cron log directory will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  begin
    cron_log_dir = Dir.new "#{cron_user_root}/log"
  rescue Errno::ENOENT
    cron_dir = nil
  end

  unless negate
    cron_log_dir.should be_a(Dir)
  else
    cron_log_dir.should be_nil
  end
end


Then /^the cron run directory will( not)? exist$/ do | negate |
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  begin
    cron_run_dir = Dir.new "#{cron_user_root}/run"
  rescue Errno::ENOENT
    cron_run_dir = nil
  end

  unless negate
    cron_run_dir.should be_a(Dir)
  else
    cron_run_dir.should be_nil
  end
end


Then /^cron jobs will( not)? be enabled$/ do | negate |
  account_name = @account['accountname']

  cron_user_root = "#{$home_root}/#{account_name}/cron-#{$cron_version}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  unless negate
    marker_file.should be_a(File)
  else
    marker_file.should be_nil
  end
end