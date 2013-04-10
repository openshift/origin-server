@runtime_other
Feature: V2 SDK Mock Cartridge

  Scenario: Exercise basic platform functionality in isolation
    Given a v2 default node
    Given a new mock-0.1 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the mock-0.1 cartridge private endpoints will be exposed
    And the mock setup_called marker will exist
    And the mock setup_version marker will exist
    And the mock setup_failure marker will not exist
    And the mock-0.1 MOCK_VERSION env entry will exist
    And the mock-0.1 MOCK_EXAMPLE env entry will exist
    And the mock-0.1 MOCK_SERVICE_URL env entry will exist
    And the "app-root/runtime/repo/.openshift/README.md" content does exist for mock-0.1
    And the ".mock_gear_locked_file" content does exist for mock-0.1
    And the "mock/mock_cart_locked_file" content does exist for mock-0.1
    And the "app-root/data/mock_gear_data_locked_file" content does exist for mock-0.1
    And the "invalid_locked_file" content does not exist for mock-0.1

    When I start the newfangled application
    Then the mock control_start marker will exist

    When I status the mock-0.1 cartridge
    Then the mock control_status marker will exist

    When I stop the newfangled application
    Then the mock control_stop marker will exist

    When I restart the newfangled application
    Then the mock control_restart marker will exist

    When the application is made publicly accessible 
    And the application is prepared for git pushes
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    And the mock control_build marker will exist
    And the mock control_deploy marker will exist
    And the mock control_start marker will exist
    And the mock action_hook_pre_build marker will exist
    And the mock action_hook_build marker will exist
    And the mock action_hook_deploy marker will exist
    And the mock action_hook_post_deploy marker will exist
    And the application repo has been updated

    When I tidy the newfangled application
    Then the mock control_tidy marker will exist

    When I destroy the application
    Then the application git repo will not exist

  # Scenario: Add cartridge w/ user-specified repo
  # Scenario: Move
  # Scenario: Access via SSH

  Scenario: Basic functional test using oo-app-create and oo-cartridge
    Given a v2 default node
    Given a new cli-created mock-0.1 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the mock-0.1 cartridge private endpoints will be exposed
    And the mock setup_called marker will exist
    And the mock setup_version marker will exist
    And the mock-0.1 MOCK_VERSION env entry will exist
    And the mock setup_failure marker will not exist
    And the mock-0.1 MOCK_EXAMPLE env entry will exist
    And the mock-0.1 MOCK_SERVICE_URL env entry will exist
    And the mock-0.1 MOCK_IDENT env entry will exist

    When I start the application
    Then the mock control_start marker will exist

    When I status the application
    Then the mock control_status marker will exist

    When I stop the application
    Then the mock control_stop marker will exist

    When I restart the application
    Then the mock control_restart marker will exist

    When the application is made publicly accessible 
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And an update is pushed to the application repo
    Then the mock control_stop marker will exist
    And the mock control_build marker will exist
    And the mock control_deploy marker will exist
    And the mock control_start marker will exist

    When I call tidy on the application
    Then the mock control_tidy marker will exist

    When I destroy the application
    Then the application git repo will not exist

  # Client tools tests

  Scenario: Create, snapshot, and restore application with client tools
    Given a v2 default node
    And the libra client tools
    And an accepted node
    And a new client created mock-0.1 application

    When I snapshot the application
    Then the mock control_pre_snapshot marker will exist in the gear
    And the mock control_post_snapshot marker will exist in the gear

    When a new file is added and pushed to the client-created application repo
    Then the new file will be present in the gear app-root repo

    When I restore the application
    And the mock control_post_restore marker will exist in the gear
    And the new file will not be present in the gear app-root repo

  Scenario: Platform SSH for web proxy cartridge
    Given a v2 default node
    And a new client created scalable mock-0.1 application

    When the minimum scaling parameter is set to 2
    And a new file is added and pushed to the client-created application repo
    Then the new file will be present in the secondary gear app-root repo

  # Plugin tests

  Scenario: Add/Remove mock plugin to/from mock application
    Given a v2 default node
    Given a new mock-0.1 type application
    When I embed a mock-plugin-0.1 cartridge into the application
    Then the mock-plugin-0.1 cartridge private endpoints will be exposed
    And the mock-plugin setup_called marker will exist
    And the mock-plugin setup_version marker will exist
    And the mock-plugin setup_failure marker will not exist
    And the mock-plugin-0.1 MOCK_PLUGIN_EXAMPLE env entry will exist
    And the mock-plugin-0.1 MOCK_PLUGIN_SERVICE_URL env entry will exist
    When I remove the mock-plugin-0.1 cartridge from the application
    Then the mock-plugin teardown_called marker will exist
    And the mock-plugin-0.1 cartridge private endpoints will be concealed
    And the mock-plugin-0.1 cartridge instance directory will not exist

  Scenario: Basic state checks for an application with an embedded cartridge
    Given a v2 default node
    Given a new mock-0.1 type application   
    
    When I embed a mock-plugin-0.1 cartridge into the application
    Then the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should not be present

    # A stopped application should restart after a build, which performs
    # a restart on behalf of the user
    When I stop the newfangled application
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be stopped
    And the application stoplock should be present

    When the application is made publicly accessible 
    And the application is prepared for git pushes
    And a simple update is pushed to the application repo
    Then the mock control_build marker will exist
    And the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should not be present

    # A tidy will indirectly attempt to restart the application, which
    # is NOT on the user's behalf. So, a stopped app should not be
    # restarted following a tidy.
    When I stop the newfangled application
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be stopped
    And the application stoplock should be present

    When I tidy the newfangled application
    Then the mock control_tidy marker will exist
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be stopped
    And the application stoplock should be present    

    When I start the newfangled application
    Then the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should not be present

    # Control operations against secondary carts shouldn't affect
    # the overall app state or stop lock    
    When I stop the mock-plugin-0.1 cartridge
    Then the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be stopped
    And the application stoplock should not be present

    When I start the mock-plugin-0.1 cartridge
    Then the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should not be present

    # Control operations against the primary cart in isolation should
    # modify the application and stoplock statesS
    When I stop the mock-0.1 cartridge
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should be present

    When I stop the mock-plugin-0.1 cartridge
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be stopped
    And the application stoplock should be present

    # With the whole app shut down, restarting the secondary cartridge
    # shouldn't affect the application or stoplock state
    When I start the mock-plugin-0.1 cartridge
    Then the application state will be stopped
    And the mock-0.1 cartridge status should be stopped
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should be present

    When I start the mock-0.1 cartridge
    Then the application state will be started
    And the mock-0.1 cartridge status should be running
    And the mock-plugin-0.1 cartridge status should be running
    And the application stoplock should not be present
    