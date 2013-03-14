@runtime
Feature: Cartridge Runtime Standard Checks (PHP)

  #@runtime_other2
  @runtime2
  @rhel-only
  Scenario Outline: PHP cartridge checks
    Given a new php-5.3 application, verify it using httpd
    
  @runtime2
  @fedora-only
  Scenario Outline: PHP cartridge checks
    Given a new php-5.4 application, verify it using httpd
