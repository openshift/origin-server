@node
@cartridge_extended1
Feature: Cartridge Lifecycle Ruby Verification Tests
  Scenario Outline: Application Creation
  #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    Given an existing <cart_name> application

  #Given an existing <cart_name> application, verify application aliases
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
    When I tidy the application
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be restarted
    When the application is restarted
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

    Scenarios: RHEL scenarios
      | cart_name |
      | ruby-1.8  |
      | ruby-1.9  |
      | ruby-2.0  |
