Feature: MySQL Application Sub-Cartridge
  @runtime
  @runtime_other1
  @rhel-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.3 application, verify addition and removal of mysql
  
  @runtime
  @runtime_other1
  @fedora-only
  Scenario: Create Delete one application with a MySQL database (RHEL/CentOS)
    Given a php-5.4 application, verify addition and removal of mysql

  @runtime_extended3
  @runtime_extended_other3
  @rhel-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.3 application, verify using socket file to connect to database
  
  @runtime_extended3
  @runtime_extended_other3
  @fedora-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.4 application, verify using socket file to connect to database
