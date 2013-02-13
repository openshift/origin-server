@runtime
Feature: V2 SDK Mock Cartridge

  Scenario: Add cartridge
  Given a new mock type application
  Then the mock setup_version marker should exist
  And the mock setup_failure marker should not exist
  And the mock control_start marker should exist

  #Scenario: Delete cartridge