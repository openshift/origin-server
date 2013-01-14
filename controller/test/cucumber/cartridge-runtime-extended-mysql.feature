@runtime_extended3
Feature: Mysql extended tests
  
  Scenario: Use socket file to connect to database 
    Given a new php-5.3 type application
    And I embed a mysql-5.1 cartridge into the application
    And the application is made publicly accessible

    When I select from the mysql database using the socket file
    Then the select result from the mysql database should be valid