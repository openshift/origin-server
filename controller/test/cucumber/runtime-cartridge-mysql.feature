@cartridge_extended2
@not-fedora-19
Feature: MySQL Application Sub-Cartridge

  Scenario: Create Delete one application with a MySQL 5.1 database
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

  Scenario: Create Delete one application with a MySQL 5.5 database
    Given a new mock-0.1 type application

    When I embed a mysql-5.5 cartridge into the application
    Then a mysqld process will be running
    And the mysql-5.5 cartridge instance directory will exist

    When I stop the mysql-5.5 cartridge
    Then a mysqld process will not be running

    When I start the mysql-5.5 cartridge
    Then a mysqld process will be running

    When I destroy the application
    Then a mysqld process will not be running
