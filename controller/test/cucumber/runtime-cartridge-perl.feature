@runtime_extended3
Feature: V2 SDK Perl Cartridge

  Scenario Outline: Add cartridge
    Given a new <cart_name> type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the <cart_name> cartridge private endpoints will be exposed
    And the <cart_name> PERL_DIR env entry will exist
    And the <cart_name> PERL_LOG_DIR env entry will exist
    And the <cart_name> PERL_VERSION env entry will exist
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |

    @fedora-19-only
    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.16 |

  Scenario Outline: Destroy application
    Given a new <cart_name> type application
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |

    @fedora-19-only
    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.16 |
