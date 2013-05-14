@runtime
@not-fedora-19
@runtime_extended_other2
Feature: Cartridge Runtime Standard Checks (Python)

  Scenario Outline: Python cartridge checks
    #Given a new python-2.6 application, verify it using httpd
    Given a new <cart_name> type application
    Then the http proxy will exist
    And a <proc_name> process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I stop the application
    Then a <proc_name> process will not be running
    When I start the application
    Then a <proc_name> process will be running
    When I status the application
    Then a <proc_name> process will be running
    When I restart the application
    Then a <proc_name> process will be running
    When I destroy the application
    Then the http proxy will not exist
    And a <proc_name> process will not be running
    And the application git repo will not exist
    And the application source tree will not exist

    @rhel-only
    Scenarios: RHEL scenarios
      | cart_name  | proc_name |
      | python-2.6 | httpd     |

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
    Scenarios: RHEL scenarios
      | type       | proc_name | hot_deploy_status | pid_changed   |
      | python-2.6 | httpd     | is not enabled    | should be     |