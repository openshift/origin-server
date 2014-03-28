@cartridge_extended1
@jboss
@jbossas
@not-enterprise
Feature: JBossAS Cartridge

  Scenario: Add cartridge
    Given a new jbossas-7 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the jbossas-7 cartridge private endpoints will be exposed
    And the jbossas-7 JBOSSAS_DIR env entry will exist
    And the jbossas-7 JBOSSAS_VERSION env entry will exist
    When I embed a switchyard-0 cartridge into the application
    Then the as module configuration file will exist
    When I remove the switchyard-0 cartridge from the application
    Then the eap module configuration file will not exist
    When I destroy the application
    Then the application git repo will not exist