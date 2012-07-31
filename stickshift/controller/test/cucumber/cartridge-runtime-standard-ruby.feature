@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  @runtime1
  Scenario Outline: Ruby cartridge checks
    Given a new <type> application, verify it using httpd

    Examples:
      | type     |
      | ruby-1.8 |
      | ruby-1.9 |
