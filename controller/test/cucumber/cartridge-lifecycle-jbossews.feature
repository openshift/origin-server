@runtime_extended
@runtime_extended2
@not-origin
Feature: Cartridge Lifecycle JBossEAP Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  jbossews-1.0   |
    
  Scenario Outline: Application Restarting
    Given an existing <type> application
    When the application is restarted
    Then the application should be accessible

  Scenarios: Application Restart Scenarios
    |      type     |
    |   jbossews-1.0   |
    
  Scenario Outline: Application Snapshot
    Given an existing <type> application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible

  Scenarios: Application Snapshot Scenarios
    |      type     |
    |   jbossews-1.0   |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   jbossews-1.0   |
