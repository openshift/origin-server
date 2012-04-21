@internals
@node
Feature: PostgreSQL Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with a PostgreSQL database
    Given an accepted node
    And a new guest account
    And a new <type> application
    When I configure a postgresql database
    Then the postgresql directory will exist
    And the postgresql configuration file will exist
    And the postgresql database will exist
    And the postgresql control script will exist
    And the postgresql daemon will be running
    And the postgresql admin user will have access

    When I stop the postgresql database
    Then the postgresql daemon will not be running
    And the postgresql daemon is stopped

    When I start the postgresql database
    Then the postgresql daemon will be running

    When I restart the postgresql database
    Then the postgresql daemon will be running
    And the postgresql daemon pid will be different

    When I deconfigure the postgresql database
    Then the postgresql directory will not exist
    And the postgresql configuration file will not exist
    And the postgresql database will not exist
    And the postgresql control script will not exist
    And the postgresql daemon will not be running

  Scenarios: Create Delete Application With Database Scenarios
    |type|
    |php|
