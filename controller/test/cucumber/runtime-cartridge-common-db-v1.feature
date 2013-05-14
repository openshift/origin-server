@runtime
@runtime_extended_other2
@rhel-only
Feature: Cartridge Runtime Extended Checks (Database)

  Scenario Outline: Embed and then remove database cartridges (Common)
    #Given a <app_type> application, add and remove <db_cart_type> database and use <db_proc> proc and <db_name> name to verify
    Given a new <cart_name> type application

    When I embed a <db_cart_type> cartridge into the application
    Then a <db_proc> process will be running
    And the embedded <db_cart_type> cartridge directory will exist
    And the <db_name> configuration file will exist
    And the <db_name> database will exist
    And the <db_name> admin user will have access
    And the embedded <db_cart_type> cartridge control script will not exist

    When I remove the <db_cart_type> cartridge from the application
    Then a <db_proc> process will not be running
    And the embedded <db_cart_type> cartridge control script will not exist
    And the <db_name> database will not exist
    And the <db_name> configuration file will not exist
    And the embedded <db_cart_type> cartridge directory will not exist

    @rhel-only
    Scenarios: Embed/Unembed database cartridge scenarios
      | app_type  | db_cart_type    | db_proc   | db_name     |
      | ruby-1.9  | mongodb-2.2     | mongod    | mongodb     |
      | php-5.3   | mysql-5.1       | mysqld    | mysql       |
      | php-5.3   | mongodb-2.2     | mongod    | mongodb     |
      | ruby-1.8  | mongodb-2.2     | mongod    | mongodb     |
      | php-5.3   | postgresql-8.4  | postgres  | postgresql  |

  Scenario Outline: Embed all databases into one cartridges (RHEL/CentOS)
    #Given a php-5.3 application, embed mysql-5.1, postgresql-8.4, mongodb-2.2
    Given a new <cart_name> type application
    When I embed a mysql-<mysql_version> cartridge into the application
    And I embed a postgresql-<postgresql_version> cartridge into the application
    And I embed a mongodb-<mongodb_version> cartridge into the application
    Then a mysqld process will be running
    And the embedded mysql-<mysql_version> cartridge directory will exist
    And a postgres process will be running
    And the embedded postgresql-<postgresql_version> cartridge directory will exist
    And a mongod process will be running
    And the embedded mongodb-<mongodb_version> cartridge directory will exist

    @rhel-only
    Scenarios: RHEL
      | cart_name | mysql_version | postgresql_version | mongodb_version |
      |  php-5.3  |      5.1      |         8.4        |       2.2       |
