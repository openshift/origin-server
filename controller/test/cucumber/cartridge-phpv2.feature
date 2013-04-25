@runtime_other1
Feature: V2 SDK PHP Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new php-5.3 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the php-5.3 cartridge private endpoints will be exposed
  And the php-5.3 PHP_VERSION env entry will exist
  When I destroy the application
  Then the application git repo will not exist
