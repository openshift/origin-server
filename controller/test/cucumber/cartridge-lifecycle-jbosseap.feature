@runtime_extended
@runtime_extended2
@not-origin
Feature: Cartridge Lifecycle JBossEAP Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 jbosseap-6.0 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing jbosseap-6.0 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing jbosseap-6.0 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing jbosseap-6.0 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Snapshot
    Given an existing jbosseap-6.0 application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing jbosseap-6.0 application
    When the application is destroyed
    Then the application should not be accessible
