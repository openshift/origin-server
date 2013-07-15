@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle Jenkins Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jenkins-1.4 applications are created
    Then the applications should be accessible
    Given an existing jenkins-1.4 application
    And the application should be accessible
    When the application is restarted
    Then the application should be accessible
    When the application is destroyed
    Then the application should not be accessible
