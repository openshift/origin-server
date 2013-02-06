@runtime_extended2
@runtime_extended3
Feature: Trap User Shell
  Scenario Outline: Use ctl_all to start and stop a simple application
    Given a new <type> type application
    And the application is made publicly accessible

    When I stop the application using ctl_all via rhcsh
    Then a <proc_name> process will not be running

    When I start the application using ctl_all via rhcsh
    Then a <proc_name> process will be running

    @rhel-only
    Scenarios:
      | type         | proc_name |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |

    Scenarios:
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | perl-5.10    | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |
      | ruby-1.9     | httpd     |

  Scenario Outline: Use ctl_all to start and stop an application with an embedded database
    Given a new <type> type application
    And I embed a <db_type> cartridge into the application
    And I embed a <management_app> cartridge into the application
    And the application is made publicly accessible

    When I stop the application using ctl_all via rhcsh
    Then a <proc_name> process for <type> will not be running
    And a <db_proc_name> process will not be running 
    And a httpd process for <management_app> will not be running

    When I start the application using ctl_all via rhcsh
    Then a <proc_name> process for <type> will be running
    And a <db_proc_name> process will be running
    And a httpd process for <management_app> will be running

    Scenarios:
      | type         | proc_name | db_type     | db_proc_name | management_app |
      | perl-5.10    | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | perl-5.10    | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |
      | php-5.3      | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | php-5.3      | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |
      | ruby-1.9     | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | ruby-1.9     | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |

    @rhel-only
    Scenarios:
      | type         | proc_name | db_type     | db_proc_name | management_app |
      | ruby-1.8     | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | ruby-1.8     | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |

    
