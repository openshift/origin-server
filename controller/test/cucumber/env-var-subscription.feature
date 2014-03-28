@gear_singleton
@manipulates_cart_repo
Feature: Environment variable subscription

  Scenario: Complete set environment variables published when cartridge subscribes to all
    Given the 0.0.1 version of the mock-plugin-0.1 cartridge is installed
    And the 0.0.1 version of the mock-0.1 cartridge is installed
    And a version of the mock-0.1 cartridge with wildcard ENV subscription is installed
    And a version of the mock-plugin-0.1 cartridge with additional published ENV vars is installed
    And the broker cache is cleared
    And a new client created scalable mock-0.1 application 
    And the embedded mock-plugin-0.1 cartridge is added

    Then the mock-plugin application environment variable MOCK_PLUGIN_GARBAGE will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_GEAR_UUID will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_USERNAME will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_PASSWORD will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_HOST will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_PORT will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_URL will exist

  Scenario: Limited set of environment variables published when cartridge does not subscribe to all
    Given the 0.0.1 version of the mock-plugin-0.1 cartridge is installed
    And the 0.0.1 version of the mock-0.1 cartridge is installed
    And a version of the mock-0.1 cartridge without wildcard ENV subscription is installed
    And a version of the mock-plugin-0.1 cartridge with additional published ENV vars is installed
    And the broker cache is cleared
    And a new client created scalable mock-0.1 application
    And the embedded mock-plugin-0.1 cartridge is added

    Then the mock-plugin application environment variable MOCK_PLUGIN_GARBAGE will not exist
    And the mock-plugin application environment variable MOCK_PLUGIN_GEAR_UUID will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_USERNAME will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_PASSWORD will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_HOST will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_PORT will exist
    And the mock-plugin application environment variable MOCK_PLUGIN_DB_URL will exist
