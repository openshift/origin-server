@runtime_other4
@postgres
@v2
Feature: Postgres Application Sub-Cartridge
  Background:
    Given a v2 default node

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

  Scenario: Database connections
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    # using psql wrapper
    # VALID
    Given I use the helper to connect to the postgresql database
    Then I should be able to query the postgresql database

    # postgres, socket
    # VALID
    Given I use socket to connect to the postgresql database as postgres
    Then I should be able to query the postgresql database

    # postgres, TCP
    # INVALID
    Given I use host to connect to the postgresql database as postgres
    Then I should not be able to query the postgresql database

    # ENV user, socket
    # VALID
    Given I use socket to connect to the postgresql database as env
    Then I should be able to query the postgresql database

    # ENV user, tcp without credentials
    # INVALID
    Given I use host to connect to the postgresql database as env
    Then I should not be able to query the postgresql database

    # ENV user, tcp with PGPASSFILE
    # VALID
    Given I use host to connect to the postgresql database as env with passfile
    Then I should be able to query the postgresql database

  Scenario: Scaled Database connections
    Given a new client created scalable mock-0.1 application
    Given the minimum scaling parameter is set to 2
    Given the embedded postgresql-8.4 cartridge is added

    # using psql wrapper
    # VALID
    # TODO: Blocked by https://bugzilla.redhat.com/show_bug.cgi?id=955849
    # This is not a critical test if the others pass
    #Given I use the helper to connect to the postgresql database
    #Then I should be able to query the postgresql database

    # ENV user, tcp without credentials
    # INVALID
    Given I use host to connect to the postgresql database as env
    Then I should not be able to query the postgresql database

    # ENV user, tcp with password
    # VALID
    Given I use host to connect to the postgresql database as env with password
    Then I should be able to query the postgresql database

  Scenario: Tidy Database
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    When I add debug data to the log file
    Then the debug data should exist in the log file

    When I tidy the application
    Then the debug data should not exist in the log file

  Scenario: Reload Database
    Given a new client created mock-0.1 application
    Given the embedded postgresql-8.4 cartridge is added

    Given I use host to connect to the postgresql database as env with password
    Then I should be able to query the postgresql database

    When I replace md5 authentication with reject in the configuration file
    And I reload the application
    Then I should not be able to query the postgresql database

    When I replace reject authentication with md5 in the configuration file
    And I reload the application
    Then I should be able to query the postgresql database
