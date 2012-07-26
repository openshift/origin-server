@runtime
@runtime1
Feature: cron Embedded Cartridge

  Scenario Outline: Add Remove cron to one application
    Given a new <type> type application
    And I embed a cron-1.4 cartridge into the application
    And cron is running

    Then the embedded cron-1.4 cartridge directory will exist
    And the embedded cron-1.4 cartridge subdirectory named log will exist
    And the embedded cron-1.4 cartridge control script named cron will exist
    And the embedded cron-1.4 cartridge subdirectory named run will exist
    And cron jobs will be enabled

    When I destroy the application
    Then cron is stopped
    And the embedded cron-1.4 cartridge directory will not exist
    And the embedded cron-1.4 cartridge subdirectory named log will not exist
    And the embedded cron-1.4 cartridge control script named cron will not exist
    And the embedded cron-1.4 cartridge subdirectory named run will not exist

  Scenarios: Add Remove cron to one Application Scenarios
    |type|
    |php-5.3|

  Scenario Outline: Stop Start Restart cron
    Given a new <type> type application
    And I embed a cron-1.4 cartridge into the application
    And cron is running

    When I stop the cron-1.4 cartridge
    Then cron jobs will not be enabled
    And cron is stopped
    When I start the cron-1.4 cartridge
    Then cron jobs will be enabled
    And cron is running
    When I restart the cron-1.4 cartridge
    Then cron jobs will be enabled

  Scenarios: Stop Start Restart cron scenarios
    |type|
    |php-5.3|
