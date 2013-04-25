@runtime_extended
@runtime_extended1
@runtime_extended_other1
@rhel-only
Feature: Cartridge Lifecycle Python Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 python-2.6 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing python-2.6 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing python-2.6 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing python-2.6 application
    When the application is destroyed
    Then the application should not be accessible
