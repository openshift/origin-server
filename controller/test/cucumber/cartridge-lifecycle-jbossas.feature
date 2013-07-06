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
    Given an existing jbossas-7 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible
    When the application is restarted
    Then the application should be accessible
    When I tidy the application
    Then the application should be accessible
    When I snapshot the application
    Then the application should be accessible
    When a new file is added and pushed to the client-created application repo
    When I restore the application
    Then the application should be accessible
    And the new file will not be present in the gear app-root repo
    When the application is destroyed
    Then the application should not be accessible
