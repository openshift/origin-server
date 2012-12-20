@runtime
Feature: Cartridge Runtime Extended Checks (Ruby)

  @runtime_extended2
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

    @rhel-only
    Scenarios: Code push scenarios
      | type         | proc_name        | hot_deploy_status | pid_changed   |
      | ruby-1.8     | PassengerWatchd  | is not enabled    | should be     |
      | ruby-1.8     | PassengerWatchd  | is enabled        | should not be |

    Scenarios: Code push scenarios - origin
      | type         | proc_name        | hot_deploy_status | pid_changed   |
      | ruby-1.9     | PassengerWatchd  | is not enabled    | should be     |
      | ruby-1.9     | PassengerWatchd  | is enabled        | should not be |
