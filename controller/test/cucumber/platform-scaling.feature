@runtime_extended2
@not-rhel
@not-fedora
Feature: V2 Platform Scaling Tests

  Scenario Outline: Scaling test for php
    Given a v2 default node
    And a new client created scalable <cart_name> application
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

    @rhel-only
    Scenarios: RHEL scenarios
      | cart_name |
      | php-5.3   |

    @fedora-19-only
    Scenarios: RHEL scenarios
      | cart_name |
      | php-5.5   |
