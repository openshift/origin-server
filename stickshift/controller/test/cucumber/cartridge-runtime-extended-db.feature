@runtime
Feature: Cartridge Runtime Extended Checks (Database)

  @runtime_extended2
  Scenario Outline: Embed and then unembed database cartridges
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
    And the <db_name> configuration file will not exist
    And the embedded <db_cart_type> cartridge directory will not exist

  Scenarios: Embed/Unembed database cartridge scenarios
    | app_type  | db_cart_type    | db_proc   | db_name     |
    | php-5.3   | mysql-5.1       | mysqld    | mysql       |
    | php-5.3   | mongodb-2.2     | mongod    | mongodb     |


  @runtime_extended2
  @not-origin
  Scenario Outline: Embed and then unembed database cartridges
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
