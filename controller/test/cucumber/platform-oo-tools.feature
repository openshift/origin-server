@gear_extended
@gear_extended4
Feature: Platform Extended Tests
  Scenario: Basic functional test using oo-app-create and oo-cartridge
    Given a new cli-created mock-0.1 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the mock-0.1 cartridge private endpoints will be exposed
    And the mock setup_called marker will exist
    And the mock setup_version marker will exist
    And the mock install_called marker will exist
    And the mock install_version marker will exist
    And the mock post_install_called marker will exist
    And the mock post_install_version marker will exist
    And the mock-0.1 MOCK_VERSION env entry will exist
    And the mock setup_failure marker will not exist
    And the mock install_failure marker will not exist
    And the mock post_install_failure marker will not exist
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


