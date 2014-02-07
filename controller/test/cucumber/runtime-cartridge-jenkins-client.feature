@cartridge_extended3
@jenkins
Feature: Jenkins Client Embedded Cartridge
  Scenario Outline: Add Jenkins Client to one application without Jenkins server available (RHEL/CentOS)
    #Given a perl-5.10 application, verify that you cannot add jenkins client without server being available
    Given a new <cart_name> type application
    Then I fail to embed a jenkins-client-1 cartridge into the application

    Scenarios: RHEL scenarios
    | cart_name |
    | perl-5.10 |