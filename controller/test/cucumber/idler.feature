@singleton
Feature: Explicit idle/restore checks
  Scenario Outline: Idle one application (RHEL/CentOS)
    #Given a new <type> application with <proc_name> process, verify that it can be idled
    Given a new <type> type application
    Then a <proc_name> process will be running
    And I record the active capacity

    When I oo-idle the application
    Then a <proc_name> process will not be running
    And the active capacity has been reduced

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-1.9     | httpd     |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |

    @fedora-19-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-2.0     | httpd     |
      | perl-5.16    | httpd     |
      | php-5.5      | httpd     |
      | python-2.7   | httpd     |

  Scenario Outline: Restore one application (RHEL/CentOS)
    #Given a new <type> application with <proc_name> process, verify that it can be restored after idling
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

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-1.9     | httpd     |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |

    @fedora-19-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-2.0     | httpd     |
      | perl-5.16    | httpd     |
      | php-5.5      | httpd     |
      | python-2.7   | httpd     |

  Scenario Outline: Auto-restore one application (RHEL/CentOS)
    #Given a new <type> application with <proc_name> process, verify that it can be auto-restored after idling
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

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-1.9     | httpd     |
      | perl-5.10    | httpd     |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |

    @fedora-19-only
    Scenarios:
      | type         | proc_name |
      | nodejs       | node      |
      | ruby-2.0     | httpd     |
      | perl-5.16    | httpd     |
      | python-2.7   | httpd     |