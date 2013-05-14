@runtime_extended_other2
@runtime_extended
@runtime_extended2
@not-enterprise
@jboss
@jbossas

Feature: Cartridge Lifecycle JBossAS Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbossas-7 applications are created
    Then the applications should be accessible
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible
    When the application is restarted
    Then the application should be accessible
    When I tidy the application
    Then the application should be accessible
    Given an existing jbossas-7 application, verify it can be snapshotted and restored
    When the application is destroyed
    Then the application should not be accessible
