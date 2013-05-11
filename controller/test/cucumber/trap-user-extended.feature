@runtime_extended2
Feature: Trap User Shell

  @rhel-only
  Scenario Outline: Use ctl_all to start and stop a simple application (RHEL/CentOS)
    Given a new <type> application, use ctl_all to start and stop it, and verify it using <proc_name>

    Scenarios: RHEL scenarios
      | type         | proc_name |
      | jbossas-7    | java      |
      | jbosseap-6.0 | java      |
      | jbossews-1.0 | java      |
      | ruby-1.8     | httpd     |
      | perl-5.10    | httpd     |
      | php-5.3      | httpd     |
      | python-2.6   | httpd     |


  Scenario Outline: Use ctl_all to start and stop a simple application (Common)
    Given a new <type> application, use ctl_all to start and stop it, and verify it using <proc_name>

    Scenarios: Common scenarios
      | type         | proc_name |
      | nodejs-0.6   | node      |
      | ruby-1.9     | httpd     |

  @fedora-only
  Scenario Outline: Use ctl_all to start and stop a simple application (Fedora)
    Given a new <type> application, use ctl_all to start and stop it, and verify it using <proc_name>

    Scenarios: Fedora 18 scenarios
      | type         | proc_name |
      | perl-5.16    | httpd     |
      | php-5.4      | httpd     |

  @rhel-only
  Scenario Outline: Use ctl_all to start and stop an application with an embedded database (RHEL/CentOS)
    Given a new <type> application, with <db_type> and <management_app>, verify that they are running using <proc_name> and <db_proc_name>

    Scenarios: RHEL scenarios
      | type         | proc_name | db_type     | db_proc_name | management_app |
      | ruby-1.8     | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | ruby-1.8     | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |
      | perl-5.10    | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | perl-5.10    | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |
      | php-5.3      | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | php-5.3      | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |
      | ruby-1.9     | httpd     | mongodb-2.2 | mongod       | rockmongo-1.1  |
      | ruby-1.9     | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.4 |

  @fedora-only
  Scenario Outline: Use ctl_all to start and stop an application with an embedded database (Fedora)
    Given a new <type> application, with <db_type> and <management_app>, verify that they are running using <proc_name> and <db_proc_name>
    
    Scenarios: Fedora 18 scenarios
      | type         | proc_name | db_type     | db_proc_name | management_app |
      | perl-5.16    | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.5 |
      | php-5.4      | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.5 |
      | ruby-1.9     | httpd     | mysql-5.1   | mysqld       | phpmyadmin-3.5 |