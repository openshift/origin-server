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


    When I start the application
    Then the mock control_start marker will exist

    When I status the mock-0.1 cartridge
    Then the mock control_status marker will exist

    When I stop the application
    Then the mock control_stop marker will exist

    When I restart the application
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
    And the application repo has been updated

    When I call tidy on the application
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

  Scenario: Create and exercise application with client tools
    Given a v2 default node
    And the libra client tools
    And an accepted node
    When 1 mock-0.1 applications are created
    # Then the applications should be accessible # Mock needs to serve HTTP for this step to work

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

