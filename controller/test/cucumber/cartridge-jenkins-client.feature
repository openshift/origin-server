@runtime
@runtime1
@jenkins
Feature: Jenkins Client Embedded Cartridge

  # See cartridge-jenkins-build for the success Scenario
  Scenario Outline: Add Jenkins Client to one application without Jenkins server available
    Given a new <perl_version> type application
    When I fail to embed a jenkins-client-1.4 cartridge into the application
    Then the embedded jenkins-client-1.4 cartridge directory will not exist

    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |