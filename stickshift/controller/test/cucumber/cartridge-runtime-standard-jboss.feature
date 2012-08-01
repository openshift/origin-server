@runtime
Feature: Cartridge Runtime Standard Checks (JBoss)

  @runtime1
  Scenario Outline: Create and Delete Application (JBoss)
    Given a new <type> application, verify create and delete using java

    Examples:
      | type         |
      | jbossas-7    |
      | jbosseap-6.0 |

  @runtime2
  Scenario Outline: Start/stop/restart an application (JBoss)
    Given a new <type> application, verify start, stop, restart using java

    Examples:
      | type         |
      | jbossas-7    |
      | jbosseap-6.0 |
