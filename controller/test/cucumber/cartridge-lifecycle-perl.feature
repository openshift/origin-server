@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle Perl Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 <perl_version> applications are created
    Then the applications should be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |
    
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |

  Scenario Outline: Application Modification
    Given an existing <perl_version> application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |
    
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |

  Scenario Outline: Application Restarting
    Given an existing <perl_version> application
    When the application is restarted
    Then the application should be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |
    
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |

  Scenario Outline: Application Destroying
    Given an existing <perl_version> application
    When the application is destroyed
    Then the application should not be accessible

    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |
    
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |