@runtime
@rhel-only
@not-enterprise
@not-origin
Feature: Cartridge Runtime Standard Checks (Node)

  @runtime_extended_other1
  @runtime_extended1
  Scenario: Node cartridge checks
    #Given a new nodejs-0.6 application, verify it using node
    Given a new nodejs-0.6 type application
    Then the http proxy will exist
    And a node process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I stop the application
    Then a node process will not be running
    When I start the application
    Then a node process will be running
    When I status the application
    Then a node process will be running
    When I restart the application
    Then a node process will be running
    When I destroy the application
    Then the http proxy will not exist
    And a node process will not be running
    And the application git repo will not exist
    And the application source tree will not exist


#@runtime_extended2
@runtime
@not-origin
@not-enterprise
@runtime_extended_other2
  Scenario Outline: Hot deployment tests
    Given a new <type> type application
    And the application is made publicly accessible
    And hot deployment <hot_deploy_status> for the application
    And an update has been pushed to the application repo
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a <proc_name> process will be running
    And the tracked application cartridge PIDs <pid_changed> changed
    When I destroy the application
    Then a <proc_name> process will not be running

  Scenarios: Code push scenarios
    | type         | proc_name | hot_deploy_status | pid_changed   |
    | nodejs-0.6   | node      | is enabled        | should not be |
    | nodejs-0.6   | node      | is not enabled    | should be     |
