@broker_api
@broker_api2
Feature: cartridge types
  As an API client
  In order to do things with application templates
  I want to List and Show cartridge types without authenticating

  Scenario Outline: List cartridge types
    Given I accept "<format>"
    When I send an unauthenticated GET request to "/cartridges"
    Then the response should be "200"
    And the response should be a list of "cartridges"

    Scenarios:
    |format|
    |JSON  |