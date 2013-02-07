@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (JBoss AS)

  @runtime2
  Scenario: JBoss AS cartridge checks
    Given a new jbossas-7 application, verify it using java
