@runtime
@rhel-only
@jboss
Feature: Cartridge Runtime Standard Checks (JBoss EAP)

  #@runtime_other4
  @runtime2
  Scenario: JBoss EAP cartridge checks
    Given a new jbosseap-6.0 application, verify it using java
