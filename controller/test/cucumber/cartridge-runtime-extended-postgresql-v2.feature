@runtime_extended_other3
@postgres
@v2
Feature: Postgresql extended tests
  Background:
    Given a v2 default node

  Scenario: Snapshot/Restore an application with a Postgres database
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    When I create a test table in postgres
    And I insert test data into postgres
    Then the test data will be present in postgres

    When I snapshot the application
    And I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

  Scenario: Snapshot/Restore a scalable application with a Postgres database
    Given a new client created scalable mock-0.1 application
    Given the minimum scaling parameter is set to 2
    Given the embedded postgresql-8.4 cartridge is added
    Given I use host to connect to the postgresql database as env with password

    When I create a test table in postgres
    And I insert test data into postgres
    Then the test data will be present in postgres

    When I snapshot the application
    And I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

  Scenario: Snapshot/Restore after removing/adding Postgres
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    When I create a test table in postgres
    When I insert test data into postgres
    Then the test data will be present in postgres

    When I snapshot the application
    And I insert additional test data into postgres
    Then the additional test data will be present in postgres

    Given the embedded postgresql-8.4 cartridge is removed

    When the embedded postgresql-8.4 cartridge is added
    And I create a test table in postgres without dropping
    Then the test data will not be present in postgres
    And the additional test data will not be present in postgres

    When I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres
