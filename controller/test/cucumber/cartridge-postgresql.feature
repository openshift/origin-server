@runtime
@runtime3
Feature: PostgreSQL Application Sub-Cartridge
  Scenario Outline: Create Delete one application with a PostgreSQL database
    Given a new perl-5.10 type application

    When I embed a <postgres> cartridge into the application
    Then a postgres process will be running
    And the embedded <postgres> cartridge directory will exist
    And the postgresql configuration file will exist
    And the postgresql database will exist
    And the embedded <postgres> cartridge control script will not exist
    And the postgresql admin user will have access

    When I stop the <postgres> cartridge
    Then a postgres process will not be running

    When I start the <postgres> cartridge
    Then a postgres process will be running

    When the application cartridge PIDs are tracked
    And I restart the <postgres> cartridge
    Then a postgres process will be running
    And the tracked application cartridge PIDs should be changed

    When I destroy the application
    Then a postgres process will not be running
    And the postgresql database will not exist
    And the postgresql configuration file will not exist
    And the embedded <postgres> cartridge directory will not exist

    @rhel-only
    Scenario: Postgres 8.4
    | postgres       |
    | postgresql-8.4 |

    @fedora-only
    Scenario: Postgres 9.1
    | postgres       |
    | postgresql-9.1 |
