@singleton
Feature: Explicit idle/restore checks

  Scenario Outline: Idle one application
    Given a new <type> type application
    Then a <proc_name> process will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <proc_name> process will not be running
    And the active capacity has been reduced

    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |
      
    @fedora-only
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |

  Scenario Outline: Restore one application
    Given a new <type> type application
    Then a <proc_name> process will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <proc_name> process will not be running
    And the active capacity has been reduced
    And I record the active capacity after idling

    When I oo-restore the application
    Then a <proc_name> process will be running
    And the active capacity has been increased

    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |
      
    @fedora-only
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |

  Scenario Outline: Auto-restore one application
    Given a new <type> type application
    Then a <proc_name> process will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <proc_name> process will not be running
    And the active capacity has been reduced
    And I record the active capacity after idling

    When I run the health-check for the <type> cartridge
    Then a <proc_name> process will be running
    And the active capacity has been increased

    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |
      
    @fedora-only
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |
