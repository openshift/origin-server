@runtime
@runtime4
Feature: Account Management
  Scenario: Create One Account
    When I create a guest account
    Then an account password entry should exist
    And an account home directory should exist

  Scenario: Delete One Account
    And a new guest account
    When I delete the guest account
    Then an account password entry should not exist
    And an account home directory should not exist
    
 Scenario: Delete One Namespace
    When I create a new namespace
    And I delete the namespace
    Then a namespace should get deleted
