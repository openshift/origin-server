@runtime_extended
@runtime_extended3
@runtime_extended_other3
Feature: Cartridge Lifecycle Jenkins Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 jenkins-1.4 applications are created
    Then the applications should be accessible

  Scenario: Application Restarting
    Given an existing jenkins-1.4 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Change Namespace
    Given an existing jenkins-1.4 application
    When the application namespace is updated
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing jenkins-1.4 application
    And the application should be accessible
    When the application is destroyed
    Then the application should not be accessible
