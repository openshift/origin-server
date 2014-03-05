@cartridge_extended4
Feature: MySQL Application Sub-Cartridge

  Scenario Outline: Create Delete one application with a MySQL database
    Given a new mock-0.1 type application

    When I embed a <cart_name> cartridge into the application
    Then a mysqld process will be running
    And the <cart_name> cartridge instance directory will exist

    When I stop the <cart_name> cartridge
    Then a mysqld process will not be running

    When I start the <cart_name> cartridge
    Then a mysqld process will be running

    When I destroy the application
    Then a mysqld process will not be running

    Scenarios: MySQL versions
      | cart_name |
      | mysql-5.5 |
