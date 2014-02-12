@cartridge_extended3
Feature: DIY Cartridge
  Scenario: Add cartridge
    Given a new diy-0.1 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the diy-0.1 cartridge private endpoints will be exposed
    When I destroy the application
    Then the application git repo will not exist
