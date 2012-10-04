@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  @runtime1
  Scenario Outline: Ruby cartridge checks on ruby-1.8
    Given a new <type> application, verify it using httpd

    Scenarios:
      | type     |
      | ruby-1.8 |

  @runtime1
  @not-origin
  Scenario Outline: Ruby cartridge checks on ruby-1.9
    Given a new <type> application, verify it using httpd

    Scenarios:
      | type     |
      | ruby-1.9 |
