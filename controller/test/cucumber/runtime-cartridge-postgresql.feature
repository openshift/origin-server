@cartridge_extended3
Feature: Postgres Application Sub-Cartridge

  Scenario Outline: Create/Delete to application with a Postgres database
    Given a new mock-0.1 type application

    When I embed a postgresql-<postgres_version> cartridge into the application
    Then a postgres process will be running
    And the postgresql-<postgres_version> cartridge instance directory will exist

    When I stop the postgresql-<postgres_version> cartridge
    Then a postgres process will not be running

    When I start the postgresql-<postgres_version> cartridge
    Then a postgres process will be running

    When I destroy the application
    Then a postgres process will not be running

    Scenarios: RHEL
      | postgres_version |
      |       8.4        |
      |       9.2        |

  Scenario Outline: Connections and Snapshot/Restore a scalable application with a Postgres database
    Given a new client created scalable mock-0.1 application
    Given the embedded postgresql-<postgres_version> cartridge is added

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

    Given I use host to connect to the postgresql database as env with password

    When I create a test table in postgres
    And I insert test data into postgres
    Then the test data will be present in postgres

    When I snapshot the application
    And I insert additional test data into postgres
    Then the additional test data will be present in postgres
    And the cartridge postgresql-<postgres_version> status should be running

    When I restore the application
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres
    And the cartridge postgresql-<postgres_version> status should be running

    When the application is stopped
    And I snapshot the application
    Then the cartridge postgresql-<postgres_version> status should be stopped

    When I restore the application
    Then the cartridge postgresql-<postgres_version> status should be stopped

    Scenarios: RHEL
      | postgres_version |
      |       9.2        |

  @cartridge_extended3
  Scenario Outline: Connections and Snapshot/Restore after removing/adding application
    Given a new client created mock-0.1 application
    Given the embedded postgresql-<postgres_version> cartridge is added

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

    When I create a test database in postgres

    When I create a test table in postgres
    When I insert test data into postgres
    Then the test data will be present in postgres

    When I snapshot the application
    And I insert additional test data into postgres
    Then the additional test data will be present in postgres

    Given I preserve the current snapshot
    Given the application is destroyed
    Given a new client created mock-0.1 application
    Given the embedded postgresql-<postgres_version> cartridge is added

    When I create a test table in postgres without dropping
    Then the test data will not be present in postgres
    And the additional test data will not be present in postgres

    When I insert additional test data into postgres
    Then the additional test data will be present in postgres

    When I restore the application from a preserved snapshot
    Then the test data will be present in postgres
    And the additional test data will not be present in postgres

    Then all databases will have the correct ownership

    Scenarios: RHEL
      | postgres_version |
      |       9.2        |
