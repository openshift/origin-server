@node
@cartridge_extended3
@jboss
@not-enterprise
Feature: SwitchYard Application Sub-Cartridge
  Scenario: Create Delete one EAP application with embedded SwitchYard
    Given a new jbosseap-6 type application

    When I embed a switchyard-0 cartridge into the application
    Then the eap module configuration file will exist

    When I remove the switchyard-0 cartridge from the application
    Then the eap module configuration file will not exist

    When I destroy the application

  Scenario: Create Delete one Non-JBoss application with embedded SwitchYard
    Given a new mock-0.1 type application

    When I fail to embed a switchyard-0 cartridge into the application

    When I destroy the application
