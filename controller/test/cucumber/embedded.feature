@runtime_extended
@runtime_extended3
Feature: Embedded Cartridge Verification Tests

  Scenario: Embedded Usage
    Given the libra client tools
    And an accepted node
    When 1 php-5.3 applications are created
    Then the applications should be accessible

    Given an existing php-5.3 application without an embedded cartridge
    When the embedded mysql-5.1 cartridge is added
    And the embedded phpmyadmin-3.4 cartridge is added
    Then the application should be accessible
    When the application uses mysql
    Then the application should be accessible
    And the mysql response is successful
    When the embedded phpmyadmin-3.4 cartridge is removed
    And the embedded mysql-5.1 cartridge is removed
    Then the application should be accessible

    When the embedded mongodb-2.2 cartridge is added
    And the embedded cron-1.4 cartridge is added
    Then the application should be accessible
    And the embedded mongodb-2.2 cartridge is removed
    And the embedded cron-1.4 cartridge is removed
    Then the application should be accessible

    When the application is destroyed
    Then the application should not be accessible
