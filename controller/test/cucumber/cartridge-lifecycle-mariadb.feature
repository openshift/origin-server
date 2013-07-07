@runtime_extended1
@fedora-19-only
@not-rhel
Feature: MariaDB Tests
  Scenario: MariaDB in a scalable application
    Given a new client created scalable mock-0.1 application

    When the embedded mariadb-5.5 cartridge is added
    Then I can select from mysql

    When I create a test table in mysql
    And  I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When the embedded mariadb-5.5 cartridge is removed
    And the embedded mariadb-5.5 cartridge is added
    Then I can select from mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql

  Scenario: Snapshot/Restore an application with a MariaDB database
    Given a new client created mock-0.1 application

    When the embedded mariadb-5.5 cartridge is added
    Then I can select from mysql

    When I create a test table in mysql
    And I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql
