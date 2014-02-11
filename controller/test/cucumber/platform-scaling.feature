@gear_extended
@gear_extended3
Feature: Platform Scaling Tests
  Scenario: Basic scaling test for mock
    And a new client created scalable mock-0.1 application
    Then the application should be accessible
    Then the haproxy-status page will be responding
    And the gear members will be UP
    And 1 gears will be in the cluster
    When the minimum scaling parameter is set to 2
    Then the application should be accessible
    Then the haproxy-status page will be responding
    And the gear members will be UP
    And 2 gears will be in the cluster
    When the application is destroyed
    Then the application should not be accessible
