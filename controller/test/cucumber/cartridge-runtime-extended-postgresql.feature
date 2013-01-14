@runtime_extended3
Feature: Postgresql extended tests
  
  Scenario: Use socket file to connect to database 
    Given a new php-5.3 type application
    And I embed a postgresql-8.4 cartridge into the application
    And the application is made publicly accessible

    When I select from the postgresql database using the socket file
    Then the select result from the postgresql database should be valid