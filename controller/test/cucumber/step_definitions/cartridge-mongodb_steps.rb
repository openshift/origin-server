# step descriptions for MongoDB cartridge behavior.

require 'mongo'
require 'fileutils'

Given /^a ([^ ]+) application, verify addition and removal of MongoDB database$/ do |cart_name|
  steps %Q{
    Given a new #{cart_name} type application
    
    When I embed a mongodb-2.2 cartridge into the application
    Then 1 process named mongod will be running
    And the embedded mongodb-2.2 cartridge directory will exist
    And the mongodb configuration file will exist
    And the mongodb database will exist
    And the embedded mongodb-2.2 cartridge control script will not exist
    And the mongodb admin user will have access

    When I stop the mongodb-2.2 cartridge
    Then 0 processes named mongod will be running

    When I start the mongodb-2.2 cartridge
    Then 1 process named mongod will be running

    When the application cartridge PIDs are tracked
    And I restart the mongodb-2.2 cartridge
    Then 1 process named mongod will be running
    And the tracked application cartridge PIDs should be changed

    When I destroy the application
    Then 0 processes named mongod will be running
    And the mongodb database will not exist
    And the mongodb configuration file will not exist
    And the embedded mongodb-2.2 cartridge directory will not exist
  }
end

Then /^the mongodb configuration file will( not)? exist$/ do |negate|
  cart = @gear.carts['mongodb-2.2']
  user_root = "#{$home_root}/#{@gear.uuid}/#{cart.name}"
  config_file = "#{user_root}/etc/mongodb.conf"

  begin
    cnffile = File.new config_file
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
  cart = @gear.carts['mongodb-2.2']
  user_root = "#{$home_root}/#{@gear.uuid}/#{cart.name}"
  config_file = "#{user_root}/etc/mongodb.conf"
  data_dir = "#{user_root}/data/"

  begin
    datadir = Dir.new data_dir
  rescue Errno::ENOENT
    datadir = nil
  end

  unless negate
    datadir.should include "#{@app.name}.0"
    datadir.should include "#{@app.name}.ns"
    datadir.should include "mongod.lock"
    datadir.should include "admin.0"
    datadir.should include "admin.ns"
  else
    datadir.should be_nil
  end
end

Then /^the mongodb admin user will have access$/ do
  mongo_cart = @gear.carts['mongodb-2.2']

  begin
    dbh = Mongo::Connection.new(mongo_cart.db.ip.to_s).db(@app.name)
    dbh.authenticate(mongo_cart.db.username.to_s, mongo_cart.db.password.to_s)
  rescue Mongo::ConnectionError
    dbh = nil
  end

  dbh.should be_a(Mongo::DB)
  dbh.logout if dbh
end
