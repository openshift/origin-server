@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (JBoss EAP)

  @runtime2
  Scenario: JBoss EAP cartridge checks
    Given a new jbosseap-6.0 application, verify it using java
