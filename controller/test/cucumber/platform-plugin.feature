@gear_extended
@gear_extended1
Feature: Platform Plugin Tests
  Scenario: Basic state checks for an application with an embedded cartridge
    Given a new mock-0.1 type application

    When I embed a mock-plugin-0.1 cartridge into the application
    Then the mock-plugin-0.1 cartridge private endpoints will be exposed
    And the mock-plugin setup_called marker will exist
    And the mock-plugin setup_version marker will exist
    And the mock-plugin setup_failure marker will not exist
    And the mock-plugin install_called marker will exist
    And the mock-plugin install_version marker will exist
    And the mock-plugin install_failure marker will not exist
    And the mock-plugin post_install_called marker will exist
    And the mock-plugin post_install_version marker will exist
    And the mock-plugin post_install_failure marker will not exist
    And the mock-plugin-0.1 MOCK_PLUGIN_EXAMPLE env entry will exist
    And the mock-plugin-0.1 MOCK_PLUGIN_SERVICE_URL env entry will exist
    And the application state will be started
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

    When I remove the mock-plugin-0.1 cartridge from the application
    Then the mock-plugin teardown_called marker will exist
    And the mock-plugin-0.1 cartridge private endpoints will be concealed
    And the mock-plugin-0.1 cartridge instance directory will not exist
