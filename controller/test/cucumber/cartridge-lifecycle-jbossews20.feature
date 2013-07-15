@runtime_extended2
@runtime_extended
@rhel-only
@not-fedora-19
@jboss
@jbossews2

Feature: Cartridge Lifecycle JBossEWS2.0 Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbossews-2.0 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing jbossews-2.0 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing jbossews-2.0 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing jbossews-2.0 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing jbossews-2.0 application
    When the application is destroyed
    Then the application should not be accessible
