@node
@node2
Feature: Account Management
  Scenario: Create and delete one account
    Given a new guest account
    Then an account password entry should exist
    And an account PAM limits file should exist
    #And an HTTP proxy config file should exist
    And the account should be subscribed to cgroup subsystems
    And a traffic control entry should exist
    And an account home directory should exist
    And selinux labels on the account home directory should be correct
    And disk quotas on the account home directory should be correct

    When I delete the guest account
    Then an account password entry should not exist
    And an account PAM limits file should not exist
    And a traffic control entry should not exist
    And the account should not be subscribed to cgroup subsystems
    And an account home directory should not exist

 Scenario: Delete One Namespace
    When I create a new namespace
    And I delete the namespace
    Then a namespace should get deleted
