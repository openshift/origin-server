#@runtime_extended_other2
@runtime_extended
@runtime_extended2
@rhel-only
@jboss
Feature: Cartridge Lifecycle JBossEAP Verification Tests
  Scenario: Application Creation
    Given the libra client tools
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
    Given an existing jbosseap-6.0 application, verify it can be snapshotted and restored

  Scenario: Application Destroying
    Given an existing jbosseap-6.0 application
    When the application is destroyed
    Then the application should not be accessible
