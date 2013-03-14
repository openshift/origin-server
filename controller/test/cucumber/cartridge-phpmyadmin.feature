#@runtime_other4
@runtime
@runtime4
@not-enterprise
Feature: phpMyAdmin Embedded Cartridge

  @rhel-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a php-5.3 application, verify addition and removal of phpmyadmin-3.4
  
  @fedora-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a php-5.4 application, verify addition and removal of phpmyadmin-3.5
