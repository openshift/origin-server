@node
@node_extended3
Feature: Application Container Proxy gear retrieval

  Scenario Outline: Get gears with Broker auth tokens (scalable)
    Given the libra client tools
    When 1 scalable <php_version> applications are created
    Then the app is returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

  Scenario Outline: Get gears with Broker auth tokens (non-scalable)
    Given the libra client tools
    When 1 <php_version> applications are created
    Then the app is returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |
