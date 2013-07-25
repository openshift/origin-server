@singleton
Feature: Explicit idle/restore checks
  Scenario Outline: Idle one application
    Given a new mock-0.1 type application
    Then a <ruby_proc> process for mock_server will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <ruby_proc> process for mock_server will not be running
    And the active capacity has been reduced

    @fedora-19-only
    Scenarios: Fedora 19
      | ruby_proc |
      | ruby-mri  |

    @rhel-only
    Scenarios: RHEL
      | ruby_proc |
      | ruby      |

  Scenario Outline: Restore one application
    Given a new mock-0.1 type application
    Then a <ruby_proc> process for mock_server will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <ruby_proc> process for mock_server will not be running
    And the active capacity has been reduced
    And I record the active capacity after idling

    When I oo-restore the application
    Then a <ruby_proc> process for mock_server will be running
    And the active capacity has been increased

    @fedora-19-only
    Scenarios: Fedora 19
      | ruby_proc |
      | ruby-mri  |

    @rhel-only
    Scenarios: RHEL
      | ruby_proc |
      | ruby      |

  Scenario Outline: Auto-restore one application
    Given a new mock-0.1 type application
    Then a <ruby_proc> process for mock_server will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <ruby_proc> process for mock_server will not be running
    And the active capacity has been reduced
    And I record the active capacity after idling

    When I run the health-check for the <type> cartridge
    Then a <ruby_proc> process for mock_server will be running
    And the active capacity has been increased

    @fedora-19-only
    Scenarios: Fedora 19
      | ruby_proc |
      | ruby-mri  |

    @rhel-only
    Scenarios: RHEL
      | ruby_proc |
      | ruby      |

