# step descriptions for PostgreSQL cartridge behavior.

require 'postgres'
require 'fileutils'

$pgsql_version = "8.4"
$pgsql_cart_root = "/usr/libexec/stickshift/cartridges/embedded/postgresql-#{$pgsql_version}"
$pgsql_hooks = $pgsql_cart_root + "/info/hooks"
$pgsql_config = $pgsql_hooks + "/configure"
$pgsql_config_format = "#{$pgsql_config} %s %s %s"
$pgsql_deconfig = $pgsql_hooks + "/deconfigure"
$pgsql_deconfig_format = "#{$pgsql_deconfig} %s %s %s"

When /^I configure a postgresql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $pgsql_config_format % [app_name, namespace, account_name]

  pg_username_pattern = /Root User: (\S+)/
  pg_password_pattern = /Root Password: (\S+)/
  pg_ip_pattern = /postgresql:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: postgresql://$IP:3306/"
  stdout = outbuf[0]
  @pgsql = {}
  stdout.each do |line|
    if line.match(pg_username_pattern)
      @pgsql['username'] = $1
    end
    if line.match(pg_password_pattern)
      @pgsql['password'] = $1
    end
    if line.match(pg_ip_pattern)
      @pgsql['ip'] = $1
      @pgsql['port'] = $2
    end
  end
end

When /^I deconfigure the postgresql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $pgsql_deconfig_format % [app_name, namespace, account_name]
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type
  if exit_code != 0
    raise "Command failed with exit code #{exit_code}"
  end
end

Then /^the postgresql directory will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{account_name}/postgresql-#{$pgsql_version}"
  begin
    pgsql_dir = Dir.new pgsql_user_root
  rescue Errno::ENOENT
    pgsql_dir = nil
  end

  unless negate
    pgsql_dir.should be_a(Dir)
  else
    pgsql_dir.should be_nil
  end
end


Then /^the postgresql control script will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{account_name}/postgresql-#{$pgsql_version}"
  pgsql_startup_file = "#{pgsql_user_root}/#{app_name}_postgresql_ctl.sh"

  begin
    startfile = File.new pgsql_startup_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    startfile.should be_a(File)
  else
    startfile.should be_nil
  end
end

Then /^the postgresql configuration file will( not)? exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{account_name}/postgresql-#{$pgsql_version}"
  pgsql_config_file = "#{pgsql_user_root}/data/postgresql.conf"

  begin
    cnffile = File.new pgsql_config_file
  rescue Errno::ENOENT
    cnffile = nil
  end

  unless negate
    cnffile.should be_a(File)
  else
    cnffile.should be_nil
  end
end


Then /^the postgresql database will( not)? +exist$/ do |negate|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{account_name}/postgresql-#{$pgsql_version}"
  pgsql_data_dir = "#{pgsql_user_root}/data"

  begin
    datadir = Dir.new pgsql_data_dir
  rescue Errno::ENOENT
    datadir = nil
  end

  unless negate
    datadir.should include "base"
    datadir.should include "global"
    datadir.should include "pg_clog"
    datadir.should include "pg_log"
    datadir.should include "pg_xlog"
  else
    datadir.should be_nil
  end
end

Then /^the postgresql daemon will( not)? be running$/ do |negate|

  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 10
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_daemons = num_procs acct_name, 'postgres'
  $logger.debug("checking that postgres is#{negate} running")
  $logger.debug("try # #{tries}")
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'postgres'
  end

  if not negate
    num_daemons.should be > 0
  else
    num_daemons.should be == 0
  end
end

Then /^the postgresql admin user will have access$/ do
  begin
    # FIXME: For now use psql -- we should try programatically later.
    dbconn = PGconn.connect(@pgsql['ip'], 5432, '', '', 'postgres',
                            @pgsql['username'], @pgsql['password'])
  rescue PGError
    dbconn = nil
 end

 dbconn.should be_a(PGconn)
 dbconn.close if dbconn
end

Given /^a new postgresql database$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $pgsql_config_format % [app_name, namespace, account_name]

  pg_username_pattern = /Root User: (\S+)/
  pg_password_pattern = /Root Password: (\S+)/
  pg_ip_pattern = /postgresql:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

  outbuf = []
  exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf

  if exit_code != 0
    FileUtils.cp "/var/lib/stickshift/#{account_name}/postgresql-#{$pgsql_version}/log/postgres.log", "/tmp/rhc/postgresql_error_#{account_name}.log"
    raise "Error running #{command}: returned #{exit_code}"
  end
  # I have to get the stdout back
  # outbuf[0] = stdout, outbuf[1] = stderr
  
  # "Root User: admin"
  # "Root Password: $password"
  # "Connection URL: postgresql://$IP:3306/"
  stdout = outbuf[0]
  @pgsql = {}
  stdout.each do |line|
    if line.match(pg_username_pattern)
      @pgsql['username'] = $1
    end
    if line.match(pg_password_pattern)
      @pgsql['password'] = $1
    end
    if line.match(pg_ip_pattern)
      @pgsql['ip'] = $1
      @pgsql['port'] = $2
    end
  end

end

Given /^the postgresql daemon is (running|stopped)$/ do |status|

  action = status == "running" ? "start" : "stop"

  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$pgsql_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"

  num_daemons = num_procs acct_name, 'postgres'
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
  num_daemons = num_procs acct_name, 'postgres'
  while (not exit_test.call(num_daemons) and tries < max_tries)
    tries += 1
    sleep poll_rate
    num_daemons = num_procs acct_name, 'postgres'
  end
end

When /^I (start|stop|restart) the postgresql database$/ do |action|
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{acct_name}/postgresql-#{$pgsql_version}"
  pgsql_pid_file = pgsql_user_root + "/pid/postgres.pid"

  if File.exists? pgsql_pid_file
    @pgsql['oldpid'] = File.open(pgsql_pid_file).readline.strip
  end

  outbuf = []
  command = "#{$pgsql_hooks}/#{action} #{app_name} #{namespace} #{acct_name}"
  runcon command,  $selinux_user, $selinux_role, $selinux_type, outbuf
end

Then /^the postgresql daemon pid will be different$/ do
  acct_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  pgsql_user_root = "#{$home_root}/#{acct_name}/postgresql-#{$pgsql_version}"
  pgsql_pid_file = "#{pgsql_user_root}/pid/postgres.pid"

  newpid = File.open(pgsql_pid_file).readline.strip

  newpid.should_not == @pgsql['oldpid']
end

