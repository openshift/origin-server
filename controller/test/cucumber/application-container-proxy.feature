@node
@node_extended3
Feature: Application Container Proxy gear retrieval

  Scenario Outline: Get gears with Broker auth tokens (scalable)
    Given the libra client tools
    When 1 scalable <cart_version> applications are created
    Then the app is returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    Scenarios: Cart versions
      | cart_version |
      | mock-0.1    |

  Scenario Outline: Get gears with Broker auth tokens (non-scalable)
    Given the libra client tools
    When 1 <cart_version> applications are created
    Then the app is returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    Scenarios: Cart versions
      | cart_version |
      | mock-0.1    |
