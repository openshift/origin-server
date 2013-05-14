@runtime
@runtime_extended_other2
@not-fedora-19
Feature: Cartridge Runtime Standard Checks (Ruby)

  Scenario Outline: Ruby cartridge checks
    #Given a new ruby-1.8 application, verify it using httpd
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
    Scenarios: RHEL
      | cart_name | proc_name |
      | ruby-1.8  | httpd     |
      | ruby-1.9  | httpd     |

  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    #Given a new ruby-1.8 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of PassengerWatchd proc
    Given a new <cart_name> type application
    And the application is made publicly accessible
    And hot deployment is<hot_deply_not_enabled> enabled for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a <proc_name> process will be running
    And the tracked application cartridge PIDs should<pid_not_changed> be changed
    When I destroy the application
    Then a <proc_name> process will not be running

    @rhel-only
    Scenarios: Code push scenarios
      | cart_name | hot_deploy_status | pid_changed     |
      |  ruby-1.8 | is enabled        | does not change |
      |  ruby-1.8 | is not enabled    | does change     |
      |  ruby-1.9 | is enabled        | does not change |
      |  ruby-1.9 | is not enabled    | does change     |