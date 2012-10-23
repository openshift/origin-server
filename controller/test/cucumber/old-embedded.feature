@rhc_extended
Feature: Embedded Cartridge Verification Tests OLD
  Scenario: MySQL Embedded Usage
    Given the libra client tools
    And an accepted node
    When 1 php-5.3 applications are created OLD
    Then the applications should be accessible
    Given an existing php-5.3 application without an embedded cartridge
    When the embedded mysql-5.1 cartridge is added OLD
    Then the application should be accessible
    When the embedded mysql-5.1 cartridge is removed OLD
    Then the application should be accessible
    When the application is destroyed OLD
    Then the application should not be accessible
