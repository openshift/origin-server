@cartridge2
Feature: SDK Mock Cartridge

  Scenario: Exercise basic platform functionality in isolation
    Given a new mock-0.1 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the mock-0.1 cartridge private endpoints will be exposed
    And the mock-0.1 cartridge endpoints with ssl to gear option will be exposed
    And the mock setup_called marker will exist
    And the mock setup_version marker will exist
    And the mock setup_failure marker will not exist
    And the mock install_called marker will exist
    And the mock install_version marker will exist
    And the mock install_failure marker will not exist
    And the mock post_install_called marker will exist
    And the mock post_install_version marker will exist
    And the mock post_install_failure marker will not exist
    And the mock-0.1 MOCK_VERSION env entry will exist
    And the mock-0.1 MOCK_EXAMPLE env entry will exist
    And the mock-0.1 MOCK_SERVICE_URL env entry will exist
    And the "app-root/runtime/repo/.openshift/README.md" content does exist for mock-0.1
    And the ".mock_gear_locked_file" content does exist for mock-0.1
    And the "mock/mock_cart_locked_file" content does exist for mock-0.1
    And the "app-root/data/mock_gear_data_locked_file" content does exist for mock-0.1
    And the "invalid_locked_file" content does not exist for mock-0.1
    And the mock control_start marker will exist
    And the mock action_hook_pre_start marker will exist
    And the mock action_hook_pre_start_mock marker will exist
    And the mock action_hook_post_start marker will exist
    And the mock action_hook_post_start_mock marker will exist
    And the mock control_build marker will not exist

    When I status the mock-0.1 cartridge
    Then the mock control_status marker will exist

    When I stop the newfangled application
    Then the mock control_stop marker will exist
    And the mock action_hook_pre_stop marker will exist
    And the mock action_hook_pre_stop_mock marker will exist
    And the mock action_hook_post_stop marker will exist
    And the mock action_hook_post_stop_mock marker will exist

    When I restart the newfangled application
    Then the mock control_restart marker will exist
    And the mock action_hook_pre_restart marker will exist
    And the mock action_hook_pre_restart_mock marker will exist
    And the mock action_hook_post_restart marker will exist
    And the mock action_hook_post_restart_mock marker will exist

    When I reload the newfangled application
    Then the mock control_reload marker will exist
    And the mock action_hook_pre_reload marker will exist
    And the mock action_hook_pre_reload_mock marker will exist
    And the mock action_hook_post_reload marker will exist
    And the mock action_hook_post_reload_mock marker will exist    

    When the application is made publicly accessible 
    And the application is prepared for git pushes
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    And the mock control_pre_repo_archive marker will exist
    And the mock control_update_configuration marker will exist
    And the mock control_pre_build marker will exist
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
    And the mock action_hook_pre_tidy marker will exist
    And the mock action_hook_pre_tidy_mock marker will exist
    And the mock action_hook_post_tidy marker will exist
    And the mock action_hook_post_tidy_mock marker will exist

    When I destroy the application
    Then the application git repo will not exist
