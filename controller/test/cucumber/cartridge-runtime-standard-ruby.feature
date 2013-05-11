@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  @runtime_other4
  @rhel-only
  Scenario: Ruby cartridge checks (RHEL/CentOS)
    Given a new ruby-1.8 application, verify it using httpd

  @runtime_other4
  Scenario: Ruby cartridge checks (RHEL/CentOS)
    Given a new ruby-1.9 application, verify it using httpd
