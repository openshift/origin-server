@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  #@runtime_other1
  @runtime1
  Scenario Outline: Ruby cartridge checks
    Given a new <ruby_version> application, verify it using httpd

    @rhel-only
    Scenarios:
      | ruby_version |
      | ruby-1.8     |

    Scenarios:
      | ruby_version |
      | ruby-1.9     |      