#@runtime_extended_other3
@runtime_extended3
Feature: Mysql extended tests
  @rhel-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.3 application, verify using socket file to connect to database
    
  @fedora-only
  Scenario: Use socket file to connect to database 
    Given a new php-5.4 application, verify using socket file to connect to database
