#@runtime_extended_other1
@runtime
@runtime_extended1
Feature: cron Embedded Cartridge

  @rhel-only
  Scenario: Add Remove cron to one application (RHEL/CentOS)
    Given a php-5.3 application, verify addition and removal of cron
  
  @fedora-only
  Scenario: Add Remove cron to one application (Fedora)
    Given a php-5.4 application, verify addition and removal of cron
