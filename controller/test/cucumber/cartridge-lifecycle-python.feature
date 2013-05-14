@runtime_extended
@runtime_extended1
@runtime_extended_other1
Feature: Cartridge Lifecycle Python Verification Tests
  Scenario Outline: Application Creation
  #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    Given an existing <cart_name> application

  #Given an existing <cart_name> application, verify application aliases
  #  Given an existing <cart_name> application
  #  When the application is aliased
  #  Then the application should respond to the alias
  #
  #Given an existing <cart_name> application, verify submodules
  #  When the submodule is added
  #  Then the submodule should be deployed successfully
  #  And the application should be accessible

  #Given an existing <cart_name> application, verify code updates
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  #Given an existing <cart_name> application, verify it can be stopped
  #  When the application is stopped
  #  Then the application should not be accessible
  #
  #Given an existing <cart_name> application, verify it can be started
  #  When the application is started
  #  Then the application should be accessible
  #
  #Given an existing <cart_name> application, verify it can be tidied
  #  When I tidy the application
  #  Then the application should be accessible
  #
  #Given an existing <cart_name> application, verify it can be snapshotted and restored
  #  When I snapshot the application
  #  Then the application should be accessible
  #  When a new file is added and pushed to the client-created application repo
  #  When I restore the application
  #  Then the application should be accessible
  #  And the new file will not be present in the gear app-root repo

  #Given an existing <cart_name> application, verify it can be restarted
    When the application is restarted
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

  @rhel-only
  Scenarios: RHEL scenarios
    | cart_name  |
    | python-2.6 |

  @fedora-19-only
  Scenarios: RHEL scenarios
    | cart_name  |
    | python-2.7 |