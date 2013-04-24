#@runtime_extended_other3
@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle DIY Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 diy-0.1 applications are created
    Then the applications should be accessible

  Scenario: Application Destroying
    Given an existing diy-0.1 application
    When the application is destroyed
    Then the application should not be accessible
