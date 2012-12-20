@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle Jenkins Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  jenkins-1.4 |
    
  Scenario Outline: Application Restarting
    Given an existing <type> application
    When the application is restarted
    Then the application should be accessible

  Scenarios: Application Restart Scenarios
    |      type     |
    |   jenkins-1.4 |
    
  Scenario Outline: Application Change Namespace
    Given an existing <type> application
    When the application namespace is updated
    Then the application should be accessible

  Scenarios: Application Change Namespace Scenarios
    |      type     |
    |   jenkins-1.4 |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    And the application should be accessible
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   jenkins-1.4 |
