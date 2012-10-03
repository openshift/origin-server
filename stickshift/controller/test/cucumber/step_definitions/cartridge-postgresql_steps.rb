# step descriptions for PostgreSQL cartridge behavior.

require 'postgres'
require 'fileutils'


Then /^the postgresql configuration file will( not)? exist$/ do |negate|
  pgsql_cart = @gear.carts['postgresql-8.4']

  pgsql_user_root = "#{$home_root}/#{@gear.uuid}/#{pgsql_cart.name}"
  pgsql_config_file = "#{pgsql_user_root}/data/postgresql.conf"

  if negate
    assert_file_not_exists pgsql_config_file
  else
    assert_file_exists pgsql_config_file
  end
end


Then /^the postgresql database will( not)? +exist$/ do |negate|
  pgsql_cart = @gear.carts['postgresql-8.4']

  pgsql_user_root = "#{$home_root}/#{@gear.uuid}/#{pgsql_cart.name}"
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


Then /^the postgresql admin user will have access$/ do
  pgsql_cart = @gear.carts['postgresql-8.4']

  begin
    # FIXME: For now use psql -- we should try programatically later.
    dbconn = PGconn.connect(pgsql_cart.db.ip, 5432, '', '', 'postgres',
                            pgsql_cart.db.username, pgsql_cart.db.password)
  rescue PGError
    $logger.error("Couldn't connect to Postgres, ip=#{pgsql_cart.db.ip}, user=#{pgsql_cart.db.username}, pwd=#{pgsql_cart.db.password}")
    dbconn = nil
 end

 dbconn.should be_a(PGconn)
 dbconn.close if dbconn
end
