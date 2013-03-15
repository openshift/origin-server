@broker_api
@broker_api4
Feature: gear-groups
  As an API client
  I want to check the application state on each of the gears within each gear group

  @rhel-only
  Scenario: Check application state on gear with xml (RHEL/CentOS)
    Given a new user, create a php-5.3 application using XML format and verify application state on gear
    
  @fedora-only
  Scenario: Check application state on gear with xml (RHEL/CentOS)
    Given a new user, create a php-5.4 application using XML format and verify application state on gear