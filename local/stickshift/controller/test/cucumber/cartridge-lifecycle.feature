@verify
@broker
Feature: Cartridge Lifecycle Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  php-5.3     |
    |     1     |  python-2.6  |
    |     1     |  perl-5.10   |
    |     1     |  jbossas-7   |
    |     1     |  nodejs-0.6  |
    |     1     |  jenkins-1.4 |

  Scenario Outline: Application Creation diy
    Given the libra client tools
    And an accepted node
    When <app_count> <type> applications are created
    Then the applications should be temporarily unavailable

  Scenarios: Application Creation diy Scenarios
    | app_count |     type     |
    |     1     |  diy-0.1     |

  Scenario Outline: Application Modification
    Given an existing <type> application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenarios: Application Modification Scenarios
    |      type     |
    |   php-5.3     |
    |   python-2.6  |
    |   perl-5.10   |
    |   jbossas-7   |
    |   nodejs-0.6  |

  Scenario Outline: Application Stopping
    Given an existing <type> application
    When the application is stopped
    Then the application should not be accessible

  Scenarios: Application Stopping Scenarios
    |      type     |
    |   php-5.3     |
    |   python-2.6  |
    |   perl-5.10   |
    |   jbossas-7   |
    |   nodejs-0.6  |
    |   jenkins-1.4 |

  Scenario Outline: Application Starting
    Given an existing <type> application
    When the application is started
    Then the application should be accessible

  Scenarios: Application Starting Scenarios
    |      type     |
    |   php-5.3     |
    |   python-2.6  |
    |   perl-5.10   |
    |   jbossas-7   |
    |   nodejs-0.6  |
    |   jenkins-1.4 |
    
  Scenario Outline: Application Restarting
    Given an existing <type> application
    When the application is restarted
    Then the application should be accessible

  Scenarios: Application Restart Scenarios
    |      type     |
    |   php-5.3     |
    |   python-2.6  |
    |   perl-5.10   |
    |   jbossas-7 |
    |   nodejs-0.6  |
    |   jenkins-1.4 |

  Scenario Outline: Application Destroying
    Given an existing <type> application
    When the application is destroyed
    Then the application should not be accessible

  Scenarios: Application Destroying Scenarios
    |      type     |
    |   php-5.3     |
    |   python-2.6  |
    |   perl-5.10   |
    |   jbossas-7   |
    |   nodejs-0.6  |
    |   jenkins-1.4 |
    |   diy-0.1     |
