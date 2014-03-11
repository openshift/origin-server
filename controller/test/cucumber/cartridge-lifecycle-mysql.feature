@cartridge_extended4
Feature: MySQL Tests
  Scenario Outline: Snapshot/Restore an application with a MySQL database
    Given a new client created mock-0.1 application
    Given the embedded <cart_name> cartridge is added
    When I create a test table in mysql
    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql
    And the cartridge <cart_name> status should be running

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql
    And the cartridge <cart_name> status should be running

    When the application is stopped
    And I snapshot the application
    Then the cartridge <cart_name> status should be stopped

    When I restore the application
    Then the cartridge <cart_name> status should be stopped

    Scenarios: MySQL versions
      | cart_name |
      | mysql-5.1 |
      | mysql-5.5 |

  Scenario Outline: Snapshot/Restore a scalable application with a MySQL database
    Given a new client created scalable mock-0.1 application
    Given the embedded <cart_name> cartridge is added

    When I create a test table in mysql
    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When the embedded <cart_name> cartridge is removed
    And the embedded <cart_name> cartridge is added
    Then I can select from mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql

    Scenarios: MySQL versions
      | cart_name |
      | mysql-5.1 |

  Scenario Outline: Snapshot/Restore between applications with a MySQL database
    Given a new client created mock-0.1 application
    Given the embedded <cart_name> cartridge is added
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
    Given the embedded <cart_name> cartridge is added

    When I create a test table in mysql without dropping
    Then the test data will not be present in mysql
    And the additional test data will not be present in mysql

    When I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When I restore the application from a preserved snapshot
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql

    Scenarios: MySQL versions
      | cart_name |
      | mysql-5.1 |
