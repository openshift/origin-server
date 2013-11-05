@cartridge_extended
@cartridge_extended3
Feature: Cartridge Lifecycle DIY Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 diy-0.1 applications are created
    Then the applications should be accessible
    Given an existing diy-0.1 application
    When the application is destroyed
    Then the application should not be accessible
