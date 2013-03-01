Given /^a ([^ ]+) application, add and remove ([^ ]+) database and use ([^ ]+) proc and ([^ ]+) name to verify$/ do |cart_name, db_cart_type, db_proc, db_name|
  steps %Q{
    Given a new #{cart_name} type application
    
    When I embed a #{db_cart_type} cartridge into the application
    Then a #{db_proc} process will be running
    And the embedded #{db_cart_type} cartridge directory will exist
    And the #{db_name} configuration file will exist
    And the #{db_name} database will exist
    And the #{db_name} admin user will have access
    And the embedded #{db_cart_type} cartridge control script will not exist
    
    When I remove the #{db_cart_type} cartridge from the application
    Then a #{db_proc} process will not be running
    And the embedded #{db_cart_type} cartridge control script will not exist    
    And the #{db_name} database will not exist
    And the #{db_name} configuration file will not exist
    And the embedded #{db_cart_type} cartridge directory will not exist
  }
end

Given /^a ([^ ]+) application, embed mysql-([^ ]+), postgresql-([^ ]+), mongodb-([^ ]+) $/ do |cart_name, mysql_version, postgresql_version, mongodb_version|
  steps %Q{
    Given a new #{cart_name} type application
    When I embed a mysql-#{mysql_version} cartridge into the application
    And I embed a postgresql-#{postgresql_version} cartridge into the application
    And I embed a mongodb-#{mongodb_version} cartridge into the application
    Then a mysqld process will be running
    And the embedded mysql-#{mysql_version} cartridge directory will exist
    And a postgres process will be running
    And the embedded postgresql-#{postgresql_version} cartridge directory will exist
    And a mongod process will be running
    And the embedded mongodb-#{mongodb_version} cartridge directory will exist
  }
end


