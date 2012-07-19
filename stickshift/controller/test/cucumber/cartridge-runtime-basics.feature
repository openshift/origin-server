@runtime
Feature: Cartridge Runtime Basic Sanity Checks

  @runtime1
  Scenario Outline: Create and delete an application
    Given a new <type> type application
    Then the application http proxy file will exist
    And a <proc_name> process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I destroy the application
    Then the application http proxy file will not exist
    And a <proc_name> process will not be running
    And the application git repo will not exist
    And the application source tree will not exist

  Scenarios: Create and delete an application scenarios
    | type         | proc_name |
    | php-5.3      | httpd     |
    | perl-5.10    | httpd     |
    | python-2.6   | httpd     |
    | ruby-1.8     | httpd     |
    | ruby-1.9     | httpd     |
    | nodejs-0.6   | node      |
    | jbossas-7    | java      |
    | jbosseap-6.0 | java      |


  @runtime2
  Scenario Outline: Start/stop/restart an application
    Given a new <type> type application
    Then a <proc_name> process will be running
    When I stop the application
    Then a <proc_name> process will not be running
    When I start the application
    Then a <proc_name> process will be running
    When I status the application
    Then a <proc_name> process will be running
    When I restart the application
    Then a <proc_name> process will be running
    When I destroy the application
    Then the application http proxy file will not exist
    And a <proc_name> process will not be running

  Scenarios: Start/stop/restart an application scenarios
    | type         | proc_name |
    | php-5.3      | httpd     |
    | perl-5.10    | httpd     |
    | python-2.6   | httpd     |
    | ruby-1.8     | httpd     |
    | ruby-1.9     | httpd     |
    | nodejs-0.6   | node      |
    | jbossas-7    | java      |
    | jbosseap-6.0 | java      |


  @runtime_verify2
  Scenario Outline: Push code change to application with hot deployment disabled
    Given a new <type> type application
    And the application is prepared for git pushes
    And hot deployment is not enabled for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a <proc_name> process will be running
    And the tracked application cartridge PIDs should be changed
    When I destroy the application
    Then a <proc_name> process will not be running

  Scenarios: Code push scenarios
    | type         | proc_name |
    | php-5.3      | httpd     |
    | perl-5.10    | httpd     |
    | python-2.6   | httpd     |
    | ruby-1.8     | httpd     |
    | ruby-1.9     | httpd     |
    | nodejs-0.6   | node      |
    | jbossas-7    | java      |
    | jbosseap-6.0 | java      |


  @runtime_verify2
  Scenario Outline: Push code change to application with hot deployment enabled
    Given a new <type> type application
    And the application is prepared for git pushes
    And hot deployment is enabled for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a <proc_name> process will be running
    And the tracked application cartridge PIDs should not be changed
    When I destroy the application
    Then a <proc_name> process will not be running

  Scenarios: Code push scenarios
    | type         | proc_name |
    | php-5.3      | httpd     |
    | perl-5.10    | httpd     |
    | jbossas-7    | java      |
    | jbosseap-6.0 | java      |
