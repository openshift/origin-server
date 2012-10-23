@runtime
@runtime1
@jenkins
Feature: Jenkins Client Embedded Cartridge

  # See cartridge-jenkins-build for the success Scenario
  Scenario: Add Jenkins Client to one application without Jenkins server available
    Given a new perl-5.10 type application
    When I fail to embed a jenkins-client-1.4 cartridge into the application
    Then the embedded jenkins-client-1.4 cartridge directory will not exist
