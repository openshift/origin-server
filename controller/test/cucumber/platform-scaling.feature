@runtime_extended2
Feature: V2 Platform Scaling Tests

  Scenario: Scaling test for php
    Given a v2 default node
    And a new client created scalable php-5.3 application
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
