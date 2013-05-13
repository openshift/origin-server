@runtime
@runtime_extended_other3
@not-enterprise
Feature: phpMyAdmin Embedded Cartridge

  @runtime_extended_other3
  @rhel-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a php-5.3 application, verify addition and removal of phpmyadmin-3.4
  
  @fedora-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a php-5.4 application, verify addition and removal of phpmyadmin-3.5
