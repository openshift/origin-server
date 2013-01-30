@runtime_extended
@runtime_extended3
Feature: Cartridge Lifecycle Perl Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 perl-5.10 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing perl-5.10 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing perl-5.10 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing perl-5.10 application
    When the application is destroyed
    Then the application should not be accessible
