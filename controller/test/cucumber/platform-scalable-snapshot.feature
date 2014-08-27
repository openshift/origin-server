@gear_extended
@gear_extended2
Feature: Scalable snapshot and restore
  Scenario: Create, snapshot, and restore scalable application with plugin with client tools
    And the libra client tools
    And a new client created scalable mock-0.1 application
    And the embedded mock-plugin-0.1 cartridge is added

    # FIXME there is an issue with the haproxy cartridge where attempting to reload haproxy
    # with a new configuration (e.g. after update-cluster), followed quickly by attempts to
    # stop and then start haproxy, can fail. The issue is that the reload is still trying
    # to gracefully stop the previous haproxy process instance, and then the attempts to
    # stop and start the haproxy cartridge don't produce the intended results, resulting
    # in a test failure. In the long term, we should try to fix the haproxy cartridge's
    # control script to address these issues.
    And I sleep 10 seconds

    When I snapshot the application
    Then the mock control_pre_snapshot marker will exist in the gear
    And the mock control_post_snapshot marker will exist in the gear
    And the mock-plugin control_pre_snapshot marker will exist in the plugin gear
    And the mock-plugin control_post_snapshot marker will exist in the plugin gear
    And the plugin gear state will be started
    And the gear state will be started

    When a new file is added and pushed to the client-created application repo
    Then the new file will be present in the gear app-root repo

    When I restore the application
    And the mock control_post_restore marker will exist in the gear
    And the new file will not be present in the gear app-root repo
    And the mock-plugin control_post_restore marker will exist in the plugin gear
    Then the plugin gear state will be started
    And the gear state will be started

    When the application is stopped
    And I snapshot the application
    Then the plugin gear state will be stopped
    And the gear state will be stopped

    When I restore the application
    Then the plugin gear state will be stopped
    And the gear state will be stopped
