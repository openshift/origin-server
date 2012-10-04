@runtime
@runtime3
@not-origin
Feature: PostgreSQL Application Sub-Cartridge

  Scenario: Create Delete one application with a PostgreSQL database
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
