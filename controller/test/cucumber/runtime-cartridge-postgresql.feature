@postgres
@v2
Feature: Postgres Application Sub-Cartridge
  Background:
    Given a v2 default node

  @runtime_extended1
  @smoke_test
  Scenario: Create/Delete one application with a Postgres database
    Given a new mock-0.1 type application

    When I embed a postgresql-8.4 cartridge into the application
    Then a postgres process will be running
    And the postgresql-8.4 cartridge instance directory will exist

    When I stop the postgresql-8.4 cartridge
    Then a postgres process will not be running

    When I start the postgresql-8.4 cartridge
    Then a postgres process will be running

    When I destroy the application
    Then a postgres process will not be running

  @runtime_extended1
  Scenario Outline: Database connections
    Given I use <method> to connect to the postgresql database <opts>
    Then I <should> be able to query the postgresql database

    Examples:
      | method     | opts        | should |
      | the helper |             | should |
      | socket     | as postgres | should |
      | the host   | as postgres | should not |
      | socket     | as env      | should |
      | socket     | as env      | should |
      | host       | as env      | should not |
      | host       | as env with passfile | should |

  @runtime_extended1
  @scaled
  Scenario Outline: Scaled Database connections
    Given I use <method> to connect to the postgresql database <opts>
    Then I <should> be able to query the postgresql database

    Examples:
      | method     | opts        | should |
      | the helper |             | should |
      | host       | as env      | should not |
      | host       | as env with password | should |

  @runtime_extended1
  Scenario: Tidy Database
    When I add debug data to the log file
    Then the debug data should exist in the log file

    When I tidy the application
    Then the debug data should not exist in the log file

  @runtime_extended1
  Scenario: Reload Database
    Given I use host to connect to the postgresql database as env with password
    Then I should be able to query the postgresql database

    When I replace md5 authentication with reject in the configuration file
    And I reload the application
    Then I should not be able to query the postgresql database

    When I replace reject authentication with md5 in the configuration file
    And I reload the application
    Then I should be able to query the postgresql database

  @scaled
  @runtime_extended3
  @snapshot
  Scenario: Snapshot/Restore a scalable application with a Postgres database
    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

  @runtime_extended3
  @snapshot
  Scenario: Snapshot/Restore an application with a Postgres database
    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

  @runtime_extended3
  @snapshot
  Scenario: Snapshot/Restore after removing/adding Postgres
    Given the embedded postgresql-8.4 cartridge is removed
    Given the embedded postgresql-8.4 cartridge is added

    When I create a test table in postgres without dropping
    Then the test data will not be present in postgres
    And the additional test data will not be present in postgres

    When I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres


  @runtime_extended3
  @snapshot
  Scenario: Snapshot/Restore after removing/adding application
    Given I preserve the current snapshot
    Given the application is destroyed
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    When I create a test table in postgres without dropping
    Then the test data will not be present in postgres
    And the additional test data will not be present in postgres

    When I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application from a preserved snapshot
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

    Then all databases will have the correct ownership
