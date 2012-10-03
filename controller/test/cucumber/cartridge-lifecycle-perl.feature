@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle Perl Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  perl-5.10   |

  Scenario Outline: Application Modification
    Given an existing <type> application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenarios: Application Modification Scenarios
    |      type     |
    |   perl-5.10   |

  Scenario Outline: Application Restarting
    Given an existing <type> application
    When the application is restarted
    Then the application should be accessible

  Scenarios: Application Restart Scenarios
    |      type     |
    |   perl-5.10   |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   perl-5.10   |
