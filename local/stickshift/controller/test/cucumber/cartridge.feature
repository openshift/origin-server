@verify
@broker
Feature: Cartridge Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  php-5.3     |
    |     1     |  jbossas-7   |
    |     1     |  nodejs-0.6  |
    |     1     |  jenkins-1.4 |

  Scenario Outline: Server Alias
    Given an existing <type> application
    When the application is aliased
    Then the application should respond to the alias

  Scenarios: Server Alias Scenarios
    |      type     |
    |   php-5.3     |

  Scenario Outline: Application Submodule Addition
    Given an existing <type> application
    When the submodule is added
    Then the submodule should be deployed successfully
    And the application should be accessible

  Scenarios: Application Submodule Addition Scenarios
    |      type     |
    |   php-5.3     |

  Scenario Outline: Application Change Namespace
    Given an existing <type> application
    When the application namespace is updated
    Then the application should be accessible

  Scenarios: Application Change Namespace Scenarios
    |      type     |
    |   php-5.3     |
    |   jenkins-1.4 |

  Scenario Outline: Application Snapshot
    Given an existing <type> application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible

  Scenarios: Application Snapshot Scenarios
    |      type     |
    |   php-5.3     |
    |   jbossas-7   |
    |   nodejs-0.6  |

  Scenario Outline: Application Tidy
    Given an existing <type> application
    When I tidy the application
    Then the application should be accessible

  Scenarios: Application Tidy Scenarios
    |      type     |
    |   php-5.3     |
    |   jbossas-7   |
    |   nodejs-0.6  |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   php-5.3     |
    |   jbossas-7   |
    |   nodejs-0.6  |
    |   jenkins-1.4 |
