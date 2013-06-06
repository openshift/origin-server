

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


