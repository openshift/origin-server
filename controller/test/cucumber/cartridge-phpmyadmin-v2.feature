@runtime_other4
@not-enterprise
Feature: phpMyAdmin Embedded Cartridge

  @rhel-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a mock application, verify addition and removal of v2 phpmyadmin-3.4
  
  @fedora-only
  Scenario: Add Remove phpMyAdmin to one application
    Given a mock application, verify addition and removal of v2 phpmyadmin-3.5
