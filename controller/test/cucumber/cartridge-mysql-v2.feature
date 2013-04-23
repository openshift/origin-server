@runtime_other
Feature: MySQL Application Sub-Cartridge
  
  Scenario: Create Delete one application with a MySQL database
    Given a v2 default node
    Given a new mock-0.1 type application
    
    When I embed a mysql-5.1 cartridge into the application
    Then a mysqld process will be running
    And the mysql-5.1 cartridge instance directory will exist
    
    When I stop the mysql-5.1 cartridge
    Then a mysqld process will not be running
    
    When I start the mysql-5.1 cartridge
    Then a mysqld process will be running
    
    When I destroy the application
    Then a mysqld process will not be running

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
