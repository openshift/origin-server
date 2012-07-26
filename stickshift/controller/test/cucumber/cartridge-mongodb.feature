@runtime
@runtime1
Feature: MongoDB Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with a MongoDB database
    Given a new <type> type application
    
    When I embed a mongodb-2.0 cartridge into the application
    Then 1 process named mongod will be running
    And the embedded mongodb-2.0 cartridge directory will exist
    And the mongodb configuration file will exist
    And the mongodb database will exist
    And the embedded mongodb-2.0 cartridge control script named mongodb will exist
    And the mongodb admin user will have access

    When I stop the mongodb-2.0 cartridge
    Then 0 processes named mongod will be running

    When I start the mongodb-2.0 cartridge
    Then 1 process named mongod will be running

    When the application cartridge PIDs are tracked
    And I restart the mongodb-2.0 cartridge
    Then 1 process named mongod will be running
    And the tracked application cartridge PIDs should be changed

    When I destroy the application
    Then 0 processes named mongod will be running
    And the mongodb database will not exist
    And the embedded mongodb-2.0 cartridge control script named mongodb will not exist
    And the mongodb configuration file will not exist
    And the embedded mongodb-2.0 cartridge directory will not exist

  Scenarios: Create Delete Application With Database Scenarios
    |type|
    |php-5.3|
