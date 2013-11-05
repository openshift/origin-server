@node
@node3
Feature: Trap User Shell

  As a system designer
  I should be able to limit user login to a defined set of commands
  So that I can ensure the security of the system

  Scenario: Running commands via rhcsh (RHEL/CentOS)
    Given a new mock-0.1 type application

    When the application is made publicly accessible
    Then I can run "ls / > /dev/null" with exit code: 0
    And I can run "this_should_fail" with exit code: 127
    And I can run "true" with exit code: 0
    And I can run "scp" with exit code: 1

    When I run the rhcsh command "ctl_all stop"
    Then the application state will be stopped

    When I run the rhcsh command "ctl_all start"
    Then the application state will be started

    When I embed a mock-plugin-0.1 cartridge into the application
    Then the application state will be started
    Then the mock-0.1 cartridge status should be running
    Then the mock-plugin-0.1 cartridge status should be running

    When I run the rhcsh command "ctl_all stop"
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be stopped

    When I run the rhcsh command "ctl_all start"
    Then the application state will be started
    Then the mock-0.1 cartridge status should be running
    Then the mock-plugin-0.1 cartridge status should be running
