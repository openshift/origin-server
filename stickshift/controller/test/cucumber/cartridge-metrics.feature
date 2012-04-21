@internals
@node
Feature: metrics Embedded Cartridge

  Scenario Outline: Add Remove metrics to one application
    Given an accepted node
    And a new guest account
    And a new <type> application
    When I configure metrics
    Then a metrics http proxy file will exist
    And a metrics httpd will be running
    And the metrics directory will exist
    And metrics log files will exist
    And the metrics control script will exist
    When I deconfigure metrics
    Then a metrics http proxy file will not exist
    And a metrics httpd will not be running
    And the metrics directory will not exist
    And metrics log files will not exist
    And the metrics control script will not exist

  Scenarios: Add Remove Metrics to one Application Scenarios
    |type|
    |php|

  Scenario Outline: Stop Start Restart Metrics
    Given an accepted node
    And a new guest account
    And a new <type> application
    And a new metrics
    And metrics is running
    When I stop metrics
    Then a metrics httpd will not be running
    And metrics is stopped
    When I start metrics
    Then a metrics httpd will be running
    And metrics is running
    When I restart metrics
    Then a metrics httpd will be running

  Scenarios: Stop Start Restart Metrics scenarios
    |type|
    |php|
