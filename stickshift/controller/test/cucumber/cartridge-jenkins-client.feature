@runtime
@runtime1
@jenkins
Feature: Jenkins Client Embedded Cartridge

  Scenario: Add Jenkins Client to one application without Jenkins server available
    Given an accepted node
    And a new guest account
    And a new php application
    When I try to configure jenkins-client it will fail
    And the jenkins-client directory will not exist
