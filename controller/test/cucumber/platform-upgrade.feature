@manipulates_cart_repo
@singleton
Feature: Cartridge upgrades
  Scenario: Upgrade from compatible version
    Given the expected version of the mock cartridge is installed
    And a new client created mock-0.1 application
    And a compatible version of the mock cartridge
    And the mock invocation markers are cleared

    When the application is upgraded to the new cartridge versions
    Then the upgrade metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from a compatible upgrade should exist
    And the application should be accessible

  Scenario: Upgrade from incompatible version
    Given the expected version of the mock cartridge is installed
    And a new client created mock-0.1 application
    And an incompatible version of the mock cartridge
    And the mock invocation markers are cleared

    When the application is upgraded to the new cartridge versions
    Then the upgrade metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from an incompatible upgrade should exist
    And the application should be accessible
