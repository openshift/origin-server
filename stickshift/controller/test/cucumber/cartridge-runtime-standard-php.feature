@runtime
Feature: Cartridge Runtime Standard Checks (PHP)

  @runtime1
  Scenario Outline: Create and Delete Application (PHP)
    Given a new <type> application, verify create and delete using httpd

    Examples:
      | type      |
      | php-5.3   |

  @runtime2
  Scenario Outline: Start/stop/restart an application (PHP)
    Given a new <type> application, verify start, stop, restart using httpd

    Examples:
      | type      |
      | php-5.3   |
