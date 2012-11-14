@runtime
Feature: Cartridge Runtime Extended Checks (Database)

  @runtime_extended2
  Scenario Outline: Embed and then remove database cartridges
    Given a new <app_type> type application
    
    When I embed a <db_cart_type> cartridge into the application
    Then a <db_proc> process will be running
    And the embedded <db_cart_type> cartridge directory will exist
    And the <db_name> configuration file will exist
    And the <db_name> database will exist
    And the <db_name> admin user will have access
    And the embedded <db_cart_type> cartridge control script will not exist
    
    When I remove the <db_cart_type> cartridge from the application
    Then a <db_proc> process will not be running
    And the <db_name> database will not exist
    And the <db_name> configuration file will not exist
    And the embedded <db_cart_type> cartridge directory will not exist

  Scenarios: Embed/Unembed database cartridge scenarios
    | app_type  | db_cart_type    | db_proc   | db_name     |
    | php-5.3   | mysql-5.1       | mysqld    | mysql       |
    | php-5.3   | mongodb-2.2     | mongod    | mongodb     |
    | ruby-1.9  | mongodb-2.2     | mongod    | mongodb     |
    | ruby-1.8  | mongodb-2.2     | mongod    | mongodb     |


  @runtime_extended2
  @not-origin
  Scenario Outline: Embed and then remove database cartridges
    Given a new <app_type> type application
    
    When I embed a <db_cart_type> cartridge into the application
    Then a <db_proc> process will be running
    And the embedded <db_cart_type> cartridge directory will exist
    And the <db_name> configuration file will exist
    And the <db_name> database will exist
    And the embedded <db_cart_type> cartridge control script will not exist
    
    When I remove the <db_cart_type> cartridge from the application
    Then a <db_proc> process will not be running
    And the <db_name> database will not exist
    And the embedded <db_cart_type> cartridge control script will not exist
    And the <db_name> configuration file will not exist
    And the embedded <db_cart_type> cartridge directory will not exist

  Scenarios: Embed/Unembed database cartridge scenarios
    | app_type  | db_cart_type    | db_proc   | db_name     |
    | php-5.3   | postgresql-8.4  | postgres  | postgresql  |

  @runtime_extended2
  Scenario: Embed all databases into one cartridges
    Given a new php-5.3 type application
    When I embed a mysql-5.1 cartridge into the application
    And I embed a postgresql-8.4 cartridge into the application
    And I embed a mongodb-2.2 cartridge into the application
    Then a mysqld process will be running
    And the embedded mysql-5.1 cartridge directory will exist
    And a postgres process will be running
    And the embedded postgresql-8.4 cartridge directory will exist
    And a mongod process will be running
    And the embedded mongodb-2.2 cartridge directory will exist
