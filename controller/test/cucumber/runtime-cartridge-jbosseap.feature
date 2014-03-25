@cartridge_extended2
@jboss
@jbosseap
Feature: JBossEAP Cartridge

  Scenario: Add cartridge
    Given a new jbosseap-6 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the jbosseap-6 cartridge private endpoints will be exposed
    And the jbosseap-6 JBOSSEAP_DIR env entry will exist
    And the jbosseap-6 JBOSSEAP_VERSION env entry will exist
    When I destroy the application
    Then the application git repo will not exist


