@runtime
@rhel-only
Feature: Cartridge Runtime Standard Checks (DIY)

  @runtime_extended_other1
  Scenario Outline: DIY cartridge checks
    #Given a new diy-0.1 application, verify it using ruby
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
    | diy-0.1   | ruby      |
