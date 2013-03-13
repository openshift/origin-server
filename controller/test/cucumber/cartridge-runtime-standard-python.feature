@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (Python)

  #@runtime_other2
  @runtime2
  Scenario: Python cartridge checks
    Given a new python-2.6 application, verify it using httpd
