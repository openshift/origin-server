@runtime_extended_other2
@runtime_extended
@rhel-only
@not-fedora-19
@jboss
@jbossews1

Feature: Cartridge Lifecycle JBossEWS1.0 Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbossews-1.0 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing jbossews-1.0 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing jbossews-1.0 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing jbossews-1.0 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Snapshot
    Given an existing jbossews-1.0 application, verify it can be snapshotted and restored

  Scenario: Application Destroying
    Given an existing jbossews-1.0 application
    When the application is destroyed
    Then the application should not be accessible
