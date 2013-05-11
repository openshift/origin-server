@runtime
@runtime_other1
Feature: MySQL Application Sub-Cartridge
  @rhel-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.3 application, verify addition and removal of mysql
    
  @fedora-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.4 application, verify addition and removal of mysql
