@runtime
Feature: Cartridge Runtime Standard Checks (Node)

  @runtime1
  Scenario Outline: Create and Delete Application (Node)
    Given a new <type> application, verify create and delete using <proc_name>

    Examples:
      | type       | proc_name |
      | nodejs-0.6 | node      |

  @runtime2
  Scenario Outline: Start/stop/restart an application (Node)
    Given a new <type> application, verify start, stop, restart using <proc_name>

    Examples:
      | type       | proc_name |
      | nodejs-0.6 | node      |
