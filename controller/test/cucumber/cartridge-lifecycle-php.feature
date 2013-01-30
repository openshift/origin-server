@runtime
@runtime4
@not-enterprise
Feature: Cartridge Lifecycle PHP Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 php-5.3 applications are created
    Then the applications should be accessible

  Scenario: Server Alias
    Given an existing php-5.3 application
    When the application is aliased
    Then the application should respond to the alias

  Scenario: Application Submodule Addition
    Given an existing php-5.3 application
    When the submodule is added
    Then the submodule should be deployed successfully
    And the application should be accessible

  Scenario: Application Modification
    Given an existing php-5.3 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Stopping
    Given an existing php-5.3 application
    When the application is stopped
    Then the application should not be accessible

  Scenario: Application Starting
    Given an existing php-5.3 application
    When the application is started
    Then the application should be accessible

  Scenario: Application Restarting
    Given an existing php-5.3 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing php-5.3 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Snapshot
    Given an existing php-5.3 application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible

  Scenario: Application Change Namespace
    Given an existing php-5.3 application
    When the application namespace is updated
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing php-5.3 application
    When the application is destroyed
    Then the application should not be accessible
