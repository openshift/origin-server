@runtime4
@fedora-19-only
Feature: MySQL Application Sub-Cartridge

  Scenario: Create Delete one application with a MySQL database
    Given a new mock-0.1 type application

    When I embed a mariadb-5.5 cartridge into the application
    Then a mysqld process will be running
    And the mariadb-5.5 cartridge instance directory will exist

    When I stop the mariadb-5.5 cartridge
    Then a mysqld process will not be running

    When I start the mariadb-5.5 cartridge
    Then a mysqld process will be running

    When I destroy the application
    Then a mysqld process will not be running
