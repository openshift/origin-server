@runtime
@runtime1
Feature: MongoDB Application Sub-Cartridge
  
  Scenario: Create Delete one application with a MongoDB database
    Given a new perl-5.10 type application
    
    When I embed a mongodb-2.2 cartridge into the application
    Then 1 process named mongod will be running
    And the embedded mongodb-2.2 cartridge directory will exist
    And the mongodb configuration file will exist
    And the mongodb database will exist
    And the embedded mongodb-2.2 cartridge control script will not exist
    And the mongodb admin user will have access

    When I stop the mongodb-2.2 cartridge
    Then 0 processes named mongod will be running

    When I start the mongodb-2.2 cartridge
    Then 1 process named mongod will be running

    When the application cartridge PIDs are tracked
    And I restart the mongodb-2.2 cartridge
    Then 1 process named mongod will be running
    And the tracked application cartridge PIDs should be changed

    When I destroy the application
    Then 0 processes named mongod will be running
    And the mongodb database will not exist
    And the mongodb configuration file will not exist
    And the embedded mongodb-2.2 cartridge directory will not exist
