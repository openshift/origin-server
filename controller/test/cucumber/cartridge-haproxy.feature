#@runtime_other3
@runtime
@runtime3
Feature: HAProxy Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with haproxy
    Given a new <type> type application
    Then a <proc_name> process will be running
    
    When I embed a haproxy-1.4 cartridge into the application
    Then 0 process named haproxy will be running
    And the embedded haproxy-1.4 cartridge directory will exist
    And the haproxy configuration file will exist
    And the haproxy PATH override will exist

    When I destroy the application
    Then 0 processes named haproxy will be running
    And a <proc_name> process will not be running
    And the embedded haproxy-1.4 cartridge directory will not exist
    And the haproxy configuration file will not exist

    @rhel-only
    Scenarios: Create Delete Application With haproxy Scenarios - RHEL
      | type         | proc_name |
      | ruby-1.8     | httpd     |
      | php-5.3      | httpd     |
      | perl-5.10    | httpd     |
      | python-2.6   | httpd     |

    @jboss
    Scenarios: Create Delete Application With haproxy Scenarios - Fedora 18
      | type         | proc_name |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |

    @fedora-only
    Scenarios: Create Delete Application With haproxy Scenarios - Fedora 18
      | type         | proc_name |
      | php-5.4      | httpd     |
      | perl-5.16    | httpd     |

    Scenarios: Create Delete Application With haproxy Scenarios - Common
      | type         | proc_name |
      | ruby-1.9     | httpd     |
      | nodejs-0.6   | node      |
