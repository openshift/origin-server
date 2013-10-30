@runtime_extended3
@cartridge_nodejs
Feature: V2 SDK Node.js Cartridge

  Scenario Outline: Add cartridge
    Given a new nodejs-<nodejs_version> type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the nodejs-<nodejs_version> cartridge private endpoints will be exposed
    And the nodejs-<nodejs_version> NODEJS_DIR env entry will exist
    And the nodejs-<nodejs_version> NODEJS_LOG_DIR env entry will exist
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL SCL
      | nodejs_version |
      |  0.10          |

    @rhel-only
    @not-enterprise
    Scenarios: RHEL non-SCL
      | nodejs_version |
      |  0.6           |

    @fedora-only
    Scenarios: Fedora-19
      | nodejs_version |
      |  0.10          |

  Scenario Outline: Destroy application
    Given a new nodejs-<nodejs_version> type application
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL SCL
      | nodejs_version |
      |  0.10          |

    @rhel-only
    @not-enterprise
    Scenarios: RHEL non-SCL
      | nodejs_version |
      |  0.6           |
      
    @fedora-only
    Scenarios: Fedora-19
      | nodejs_version |
      |  0.10          |
