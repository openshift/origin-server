@runtime
Feature: Cartridge Runtime Standard Checks (PHP)

  @runtime2
  Scenario Outline: PHP cartridge checks
    Given a new <php_version> application, verify it using httpd
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |
