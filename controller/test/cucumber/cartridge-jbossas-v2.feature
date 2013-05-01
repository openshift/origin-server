@runtime_other4
Feature: V2 SDK JBossAS Cartridge

  Scenario: Add cartridge
    Given a v2 default node
    Given a new jbossas-7 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the jbossas-7 cartridge private endpoints will be exposed
    And the jbossas-7 JBOSSAS_DIR env entry will exist
    And the jbossas-7 JBOSSAS_LOG_DIR env entry will exist
    And the jbossas-7 JBOSSAS_VERSION env entry will exist

  Scenario: Destroy application
    Given a v2 default node
    Given a new jbossas-7 type application
    When I destroy the application
    Then the application git repo will not exist


