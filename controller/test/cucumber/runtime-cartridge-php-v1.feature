@runtime
@runtime_extended_other2
@rhel-only
Feature: PHP Application
  @rhel-only
  Scenario: Test Alias Hooks (RHEL/CentOS)
    #Given a new php-5.3 application, verify application alias setup on the node
    Given a new php-5.3 type application
    And I add an alias to the application
    Then the php application will be aliased
    And the php file permissions are correct
    When I remove an alias from the application
    Then the php application will not be aliased
    When I destroy the application
    Then the http proxy will not exist

  @rhel-only
  Scenario Outline: PHP cartridge checks
    #Given a new php-5.3 application, verify it using httpd
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

    Scenarios: All
      | cart_name | proc_name |
      |  php-5.3  |  httpd    |


  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    #Given a new php-5.3 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of httpd proc
    Given a new php-5.3 type application
    And the application is made publicly accessible
    And hot deployment <hot_deploy_status> for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a httpd process will be running
    And the tracked application cartridge PIDs <pid_changed>
    When I destroy the application
    Then a httpd process will not be running

    Scenarios: Code push scenarios
      | hot_deploy_status | pid_changed           |
      | is enabled        | should not be changed |
      | is not enabled    | should be changed     |
