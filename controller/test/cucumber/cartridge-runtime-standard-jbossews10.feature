@runtime
@rhel-only
@jboss
Feature: Cartridge Runtime Standard Checks (JBoss EWS1.0)

  @runtime_extended_other2
  Scenario: JBoss EWS1.0 cartridge checks
    Given a new jbossews-1.0 application, verify it using java
