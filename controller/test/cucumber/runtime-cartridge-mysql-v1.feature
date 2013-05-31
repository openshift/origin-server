@runtime
@runtime_extended_other3
Feature: MySQL Application Sub-Cartridge

  @rhel-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.3 application, verify addition and removal of mysql

  @fedora-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.4 application, verify addition and removal of mysql

  
  @rhel-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.3 application, verify using socket file to connect to database
  
  @fedora-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.4 application, verify using socket file to connect to database
