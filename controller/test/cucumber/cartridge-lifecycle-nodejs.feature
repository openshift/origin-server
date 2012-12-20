@runtime_extended
@runtime_extended3
@rhel-only
@not-enterprise
Feature: Cartridge Lifecycle NodeJS Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  nodejs-0.6  |

  Scenario Outline: Application Modification
    Given an existing <type> application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenarios: Application Modification Scenarios
    |      type     |
    |   nodejs-0.6  |
    
  Scenario Outline: Application package.json Dependency Add
    Given an existing <type> application
    When I add dependencies to package.json on node modules <modules>
    Then the application will have the <modules> node modules installed

  Scenarios: Application package.json Dependency Add Scenarios
    |      type     |  modules                        |
    |   nodejs-0.6  |  async socket.io coffee-script  |

  Scenario Outline: Application deplist.txt Dependency Add
    Given an existing <type> application
    When I add dependencies to deplist.txt on node modules <modules>
    Then the application will have the <modules> node modules installed

  Scenarios: Application deplist.txt Dependency Add Scenarios
    |      type     |  modules                         |
    |   nodejs-0.6  |  request optimist coffee-script  |

  Scenario Outline: Application Restarting
    Given an existing <type> application
    When the application is restarted
    Then the application should be accessible

  Scenarios: Application Restart Scenarios
    |      type     |
    |   nodejs-0.6  |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   nodejs-0.6  |
