@cartridge_extended3
@not-enterprise
Feature: MongoDB Application Sub-Cartridge

  Scenario: Create Delete one application with a MongoDB database
    Given a new mock-0.1 type application

    When I embed a mongodb-2.4 cartridge into the application
    Then a mongod process will be running
    And the mongodb-2.4 cartridge instance directory will exist

    When I stop the mongodb-2.4 cartridge
    Then a mongod process will not be running

    When I start the mongodb-2.4 cartridge
    Then a mongod process will be running

    And an agent settings.py file is created
    And I embed a 10gen-mms-agent-0.1 cartridge into the application

    Then 1 process named python will be running
    And the embedded 10gen-mms-agent-0.1 cartridge log files will exist

    When I stop the 10gen-mms-agent-0.1 cartridge
    Then 0 processes named python will be running

    When I start the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I restart the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I destroy the application
    Then 0 processes named python will be running
    And a mongod process will not be running
    And the embedded 10gen-mms-agent-0.1 cartridge log files will not exist