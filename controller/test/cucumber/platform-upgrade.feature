@manipulates_cart_repo
@manipulates_gear_upgrade
@singleton
Feature: Cartridge upgrades
  Scenario: Upgrade from compatible version
    Given the expected version of the mock-0.1 cartridge is installed
    And a new client created mock-0.1 application
    And a compatible version of the mock-0.1 cartridge
    And the mock invocation markers are cleared
    And a gear level upgrade extension exists

    When the application is upgraded to the new cartridge versions
    Then the upgrade metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from a compatible upgrade should exist
    And the invocation markers from the gear upgrade should exist
    And the application should be accessible

  Scenario: Upgrade from incompatible version
    Given the expected version of the mock-0.1 cartridge is installed
    And a new client created mock-0.1 application
    And an incompatible version of the mock-0.1 cartridge
    And the mock invocation markers are cleared
    And a gear level upgrade extension exists

    When the application is upgraded to the new cartridge versions
    Then the upgrade metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from an incompatible upgrade should exist
    And the invocation markers from the gear upgrade should exist
    And the application should be accessible

  Scenario: Upgrade a node using containing failed apps
    Given the expected version of the mock-0.1 cartridge is installed
    And a new client created mock-0.1 application named mock1
    And a new client created mock-0.2 application named mock2
    And the mock invocation markers are cleared in mock1
    And the mock invocation markers are cleared in mock2
    And a rigged version of the mock-0.1 cartridge set to fail 2 times

    When existing oo-admin-upgrade output is archived
    And the gears on the node are upgraded with oo-admin-upgrade
    Then the mock cartridge version should not be updated in mock1
    And unprocessed ERB templates should exist in mock1
    And the invocation markers from an incompatible upgrade should not exist in mock1
    And the mock1 application should not be accessible

    And the upgrade metadata will be cleaned up in mock2
    And no unprocessed ERB templates should exist in mock2
    And the invocation markers from a incompatible upgrade should exist in mock2
    And the mock2 application should be accessible
    Then the mock cartridge version should be updated in mock2

    When the gears on the node are upgraded with oo-admin-upgrade
    Then no unprocessed ERB templates should exist in mock1
    And the invocation markers from an incompatible upgrade should exist in mock1
    And the mock1 application should be accessible
