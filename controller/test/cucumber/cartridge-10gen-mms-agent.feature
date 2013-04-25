@runtime
@runtime_extended1
@not-enterprise
Feature: 10gen-mms-agent Embedded Cartridge

  @rhel-only
  Scenario: 10gen-mms-agent Embedded Cartridge (RHEL/CentOS)
    Given a perl-5.10 application, verify addition and removal of 10gen-mms-agent
    
  @fedora-only
  Scenario: 10gen-mms-agent Embedded Cartridge (Fedora)
    Given a perl-5.16 application, verify addition and removal of 10gen-mms-agent
