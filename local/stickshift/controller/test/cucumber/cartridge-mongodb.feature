@internals
@node
Feature: MongoDB Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with a MongoDB database
    Given an accepted node
    And a new guest account
    And a new <type> application
    When I configure a mongodb database
    Then the mongodb directory will exist
    And the mongodb configuration file will exist
    And the mongodb database will exist
    And the mongodb control script will exist
    And the mongodb daemon will be running
    And the mongodb admin user will have access

    When I stop the mongodb database
    Then the mongodb daemon will not be running
    And the mongodb daemon is stopped

    When I start the mongodb database
    Then the mongodb daemon will be running

    When I restart the mongodb database
    Then the mongodb daemon will be running
    And the mongodb daemon pid will be different

    When I deconfigure the mongodb database
    Then the mongodb daemon will not be running
    And the mongodb database will not exist
    And the mongodb control script will not exist
    And the mongodb configuration file will not exist
    And the mongodb directory will not exist

  Scenarios: Create Delete Application With Database Scenarios
    |type|
    |php|
