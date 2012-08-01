@runtime
Feature: Cartridge Runtime Standard Checks (Perl)

  @runtime1
  Scenario Outline: Create and Delete Application (Perl)
    Given a new <type> application, verify create and delete using httpd

    Examples:
      | type      |
      | perl-5.10 |

  @runtime2
  Scenario Outline: Start/stop/restart an application (Perl)
    Given a new <type> application, verify start, stop, restart using httpd

    Examples:
      | type      |
      | perl-5.10 |
