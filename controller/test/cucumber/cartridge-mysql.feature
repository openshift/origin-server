#@runtime_other4
@runtime
@runtime4
Feature: MySQL Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with a MySQL database
    Given a new <php_version> type application
    
    When I embed a mysql-5.1 cartridge into the application
    Then a mysqld process will be running
    And the embedded mysql-5.1 cartridge directory will exist
    And the mysql configuration file will exist
    And the mysql database will exist
    And the mysql admin user will have access
    
    When I stop the mysql-5.1 cartridge
    Then a mysqld process will not be running
    
    When I start the mysql-5.1 cartridge
    Then a mysqld process will be running
    
    When the application cartridge PIDs are tracked
    And I restart the mysql-5.1 cartridge
    Then a mysqld process will be running
    And the tracked application cartridge PIDs should be changed
    
    When I destroy the application
    Then a mysqld process will not be running
    And the mysql database will not exist
    And the mysql configuration file will not exist
    And the embedded mysql-5.1 cartridge directory will not exist
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |
