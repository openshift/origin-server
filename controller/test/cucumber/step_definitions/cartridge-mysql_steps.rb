# step descriptions for MySQL cartridge behavior.

require 'rubygems'
require 'mysql'
require 'fileutils'

Then /^the mysql configuration file will( not)? exist$/ do |negate|
  mysql_cart = @gear.carts['mysql-5.5']

  mysql_user_root = "#{$home_root}/#{@gear.uuid}/#{mysql_cart.directory}"
  mysql_config_file = "#{mysql_user_root}/etc/my.cnf"

  if negate
    refute_file_exist mysql_config_file
  else
    assert_file_exist mysql_config_file
  end
end


Then /^the mysql database will( not)? +exist$/ do |negate|
  mysql_cart = @gear.carts['mysql-5.5']

  mysql_user_root = "#{$home_root}/#{@gear.uuid}/#{mysql_cart.directory}"
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
    datadir.should include @app.name
  else
    datadir.should be_nil
  end
end

Then /^the mysql admin user will have access$/ do
  mysql_cart = @gear.carts['mysql-5.5']

  begin
    dbh = Mysql.real_connect(mysql_cart.db.ip, 
                             mysql_cart.db.username, 
                             mysql_cart.db.password,
                             'mysql')
  rescue Mysql::Error
    dbh = nil
  end

  dbh.should be_a(Mysql)
  dbh.close if dbh
end
