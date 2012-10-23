@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle DIY Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation diy Scenarios
    | app_count |     type     |
    |     1     |  diy-0.1     |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   diy-0.1     |
