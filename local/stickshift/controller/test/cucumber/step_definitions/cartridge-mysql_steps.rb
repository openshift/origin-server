# step descriptions for MySQL cartridge behavior.

require 'mysql'
require 'fileutils'

$mysql_version = "5.1"
$mysql_cart_root = "/usr/libexec/stickshift/cartridges/embedded/mysql-#{$mysql_version}"
$mysql_hooks = $mysql_cart_root + "/info/hooks"
$mysql_config = $mysql_hooks + "/configure"
$mysql_config_format = "#{$mysql_config} %s %s %s"
$mysql_deconfig = $mysql_hooks + "/deconfigure"
$mysql_deconfig_format = "#{$mysql_deconfig} %s %s %s"

When /^I configure a mysql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mysql_config_format % [app_name, namespace, account_name]

  my_username_pattern = /Root User: (\S+)/
  my_password_pattern = /Root Password: (\S+)/
  my_ip_pattern = /mysql:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: mysql://$IP:3306/"
  stdout = outbuf[0]
  @mysql = {}
  stdout.each do |line|
    if line.match(my_username_pattern)
      @mysql['username'] = $1
    end
    if line.match(my_password_pattern)
      @mysql['password'] = $1
    end
    if line.match(my_ip_pattern)
      @mysql['ip'] = $1
      @mysql['port'] = $2
    end
  end
end

When /^I deconfigure the mysql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mysql_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the mysql directory will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{account_name}/mysql-#{$mysql_version}"
  begin
    mysql_dir = Dir.new mysql_user_root
  rescue Errno::ENOENT
    mysql_dir = nil
  end

  unless negate
    mysql_dir.should be_a(Dir)
  else
    mysql_dir.should be_nil
  end
end


Then /^the mysql control script will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{account_name}/mysql-#{$mysql_version}"
  mysql_startup_file = "#{mysql_user_root}/#{app_name}_mysql_ctl.sh"

  begin
    startfile = File.new mysql_startup_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    startfile.should be_a(File)
  else
    startfile.should be_nil
  end
end

Then /^the mysql configuration file will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{account_name}/mysql-#{$mysql_version}"
  mysql_config_file = "#{mysql_user_root}/etc/my.cnf"

  begin
    cnffile = File.new mysql_config_file
  rescue Errno::ENOENT
    cnffile = nil
  end

  unless negate
    cnffile.should be_a(File)
  else
    cnffile.should be_nil
  end
end


Then /^the mysql database will( not)? +exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{account_name}/mysql-#{$mysql_version}"
  mysql_data_dir = "#{mysql_user_root}/data"

  begin
    datadir = Dir.new mysql_data_dir
  rescue Errno::ENOENT
    datadir = nil
  end

  unless negate
    datadir.should include "ibdata1"
    datadir.should include "ib_logfile0"
    datadir.should include "mysql"
    datadir.should include app_name
  else
    datadir.should be_nil
  end
end

Then /^the mysql daemon will( not)? be running$/ do |negate|

  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 10
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_daemons = num_procs acct_name, 'mysqld'
  $logger.debug("checking that mysqld is#{negate} running")
  $logger.debug("try # #{tries}")
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'mysqld'
  end

  if not negate
    num_daemons.should be > 0
  else
    num_daemons.should be == 0
  end
end

Then /^the admin user will have access$/ do
  begin
    dbh = Mysql.real_connect(@mysql['ip'], 
                             @mysql['username'], 
                             @mysql['password'],
                             'mysql')
  rescue Mysql::Error
    dbh = nil
  end

  dbh.should be_a(Mysql)
  dbh.close if dbh
end

Given /^a new mysql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $mysql_config_format % [app_name, namespace, account_name]

  my_username_pattern = /Root User: (\S+)/
  my_password_pattern = /Root Password: (\S+)/
  my_ip_pattern = /mysql:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    FileUtils.cp "/var/lib/stickshift/#{account_name}/mysql-5.1/log/mysql_error.log", "/tmp/rhc/mysql_error_#{account_name}.log"
    raise "Error running #{command}: returned #{exit_code}"
  end
  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: mysql://$IP:3306/"
  stdout = outbuf[0]
  @mysql = {}
  stdout.each do |line|
    if line.match(my_username_pattern)
      @mysql['username'] = $1
    end
    if line.match(my_password_pattern)
      @mysql['password'] = $1
    end
    if line.match(my_ip_pattern)
      @mysql['ip'] = $1
      @mysql['port'] = $2
    end
  end

end

Given /^the mysql daemon is (running|stopped)$/ do |status|

  action = status == "running" ? "start" : "stop"

  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$mysql_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"

  num_daemons = num_procs acct_name, 'mysqld'
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
  num_daemons = num_procs acct_name, 'mysqld'
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'mysqld'
  end
end

When /^I (start|stop|restart) the mysql database$/ do |action|
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{acct_name}/mysql-#{$mysql_version}"
  mysql_pid_file = mysql_user_root + "/pid/mysql.pid"

  if File.exists? mysql_pid_file
    @mysql['oldpid'] = File.open(mysql_pid_file).readline.strip
  end

  outbuf = []
  command = "#{$mysql_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
end

Then /^the mysql daemon pid will be different$/ do
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  mysql_user_root = "#{$home_root}/#{acct_name}/mysql-#{$mysql_version}"
  mysql_pid_file = "#{mysql_user_root}/pid/mysql.pid"

  newpid = File.open(mysql_pid_file).readline.strip

  newpid.should_not == @mysql['oldpid']
end

