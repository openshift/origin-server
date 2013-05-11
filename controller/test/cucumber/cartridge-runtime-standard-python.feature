@runtime
@rhel-only
@runtime_extended_other2
Feature: Cartridge Runtime Standard Checks (Python)

  Scenario: Python cartridge checks
    Given a new python-2.6 application, verify it using httpd
