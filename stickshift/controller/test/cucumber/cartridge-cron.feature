@internals
@node
Feature: cron Embedded Cartridge

  Scenario Outline: Add Remove cron to one application
    Given an accepted node
    And a new guest account
    And a new <type> application
    When I configure cron
    Then the cron directory will exist
    And the cron control script will exist
    And the cron log directory will exist
    And the cron run directory will exist
    And cron jobs will be enabled
    When I deconfigure cron
    Then the cron directory will not exist
    And the cron control script will not exist
    And the cron log directory will not exist
    And the cron run directory will not exist
    And cron jobs will not be enabled

  Scenarios: Add Remove cron to one Application Scenarios
    |type|
    |php|

  Scenario Outline: Stop Start Restart cron
    Given an accepted node
    And a new guest account
    And a new <type> application
    And a new cron
    And cron is running
    When I stop cron
    Then cron jobs will not be enabled
    And cron is stopped
    When I start cron
    Then cron jobs will be enabled
    And cron is running
    When I restart cron
    Then cron jobs will be enabled

  Scenarios: Stop Start Restart cron scenarios
    |type|
    |php|
