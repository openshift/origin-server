@runtime_extended_other1
@runtime
@not-fedora-19
Feature: cron Embedded Cartridge
  Scenario Outline: Add Remove cron to one application (RHEL/CentOS)
    #Given a php-5.3 application, verify addition and removal of cron
    Given a new <cart_name> type application
    And I embed a cron-1.4 cartridge into the application
    And cron is running

    Then the embedded cron-1.4 cartridge directory will exist
    And the embedded cron-1.4 cartridge subdirectory named log will exist
    And the embedded cron-1.4 cartridge subdirectory named run will exist
    And cron jobs will be enabled

    When I stop the cron-1.4 cartridge
    Then cron jobs will not be enabled
    And cron is stopped

    When I start the cron-1.4 cartridge
    Then cron jobs will be enabled
    And cron is running

    When I restart the cron-1.4 cartridge
    Then cron jobs will be enabled

    When I destroy the application
    Then cron is stopped
    And the embedded cron-1.4 cartridge directory will not exist
    And the embedded cron-1.4 cartridge subdirectory named log will not exist
    And the embedded cron-1.4 cartridge control script will not exist
    And the embedded cron-1.4 cartridge subdirectory named run will not exist

    @rhel-only
    Scenarios: RHEL scenarios
    | cart_name |
    | php-5.3   |
