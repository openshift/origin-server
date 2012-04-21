@internals
@node
Feature: Node.js Application

  Scenario: Create Delete one Node Application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed
    When I configure a nodejs application
    Then a nodejs application http proxy file will exist
    And a nodejs application git repo will exist
    And a nodejs application source tree will exist
    And a node process will be running
    And nodejs application log files will exist
    When I deconfigure the nodejs application
    Then a nodejs application http proxy file will not exist
    And a nodejs application git repo will not exist
    And a nodejs application source tree will not exist
    And a node process will not be running

  Scenario: Stop Start a Node Application
    Given an accepted node
    And a new guest account
    And a new nodejs application
    And the nodejs application is running
    When I stop the nodejs application
    Then the nodejs application will not be running
    And a node process will not be running
    And the nodejs application is stopped
    When I start the nodejs application
    Then the nodejs application will be running
    And a node process will be running
