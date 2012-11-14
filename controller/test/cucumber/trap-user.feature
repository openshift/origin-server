@runtime
@runtime3
Feature: Trap User Shell

  As a system designer
  I should be able to limit user login to a defined set of commands
  So that I can ensure the security of the system

  Scenario: Running commands via rhcsh
    Given a new php-5.3 type application
    And the application is made publicly accessible

    Then I can run "ls / > /dev/null" with exit code: 0
    And I can run "this_should_fail" with exit code: 127
    And I can run "true" with exit code: 0
    And I can run "java -version" with exit code: 0
    And I can run "scp" with exit code: 1

  Scenario: Tail Logs
    Given a new php-5.3 type application
    And the application is made publicly accessible
    Then a tail process will not be running

    When I tail the logs via ssh
    Then a tail process will be running

    When I stop tailing the logs
    Then a tail process will not be running
    
  Scenario: Access Quota
    Given a new php-5.3 type application
    And the application is made publicly accessible
    Then I can obtain disk quota information via SSH
  
