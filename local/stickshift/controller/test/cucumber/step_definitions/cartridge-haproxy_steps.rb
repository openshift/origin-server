# step descriptions for HAProxy cartridge behavior.

require 'fileutils'

$haproxy_version = "1.4"
$haproxy_cart_root = "/usr/libexec/stickshift/cartridges/embedded/haproxy-#{$haproxy_version}"
$haproxy_hooks = $haproxy_cart_root + "/info/hooks"
$haproxy_config = $haproxy_hooks + "/configure"
$haproxy_config_format = "#{$haproxy_config} %s %s %s"
$haproxy_deconfig = $haproxy_hooks + "/deconfigure"
$haproxy_deconfig_format = "#{$haproxy_deconfig} %s %s %s"

# Hack to ensure haproxy_ctld_daemon continues to work
ENV['BUNDLE_GEMFILE'] = nil

When /^I configure haproxy$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $haproxy_config_format % [app_name, namespace, account_name]

  outbuf = []
  exit_status = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_status != 0
    raise "unable to configure for %s %s %s" % [ app_name, namespace, account_name ]
  end
end

When /^I deconfigure haproxy$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $haproxy_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the haproxy directory will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  haproxy_user_root = "#{$home_root}/#{account_name}/haproxy-#{$haproxy_version}"
  begin
    haproxy_dir = Dir.new haproxy_user_root
  rescue Errno::ENOENT
    haproxy_dir = nil
  end

  unless negate
    haproxy_dir.should be_a(Dir)
  else
    haproxy_dir.should be_nil
  end
end


Then /^the haproxy PATH override will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  path_location = "#{$home_root}/#{account_name}/.env/PATH"

  path_override = open(path_location).grep(/haproxy-1.4/)[0]

  unless negate
    path_override.should be_a(String)
  else
    path_override.should be_nil
  end
end

Then /^the haproxy configuration file will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  haproxy_user_root = "#{$home_root}/#{account_name}/haproxy-#{$haproxy_version}"
  haproxy_config_file = "#{haproxy_user_root}/conf/haproxy.cfg.template"

  begin
    cnffile = File.new haproxy_config_file
  rescue Errno::ENOENT
    cnffile = nil
  end

  unless negate
    cnffile.should be_a(File)
  else
    cnffile.should be_nil
  end
end

Then /^the haproxy daemon will( not)? be running$/ do |negate|

  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 10
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_daemons = num_procs acct_name, 'haproxy'
  $logger.debug("checking that haproxy is#{negate} running")
  $logger.debug("try # #{tries}")
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'haproxy'
  end

  if not negate
    num_daemons.should be > 0
  else
    num_daemons.should be == 0
  end
end

Given /^the haproxy daemon is (running|stopped)$/ do |status|

  action = status == "running" ? "start" : "stop"

  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$haproxy_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"

  num_daemons = num_procs acct_name, 'haproxyd'
  outbuf = []

  case action
  when 'start'
    if num_daemons == 0
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |tval| tval > 0 }    
  when 'stop'
    if num_daemons > 0
      runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
    end
    exit_test = lambda { |tval| tval == 0 }
  # else 
  #   raise an exception
  end

  # now loop until it's true
  max_tries = 10
  poll_rate = 3  
  tries = 0
  num_daemons = num_procs acct_name, 'haproxyd'
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'haproxyd'
  end
end

When /^I (start|stop|restart) the haproxy database$/ do |action|
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  haproxy_user_root = "#{$home_root}/#{acct_name}/haproxy-#{$haproxy_version}"
  haproxy_pid_file = haproxy_user_root + "/pid/haproxy.pid"

  if File.exists? haproxy_pid_file
    @haproxy['oldpid'] = File.open(haproxy_pid_file).readline.strip
  end

  outbuf = []
  command = "#{$haproxy_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
end

Then /^the haproxy daemon pid will be different$/ do
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  haproxy_user_root = "#{$home_root}/#{acct_name}/haproxy-#{$haproxy_version}"
  haproxy_pid_file = "#{haproxy_user_root}/pid/haproxy.pid"

  newpid = File.open(haproxy_pid_file).readline.strip

  newpid.should_not == @haproxy['oldpid']
end
