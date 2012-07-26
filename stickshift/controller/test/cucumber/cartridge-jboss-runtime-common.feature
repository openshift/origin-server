@runtime
Feature: JBoss Common Runtime Tests

  @runtime1
  Scenario Outline: Create and delete a JBoss application
    Given a new <type> type application
    Then the application http proxy file will exist
    And a <proc_name> process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    And the jboss application directory tree will be populated
    And the jboss server and module files will exist
    And the jboss server configuration files will exist
    And the jboss standalone scripts will exist
    And the jboss git hooks will exist
    And a jboss deployments directory will exist
    And the jboss maven repository will exist
    When I destroy the application
    Then the application http proxy file will not exist
    And a <proc_name> process will not be running
    And the application git repo will not exist
    And the application source tree will not exist
    And the jboss maven repository will not exist

  Scenarios: Create and delete a JBoss application scenarios
    | type         | proc_name |
    | jbossas-7    | java      |
    | jbosseap-6.0 | java      |
