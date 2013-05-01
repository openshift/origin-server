@runtime_other4
Feature: V2 SDK JBossEAP Cartridge

  Scenario: Add cartridge
    Given a v2 default node
    Given a new jbosseap-6.0 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the jbosseap-6.0 cartridge private endpoints will be exposed
    And the jbosseap-6.0 JBOSSEAP_DIR env entry will exist
    And the jbosseap-6.0 JBOSSEAP_LOG_DIR env entry will exist
    And the jbosseap-6.0 JBOSSEAP_VERSION env entry will exist

  Scenario: Destroy application
    Given a v2 default node
    Given a new jbosseap-6.0 type application
    When I destroy the application
    Then the application git repo will not exist


