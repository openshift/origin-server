#@runtime_extended_other3
@runtime_extended
@runtime_extended3
@rhel-only
@not-enterprise
Feature: Cartridge Lifecycle NodeJS Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 nodejs-0.6 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing nodejs-0.6 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application package.json Dependency Add
    Given an existing nodejs-0.6 application
    When I add dependencies to package.json on node modules async socket.io coffee-script
    Then the application will have the async socket.io coffee-script node modules installed

  Scenario: Application deplist.txt Dependency Add
    Given an existing nodejs-0.6 application
    When I add dependencies to deplist.txt on node modules request optimist coffee-script
    Then the application will have the request optimist coffee-script node modules installed

  Scenario: Application Restarting
    Given an existing nodejs-0.6 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing nodejs-0.6 application
    When the application is destroyed
    Then the application should not be accessible
