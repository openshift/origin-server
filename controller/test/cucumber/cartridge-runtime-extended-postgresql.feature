#@runtime_extended_other3
@runtime_extended3
Feature: Postgresql extended tests
  
  Scenario Outline: Use socket file to connect to database 
    Given a new <php_version> type application
    And I embed a <postgres_cart> cartridge into the application
    And the application is made publicly accessible

    When I select from the postgresql database using the socket file
    Then the select result from the postgresql database should be valid
    
    @fedora-only
    Scenarios: database cartridge scenarios - origin
      | postgres_cart  | php_version |
      | postgresql-9.2 | php-5.4     |

    @rhel-only
    Scenarios: database cartridge scenarios
      | postgres_cart  | php_version |
      | postgresql-8.4 | php-5.3     |