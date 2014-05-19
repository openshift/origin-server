@cartridge1
Feature: Snapshot and restore
  Scenario: Create, snapshot, and restore application with client tools
    Given the libra client tools
    And a new client created mock-0.1 application

    When I snapshot the application
    Then the mock control_pre_snapshot marker will exist in the gear
    And the gear state will be started

    When a new file is added and pushed to the client-created application repo
    Then the new file will be present in the gear app-root repo

    When I restore the application
    Then the mock control_post_restore marker will exist in the gear
    And the new file will not be present in the gear app-root repo
    And the gear state will be started
    
    When the application is stopped
    And I snapshot the application
    Then the gear state will be stopped
    
    When I restore the application
    Then the gear state will be stopped
    