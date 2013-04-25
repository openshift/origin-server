@runtime_extended_other1
Feature: MySQL Application Sub-Cartridge
  Scenario: Snapshot/Restore an application with a MySQL database
    Given a v2 default node
    Given a new client created mock-0.1 application

    When the embedded mysql-5.1 cartridge is added
    Then I can select from mysql

    When I insert test data into mysql
    Then the test data will be present in mysql

    When I snapshot the application
    And I insert additional test data into mysql
    Then the additional test data will be present in mysql

    When I restore the application
    Then the test data will be present in mysql
    And the additional test data will not be present in mysql