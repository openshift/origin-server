@runtime
@runtime4
@runtime_other4
@not-enterprise
Feature: Cartridge Lifecycle PHP Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 <php_version> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Server Alias
    Given an existing <php_version> application
    When the application is aliased
    Then the application should respond to the alias
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Submodule Addition
    Given an existing <php_version> application
    When the submodule is added
    Then the submodule should be deployed successfully
    And the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Modification
    Given an existing <php_version> application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Stopping
    Given an existing <php_version> application
    When the application is stopped
    Then the application should not be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Starting
    Given an existing <php_version> application
    When the application is started
    Then the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Restarting
    Given an existing <php_version> application
    When the application is restarted
    Then the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Tidy
    Given an existing <php_version> application
    When I tidy the application
    Then the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Snapshot
    Given an existing <php_version> application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Change Namespace
    Given an existing <php_version> application
    When the application namespace is updated
    Then the application should be accessible
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |

  Scenario Outline: Application Destroying
    Given an existing <php_version> application
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version |
      | php-5.3     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version |
      | php-5.4     |
