@runtime_extended3
@cartridge_v2_nodejs
@not-enterprise
Feature: V2 SDK Node.js Cartridge

  Scenario Outline: Add cartridge
    Given a v2 default node
    Given a new nodejs-<nodejs_version> type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the nodejs-<nodejs_version> cartridge private endpoints will be exposed
    And the nodejs-<nodejs_version> NODEJS_DIR env entry will exist
    And the nodejs-<nodejs_version> NODEJS_LOG_DIR env entry will exist
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL scenario
      | nodejs_version |
      |      0.6       |

    @fedora-19-only
    Scenarios: Fedora 19 scenario
      | nodejs_version |
      |      0.10      |

  Scenario Outline: Destroy application
    Given a v2 default node
    Given a new nodejs-<nodejs_version> type application
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL scenario
      | nodejs_version |
      |      0.6       |

    @fedora-19-only
    Scenarios: Fedora 19 scenario
      | nodejs_version |
      |      0.10      |
