# step descriptions for MongoDB cartridge behavior.

require 'mongo'
require 'fileutils'

$mongodb_version = "2.0"
$mongodb_cart_root = "/usr/libexec/stickshift/cartridges/embedded/mongodb-#{$mongodb_version}"
$mongodb_hooks = $mongodb_cart_root + "/info/hooks"
$mongodb_config = $mongodb_hooks + "/configure"
$mongodb_config_format = "#{$mongodb_config} %s %s %s"
$mongodb_deconfig = $mongodb_hooks + "/deconfigure"
$mongodb_deconfig_format = "#{$mongodb_deconfig} %s %s %s"

When /^I configure a mongodb database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mongodb_config_format % [app_name, namespace, account_name]

  my_username_pattern = /Root User: (\S+)/
  my_password_pattern = /Root Password: (\S+)/
  my_ip_pattern = /mongodb:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: mongodb://$IP:27017/"
  stdout = outbuf[0]
  @mongodb = {}
  stdout.each do |line|
    if line.match(my_username_pattern)
      @mongodb['username'] = $1
    end
    if line.match(my_password_pattern)
      @mongodb['password'] = $1
    end
    if line.match(my_ip_pattern)
      @mongodb['ip'] = $1
      @mongodb['port'] = $2
    end
  end
end

When /^I deconfigure the mongodb database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mongodb_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the mongodb directory will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{account_name}/mongodb-#{$mongodb_version}"
  begin
    mongodb_dir = Dir.new mongodb_user_root
  rescue Errno::ENOENT
    mongodb_dir = nil
  end

  unless negate
    mongodb_dir.should be_a(Dir)
  else
    mongodb_dir.should be_nil
  end
end


Then /^the mongodb control script will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{account_name}/mongodb-#{$mongodb_version}"
  mongodb_startup_file = "#{mongodb_user_root}/#{app_name}_mongodb_ctl.sh"

  begin
    startfile = File.new mongodb_startup_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    startfile.should be_a(File)
  else
    startfile.should be_nil
  end
end

Then /^the mongodb configuration file will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{account_name}/mongodb-#{$mongodb_version}"
  mongodb_config_file = "#{mongodb_user_root}/etc/mongodb.conf"

  begin
    cnffile = File.new mongodb_config_file
  rescue Errno::ENOENT
    cnffile = nil
  end

  unless negate
    cnffile.should be_a(File)
  else
    cnffile.should be_nil
  end
end


Then /^the mongodb database will( not)? +exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{account_name}/mongodb-#{$mongodb_version}"
  mongodb_data_dir = "#{mongodb_user_root}/data/"

  begin
    datadir = Dir.new mongodb_data_dir
  rescue Errno::ENOENT
    datadir = nil
  end

  unless negate
    datadir.should include "#{app_name}.0"
    datadir.should include "#{app_name}.ns"
    datadir.should include "mongod.lock"
    datadir.should include "admin.0"
    datadir.should include "admin.ns"
  else
    datadir.should be_nil
  end
end

Then /^the mongodb daemon will( not)? be running$/ do |negate|

  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 10
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_daemons = num_procs acct_name, 'mongodbd'
  $logger.debug("checking that mongodbd is#{negate} running")
  $logger.debug("try # #{tries}")
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'mongod'
  end

  if not negate
    num_daemons.should be > 0
  else
    num_daemons.should be == 0
  end
end

Then /^the mongodb admin user will have access$/ do
  begin
    dbh = Mongo::Connection.new(@mongodb['ip'].to_s).db(@app['name'].to_s)
    dbh.authenticate(@mongodb['username'].to_s, @mongodb['password'].to_s)
  rescue Mongo::ConnectionError
    dbh = nil
  end

  dbh.should be_a(Mongo::DB)
  dbh.logout if dbh
end

Given /^a new mongodb database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mongodb_config_format % [app_name, namespace, account_name]

  my_username_pattern = /Root User: (\S+)/
  my_password_pattern = /Root Password: (\S+)/
  my_ip_pattern = /mongodb:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    FileUtils.cp "/var/lib/stickshift/#{account_name}/mongodb-2.0/log/mongodb_error.log", "/tmp/rhc/mongodb_error_#{account_name}.log"
    raise "Error running #{command}: returned #{exit_code}"
  end
  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: mongodb://$IP:3306/"
  stdout = outbuf[0]
  @mongodb = {}
  stdout.each do |line|
    if line.match(my_username_pattern)
      @mongodb['username'] = $1
    end
    if line.match(my_password_pattern)
      @mongodb['password'] = $1
    end
    if line.match(my_ip_pattern)
      @mongodb['ip'] = $1
      @mongodb['port'] = $2
    end
  end

end

Given /^the mongodb daemon is (running|stopped)$/ do |status|

  action = status == "running" ? "start" : "stop"

  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$mongodb_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"

  num_daemons = num_procs acct_name, 'mongodbd'
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
  num_daemons = num_procs acct_name, 'mongodbd'
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'mongodbd'
  end
end

When /^I (start|stop|restart) the mongodb database$/ do |action|
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{acct_name}/mongodb-#{$mongodb_version}"
  mongodb_pid_file = mongodb_user_root + "/pid/mongodb.pid"

  if File.exists? mongodb_pid_file
    begin
      @mongodb['oldpid'] = File.open(mongodb_pid_file).readline.strip
    rescue EOFError
      @mongodb['oldpid'] = '0'
    end
  end

  outbuf = []
  command = "#{$mongodb_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
end

Then /^the mongodb daemon pid will be different$/ do
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mongodb_user_root = "#{$home_root}/#{acct_name}/mongodb-#{$mongodb_version}"
  mongodb_pid_file = "#{mongodb_user_root}/pid/mongodb.pid"

  newpid = File.open(mongodb_pid_file).readline.strip

  newpid.should_not == @mongodb['oldpid']
end

