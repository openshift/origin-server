@jboss
@jbosseap
@runtime
@rhel-only
Feature: Cartridge Runtime Extended Checks (JBoss)

  @runtime_extended_other2
  Scenario Outline: Hot deployment tests
    Given a new <type> type application
    And the application is made publicly accessible
    And hot deployment <hot_deploy_status> for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a <proc_name> process will be running
    And the tracked application cartridge PIDs <pid_changed> changed
    When I destroy the application
    Then a <proc_name> process will not be running

  Scenarios: Code push scenarios
    | type         | proc_name | hot_deploy_status | pid_changed   |
    | jbosseap-6.0 | java      | is enabled        | should not be |
    | jbosseap-6.0 | java      | is not enabled    | should be     |
