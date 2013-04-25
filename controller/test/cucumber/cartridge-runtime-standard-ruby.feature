@runtime
Feature: Cartridge Runtime Standard Checks (Ruby)

  #@runtime_other4
  @runtime1
  @rhel-only
  Scenario: Ruby cartridge checks (RHEL/CentOS)
    Given a new ruby-1.8 application, verify it using httpd

  @runtime1
  Scenario: Ruby cartridge checks (RHEL/CentOS)
    Given a new ruby-1.9 application, verify it using httpd
