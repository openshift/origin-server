@singleton
Feature: Explicit idle/restore checks

  Scenario Outline: Idle one application (Common)
    Given a new <type> application with <proc_name> process, verify that it can be idled

    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

  @rhel-only
  Scenario Outline: Idle one application (RHEL/CentOS)
    Given a new <type> application with <proc_name> process, verify that it can be idled

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
  Scenario Outline: Idle one application (Fedora)
    Given a new <type> application with <proc_name> process, verify that it can be idled    
      
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |

  Scenario Outline: Restore one application (Common)
    Given a new <type> application with <proc_name> process, verify that it can be restored after idling
    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

  @rhel-only
  Scenario Outline: Restore one application (RHEL/CentOS)
    Given a new <type> application with <proc_name> process, verify that it can be restored after idling
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
  Scenario Outline: Restore one application (Fedora)
    Given a new <type> application with <proc_name> process, verify that it can be restored after idling    
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |
      
  Scenario Outline: Auto-restore one application (Common)
    Given a new <type> application with <proc_name> process, verify that it can be auto-restored after idling
    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

  @rhel-only
  Scenario Outline: Auto-restore one application (RHEL/CentOS)
    Given a new <type> application with <proc_name> process, verify that it can be auto-restored after idling
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
  Scenario Outline: Auto-restore one application (Fedora)
    Given a new <type> application with <proc_name> process, verify that it can be auto-restored after idling    
    Scenarios:
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |