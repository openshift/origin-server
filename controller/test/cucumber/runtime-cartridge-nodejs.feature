@runtime_extended3
@cartridge_v2_nodejs
@not-enterprise
Feature: V2 SDK Node.js Cartridge

  Scenario: Add cartridge
    Given a v2 default node
    Given a new nodejs type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the nodejs cartridge private endpoints will be exposed
    And the nodejs NODEJS_DIR env entry will exist
    And the nodejs NODEJS_LOG_DIR env entry will exist
    When I destroy the application
    Then the application git repo will not exist

  Scenario: Destroy application
    Given a v2 default node
    Given a new nodejs type application
    When I destroy the application
    Then the application git repo will not exist