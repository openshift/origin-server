@runtime_other
Feature: V2 SDK PHP Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new php type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the php cartridge private endpoints will be exposed
  And the php PHP_VERSION env entry will exist

  Scenario: Destroy application
  Given a v2 default node
  Given a new php type application
  When I destroy the application
  Then the application git repo will not exist
