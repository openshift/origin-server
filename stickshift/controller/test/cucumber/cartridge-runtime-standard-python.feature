@runtime
Feature: Cartridge Runtime Standard Checks (Python)

  @runtime1
  Scenario Outline: Create and Delete Application (Python)
    Given a new <type> application, verify create and delete using <proc_name>

    Examples:
      | type       | proc_name |
      | python-2.6 | httpd     |

  @runtime2
  Scenario Outline: Start/stop/restart an application (Python)
    Given a new <type> application, verify start, stop, restart using <proc_name>

    Examples:
      | type       | proc_name |
      | python-2.6 | httpd     |
