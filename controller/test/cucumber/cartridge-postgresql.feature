#@runtime_other3
@runtime
@runtime3
Feature: PostgreSQL Application Sub-Cartridge

  @rhel-only
  Scenario: Create Delete one application with a PostgreSQL database
    Given a perl-5.10 application, verify addition and removal of postgresql 8.4

  @fedora-only
  Scenario: Create Delete one application with a PostgreSQL database
    Given a perl-5.16 application, verify addition and removal of postgresql 9.2
