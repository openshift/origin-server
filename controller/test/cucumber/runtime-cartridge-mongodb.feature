@runtime_extended1
@not-enterprise
Feature: MongoDB Application Sub-Cartridge
  
  Scenario: Create Delete one application with a MongoDB database
    Given a new mock-0.1 type application
    
    When I embed a mongodb-2.2 cartridge into the application
    Then a mongod process will be running
    And the mongodb-2.2 cartridge instance directory will exist
    
    When I stop the mongodb-2.2 cartridge
    Then a mongod process will not be running
    
    When I start the mongodb-2.2 cartridge
    Then a mongod process will be running
    
    When I destroy the application
    Then a mongod process will not be running
