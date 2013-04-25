@runtime_other4
Feature: V2 Platform SSH Tests
  Scenario: Platform SSH for web proxy cartridge
    Given a v2 default node
    And a new client created scalable mock-0.1 application

    When the minimum scaling parameter is set to 2
    And a new file is added and pushed to the client-created application repo
    Then the new file will be present in the secondary gear app-root repo
    