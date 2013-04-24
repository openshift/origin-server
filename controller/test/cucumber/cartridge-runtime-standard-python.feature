@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (Python)

  #@runtime_other4
  @runtime_extended2
  Scenario: Python cartridge checks
    Given a new python-2.6 application, verify it using httpd
