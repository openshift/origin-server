@rhel-only
Feature: MySQL Application Sub-Cartridge
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    #Given a php-5.3 application, verify addition and removal of mysql
    Given a new php-5.3 type application

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

  Scenario: Use socket file to connect to database
    #Given a new php-5.3 application, verify using socket file to connect to database
    Given a new php-5.3 type application
    And I embed a mysql-5.1 cartridge into the application

    When the application is made publicly accessible
    Then I can select from the mysql database using the socket file
