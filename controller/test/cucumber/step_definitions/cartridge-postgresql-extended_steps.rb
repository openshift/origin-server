include SQLHelper

Given /^I use the helper to connect to the postgresql database$/ do
  @psql_env = {}
  @psql_opts = {}
end

Given /^I use (.*) to connect to the postgresql database as (\w+)(.*)?$/ do |type,user,options|
  @psql_opts = {}
  @psql_env = {}

  case type
  when 'socket'
    @psql_opts['-h'] = '$OPENSHIFT_POSTGRESQL_DB_SOCKET'
  when 'host'
    @psql_opts['-h'] = '$OPENSHIFT_POSTGRESQL_DB_HOST'
    @psql_opts['-p'] = '$OPENSHIFT_POSTGRESQL_DB_PORT'
  end

  @psql_opts['-U'] = case user
               when 'env'
                 '$OPENSHIFT_POSTGRESQL_DB_USERNAME'
               else
                 user
               end

  case options
  when /with password/
    @psql_env['PGPASSWORD'] = '$OPENSHIFT_POSTGRESQL_DB_PASSWORD'
  when /with passfile/
    @psql_env['PGPASSFILE'] = nil
  end
end

When /^I should( not)? be able to query the postgresql database$/ do |negate|
  run_psql('select 1')

  if negate
    @exitstatus.should_not eq 0
  else
    @exitstatus.should eq 0
  end
end

When /^I create a test table in postgres( without dropping)?$/ do |drop|
  sql = <<-sql
    CREATE TABLE cuke_test (
      id integer PRIMARY KEY,
      msg text
    );
  sql

  without = !!!drop
  if without
    drop_sql = <<-sql
      DROP TABLE IF EXISTS cuke_test;
    sql

    sql = "#{drop_sql} #{sql}"
  end

  @query_result = run_psql(sql)
end

When "I create a test database in postgres" do
  run_psql("CREATE DATABASE new_test_database;")
end

When /^I insert (additional )?test data into postgres$/ do |additional|
  run_sql = <<-sql
    INSERT INTO cuke_test VALUES (1,'initial data');
  sql

  additional_sql = <<-sql
    INSERT INTO cuke_test VALUES (2,'additional data');
  sql

  run_sql = additional_sql if additional

  @query_result = run_psql(run_sql)
end

Then /^the (additional )?test data will (not )?be present in postgres$/ do |additional, negate|
  @query_result = run_psql('select msg from cuke_test;')

  desired_state = !!!negate
  desired_out = additional ? "additional" : "initial"

  if (desired_state)
    @query_result.should include(desired_out)
  else
    @query_result.should_not include(desired_out)
  end
end

When /^I replace (.*) authentication with (.*) in the configuration file$/ do |old_auth,new_auth|
  @app.ssh_command("sed -i s/#{old_auth}/#{new_auth}/ postgresql/data/pg_hba.conf")
end

When /^the debug data should (not )?exist in the log file$/ do |negate|
  @app.ssh_command('egrep -r \'^ZZZZZ\' \$OPENSHIFT_POSTGRESQL_DB_LOG_DIR')
  exit_status = $?.exitstatus

  if negate
    exit_status.should_not eq 0
  else
    exit_status.should eq 0
  end
end

When /^I add debug data to the log file$/ do
  # This can probably be made into a single command
  file = @app.ssh_command('find \$OPENSHIFT_POSTGRESQL_DB_LOG_DIR -type f | head -n1')
  @app.ssh_command("echo 'ZZZZZ' >> #{file}")
end

When "all databases will have the correct ownership" do
  username = @app.ssh_command('echo \$OPENSHIFT_POSTGRESQL_DB_USERNAME')
  dbs = run_psql("SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE NOT(rolname = '#{username}' OR rolname = 'postgres')").lines.to_a.compact.map(&:strip).delete_if(&:empty?)
  # TODO: This can be done better if we can run the ssh command without the MOTD
  dbs.select{|x| @apps.include?(x) }.should eq []
end
