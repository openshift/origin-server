@runtime
@rhel-only
@jboss
Feature: Cartridge Runtime Standard Checks (JBoss EWS2.0)

  #@runtime_other4
  @runtime2
  Scenario: JBoss EWS2.0 cartridge checks
    Given a new jbossews-2.0 application, verify it using java
