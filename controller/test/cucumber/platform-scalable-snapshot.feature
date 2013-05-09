@runtime_extended1
Feature: V2 SDK scalable snapshot and restore
  Scenario: Create, snapshot, and restore scalable application with plugin with client tools
    Given a v2 default node
    And the libra client tools
    And a new client created scalable mock-0.1 application
    And the embedded mock-plugin-0.1 cartridge is added

    When I snapshot the application
    Then the mock control_pre_snapshot marker will exist in the gear
    And the mock control_post_snapshot marker will exist in the gear
    And the mock-plugin control_pre_snapshot marker will exist in the plugin gear
    And the mock-plugin control_post_snapshot marker will exist in the plugin gear

    When a new file is added and pushed to the client-created application repo
    Then the new file will be present in the gear app-root repo

    When I restore the application
    And the mock control_post_restore marker will exist in the gear
    And the new file will not be present in the gear app-root repo    
    And the mock-plugin control_post_restore marker will exist in the plugin gear