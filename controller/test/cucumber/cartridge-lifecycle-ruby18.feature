@runtime
@runtime_extended1
@runtime_other4
@not-enterprise
@rhel-only
Feature: Cartridge Lifecycle Ruby Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 ruby-1.8 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing ruby-1.8 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing ruby-1.8 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing ruby-1.8 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing ruby-1.8 application
    When the application is destroyed
    Then the application should not be accessible
