@cartridge3
Feature: Mock Cartridge Build Tests

  Scenario: Exercise hot deployment
    Given a new mock-0.1 type application
    Then the application git repo will exist

    When the application is made publicly accessible 
    And the application is prepared for git pushes
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    And the mock control_start marker will exist
    And the mock control_build marker will exist

    When the mock control_start marker is removed
    And the mock control_stop marker is removed
    And the mock control_build marker is removed
    And the hot_deploy marker is added to the application repo
    And a simple update is committed to the application repo
    And the hot_deploy marker is removed from the application repo
    And a simple update is committed to the application repo
    And the hot_deploy marker is added to the application repo
    And a simple update is committed to the application repo
    And the application git repository is pushed
    Then the mock control_stop marker will not exist
    Then the mock control_start marker will not exist
    And the mock control_build marker will exist

    When the mock control_build marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will not exist
    Then the mock control_start marker will not exist

    When the mock control_build marker is removed
    And the hot_deploy marker is removed from the application repo
    And a simple update is committed to the application repo
    And the application git repository is pushed
    Then the mock control_stop marker will exist
    Then the mock control_start marker will exist
    And the mock control_build marker will exist

    When the mock control_build marker is removed
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    Then the mock control_start marker will exist
    And the mock control_build marker will exist

  Scenario: Exercise basic platform functionality in isolation with install builds enabled
    Given a new mock-0.2 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the mock-0.2 cartridge private endpoints will be exposed
    And the mock setup_called marker will exist
    And the mock setup_version marker will exist
    And the mock setup_failure marker will not exist
    And the mock install_called marker will exist
    And the mock install_version marker will exist
    And the mock install_failure marker will not exist
    And the mock post_install_called marker will exist
    And the mock post_install_version marker will exist
    And the mock post_install_failure marker will not exist
    And the mock-0.2 MOCK_VERSION env entry will exist
    And the mock-0.2 MOCK_EXAMPLE env entry will exist
    And the mock-0.2 MOCK_SERVICE_URL env entry will exist
    And the "app-root/runtime/repo/.openshift/README.md" content does exist for mock-0.2
    And the ".mock_gear_locked_file" content does exist for mock-0.2
    And the "mock/mock_cart_locked_file" content does exist for mock-0.2
    And the "app-root/data/mock_gear_data_locked_file" content does exist for mock-0.2
    And the "invalid_locked_file" content does not exist for mock-0.2
    And the mock control_start marker will exist
    And the mock action_hook_pre_start marker will exist
    And the mock action_hook_pre_start_mock marker will exist
    And the mock action_hook_post_start marker will exist
    And the mock action_hook_post_start_mock marker will exist
    And the mock control_pre_repo_archive marker will exist
    And the mock control_build marker will exist
    And the mock control_deploy marker will exist
    And the mock control_start marker will exist
    And the mock action_hook_pre_build marker will exist
    And the mock action_hook_build marker will exist
    And the mock action_hook_deploy marker will exist
    And the mock action_hook_post_deploy marker will exist
