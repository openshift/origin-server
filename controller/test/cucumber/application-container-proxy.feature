@runtime
@runtime_extended3
Feature: Application Container Proxy gear retrieval

  Scenario Outline: Get gears with Broker auth tokens
    Given the libra client tools
    When 1 scalable <php_version> applications are created
    Then the app is returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | php_version |
      | php-5.5     |

  Scenario Outline: Get gears without Broker auth tokens
    Given the libra client tools
    When 1 <php_version> applications are created
    Then the app is not returned when fetching all gears using broker key auth
    When the applications are destroyed
    Then the applications should not be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | php_version |
      | php-5.5     |
