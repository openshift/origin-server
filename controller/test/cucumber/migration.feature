@manipulates_cart_repo
@singleton
Feature: Cartridge migrations
  Scenario: Migration from compatible version
    Given the expected version of the mock cartridge is installed
    And a new client created mock-0.1 application
    And a compatible version of the mock cartridge
    And the mock invocation markers are cleared

    When the application is migrated to the new cartridge versions
    Then the migration metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from a compatible migration should exist
    And the application should be accessible

  Scenario: Migration from incompatible version
    Given the expected version of the mock cartridge is installed
    And a new client created mock-0.1 application
    And an incompatible version of the mock cartridge
    And the mock invocation markers are cleared

    When the application is migrated to the new cartridge versions
    Then the migration metadata will be cleaned up
    And the mock cartridge version should be updated
    And no unprocessed ERB templates should exist
    And the invocation markers from an incompatible migration should exist
    And the application should be accessible
