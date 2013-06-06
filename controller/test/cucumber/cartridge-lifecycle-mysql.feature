@runtime_extended1
@not-fedora-19
Feature: MySQL Tests
  Background:
    Given a v2 default node

  Scenario: Snapshot/Restore an application with a MySQL database
    Given a new client created mock-0.1 application
    Given the embedded mysql-5.1 cartridge is added
    When I create a test table in mysql
    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql

  Scenario: Snapshot/Restore a scalable application with a MySQL database
    Given a new client created scalable mock-0.1 application
    Given the embedded mysql-5.1 cartridge is added
    When I create a test table in mysql
    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When the embedded mysql-5.1 cartridge is removed
    And the embedded mysql-5.1 cartridge is added
    Then I can select from mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql

  Scenario: Snapshot/Restore between applications with a MySQL database
    Given a new client created mock-0.1 application
    Given the embedded mysql-5.1 cartridge is added
    When I create a test database in mysql

    When I create a test table in mysql
    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    Given I preserve the current snapshot
    Given the application is destroyed
    Given a new client created mock-0.1 application
    Given the embedded mysql-5.1 cartridge is added

    When I create a test table in mysql without dropping
    Then the test data will not be present in mysql
    And the additional test data will not be present in mysql

    When I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When I restore the application from a preserved snapshot
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql
