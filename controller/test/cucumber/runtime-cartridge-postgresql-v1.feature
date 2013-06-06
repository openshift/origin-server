@rhel-only
Feature: PostgreSQL Application Sub-Cartridge
  @runtime_extended_other2
  @runtime
  @postgres
  Scenario: Create Delete one application with a PostgreSQL database
    #Given a perl-5.10 application, verify addition and removal of postgresql 8.4
    Given a new perl-5.10 type application

    When I embed a postgresql-8.4 cartridge into the application
    Then a postgres process will be running
    And the embedded postgresql-8.4 cartridge directory will exist
    And the postgresql configuration file will exist
    And the postgresql database will exist
    And the embedded postgresql-8.4 cartridge control script will not exist
    And the postgresql admin user will have access

    When I stop the postgresql-8.4 cartridge
    Then a postgres process will not be running

    When I start the postgresql-8.4 cartridge
    Then a postgres process will be running

    When the application cartridge PIDs are tracked
    And I restart the postgresql-8.4 cartridge
    Then a postgres process will be running
    And the tracked application cartridge PIDs should be changed

    When I destroy the application
    Then a postgres process will not be running
    And the postgresql database will not exist
    And the postgresql configuration file will not exist
    And the embedded postgresql-8.4 cartridge directory will not exist

  @runtime_extended_other3
  @postgres
  Scenario Outline: Use socket file to connect to database
    Given a new <php_version> type application
    And I embed a <postgres_cart> cartridge into the application
    And the application is made publicly accessible

    Given I use socket to connect to the postgresql database as env with password
    Then I should be able to query the postgresql database

    Scenarios: database cartridge scenarios
      | postgres_cart  | php_version |
      | postgresql-8.4 | php-5.3     |

