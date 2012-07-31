@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  @runtime1
  Scenario Outline: Create and Delete Application (Ruby)
    Given a new <type> application, verify create and delete using httpd

    Examples:
      | type     |
      | ruby-1.8 |
      | ruby-1.9 |

  @runtime2
  Scenario Outline: Start/stop/restart an application (Ruby)
    Given a new <type> application, verify start, stop, restart using httpd

    Examples:
      | type     |
      | ruby-1.8 |
      | ruby-1.9 |
