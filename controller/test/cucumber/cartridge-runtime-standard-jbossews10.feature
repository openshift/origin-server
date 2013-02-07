@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (JBoss EWS2.0)

  @runtime2
  Scenario: JBoss EWS1.0 cartridge checks
    Given a new jbossews-1.0 application, verify it using java
