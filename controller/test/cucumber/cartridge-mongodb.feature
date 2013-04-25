#@runtime_other4
@runtime
@runtime1
@not-enterprise
Feature: MongoDB Application Sub-Cartridge
  @rhel-only
  Scenario: Create Delete one application with a MongoDB database (RHEL/CentOS)
    Given a perl-5.10 application, verify addition and removal of MongoDB database
  
  @fedora-only
  Scenario: Create Delete one application with a MongoDB database (Fedora)
    Given a perl-5.16 application, verify addition and removal of MongoDB database
