@broker_api
@broker_api2
Feature: applications
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Start, Stop, Restart, Force-stop and Delete applications

  Scenario Outline: List applications
    #Given a new user, create a php-<php_version> application using <format> format and verify application list API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |


  Scenario Outline: Create application
    #Given a new user, create a php-<php_version> application using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |


  Scenario Outline: Create application with multiple cartridges
    #Given a new user, create a php-<php_version> application with phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-<php_version>&cartridges=<database>&cartridges=phpmyadmin-<phpmyadmin_version>&initial_git_url=https://github.com/openshift/wordpress-example"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version | database  |
      | JSON   |     5.3     |        3.4         | mysql-5.1 |
      | XML    |     5.3     |        3.4         | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version | phpmyadmin_version | database    |
      | JSON   |     5.5     |        3.5         | mariadb-5.5 |
      | XML    |     5.5     |        3.5         | mariadb-5.5 |

  Scenario Outline: Create application with invalid cartridge combinations
    #Given a new user, create an invalid application with php-<php_version>, ruby-1.9, mysql-5.1, phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=<database>&cartridges=phpmyadmin-<phpmyadmin_version>"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-<php_version>&cartridges=ruby-<ruby_version>"
    Then the response should be "422"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version | database  | ruby_version |
      | JSON   |     5.3     |        3.4         | mysql-5.1 |      1.9     |
      | XML    |     5.3     |        3.4         | mysql-5.1 |      1.9     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version | phpmyadmin_version | database    | ruby_version |
      | JSON   |     5.5     |        3.5         | mariadb-5.5 |      2.0     |
      | XML    |     5.5     |        3.5         | mariadb-5.5 |      2.0     |


  Scenario Outline: Create application with blank, missing, too long and invalid name
    #Given a new user, create a php-<php_version> application using <format> format with blank, missing, too long and invalid name and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app?one&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=appone1234567890123456789012345678901234567890&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |

  Scenario Outline: Retrieve application
    #Given a new user, create a php-<php_version> application using <format> format verify retrieving application details
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=php-<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |

  Scenario Outline: Start/Stop/Restart application
    #Given a new user, create a php-<php_version> application using <format> format verify application <event> API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=<event>"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |    event    |
      | JSON   |     5.3     |    start    |
      | XML    |     5.3     |    start    |
      | JSON   |     5.3     |    stop     |
      | XML    |     5.3     |    stop     |
      | JSON   |     5.3     |   restart   |
      | XML    |     5.3     |   restart   |
      | JSON   |     5.3     | force-stop  |
      | XML    |     5.3     | force-stop  |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |    event    |
      | JSON   |     5.5     |    start    |
      | XML    |     5.5     |    start    |
      | JSON   |     5.5     |    stop     |
      | XML    |     5.5     |    stop     |
      | JSON   |     5.5     |   restart   |
      | XML    |     5.5     |   restart   |
      | JSON   |     5.5     | force-stop  |
      | XML    |     5.5     | force-stop  |

  Scenario Outline: Add and remove application alias
    #Given a new user, create a php-<php_version> application using <format> format verify adding and removing application aliases
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=php-<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |


  Scenario Outline: Delete application
    #Given a new user, create a php-<php_version> application using <format> format verify application deletion
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "404"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |

  Scenario Outline: Create duplicate application (RHEL/CentOS)
    #Given a new user, create a php-<php_version> application using <format> format verify that duplicate application creation fails
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=100"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version |
      | JSON   |     5.5     |
      | XML    |     5.5     |

  Scenario Outline: Create application with invalid, blank or missing cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=bogus"
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge="
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app"
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "404"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Retrieve or delete a non-existent application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=101"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=101"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Retrieve application descriptor
    #Given a new user, create a php-<php_version> application using <format> format verify the application descriptor API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=<database>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-<php_version>,<database>" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version | database  |
      | JSON   |     5.3     | mysql-5.1 |
      | XML    |     5.3     | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | php_version | database  |
      | JSON   |     5.5     | mariadb-5.5 |
      | XML    |     5.5     | mariadb-5.5 |

  Scenario Outline: Stop and Start embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=<database>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,<database>" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | database  |
      | JSON   | mysql-5.1 |
      | XML    | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | database  |
      | JSON   | mariadb-5.5 |
      | XML    | mariadb-5.5 |

  Scenario Outline: Restart embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=<database>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/cartridges/<database>"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,<database>" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | database  |
      | JSON   | mysql-5.1 |
      | XML    | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | database  |
      | JSON   | mariadb-5.5 |
      | XML    | mariadb-5.5 |

  Scenario Outline: Remove embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=<database>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,<database>" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/<database>"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | database  |
      | JSON   | mysql-5.1 |
      | XML    | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | database  |
      | JSON   | mariadb-5.5 |
      | XML    | mariadb-5.5 |

  Scenario Outline: Scale-up and scale-down as application that is not scalable
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-up"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-down"
    Then the response should be "422"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: add application or application event to a non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains/bogus/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    When I send a POST request to "/domains/bogus/applications/app/events" with the following:"event=scale-up"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"

    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |

  Scenario Outline: Resolve application dns
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/dns_resolvable"
    Then the response should be one of "200,404"

    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |

  Scenario Outline: threaddump an application with threaddump action available
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=ruby-<ruby_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=thread-dump"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | ruby_version |
      | JSON   |      1.9     |
      | XML    |      1.9     |

    @fedora-19-only
    Scenarios: Fedora 19 scenarios
      | format | ruby_version |
      | JSON   |      2.0     |
      | XML    |      2.0     |
