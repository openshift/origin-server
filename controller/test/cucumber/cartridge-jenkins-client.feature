#@runtime_other4
@runtime
@runtime1
@jenkins
Feature: Jenkins Client Embedded Cartridge
  @rhel-only
  Scenario: Add Jenkins Client to one application without Jenkins server available (RHEL/CentOS)
    Given a perl-5.10 application, verify that you cannot add jenkins client without server being available
    
  @fedora-only
  Scenario: Add Jenkins Client to one application without Jenkins server available (Fedora)
    Given a perl-5.16 application, verify that you cannot add jenkins client without server being available
