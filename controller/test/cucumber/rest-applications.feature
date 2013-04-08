@broker_api
@broker_api2
Feature: applications
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Start, Stop, Restart, Force-stop and Delete applications

  @rhel-only  
  Scenario Outline: List applications (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format and verify application list API
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
      
  @fedora-only  
  Scenario Outline: List applications (Fedora)
    Given a new user, create a php-<php_version> application using <format> format and verify application list API
    
    Scenarios: Fedora scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  @rhel-only  
  Scenario Outline: Create application (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format and verify application creation API
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
      
  @fedora-only  
  Scenario Outline: Create application (Fedora)
    Given a new user, create a php-<php_version> application using <format> format and verify application creation API
    
    Scenarios: Fedora scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  @rhel-only  
  Scenario Outline: Create application with multiple cartridges (RHEL/CentOS)
    Given a new user, create a php-<php_version> application with phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    
    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version |
      | JSON   |     5.3     |        3.4         |
      | XML    |     5.3     |        3.4         |
      
  @fedora-only  
  Scenario Outline: Create application with multiple cartridges (Fedora)
    Given a new user, create a php-<php_version> application with phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    
    Scenarios: Fedora 18 scenarios
    | format | php_version | phpmyadmin_version |
    | JSON   |     5.4     |         3.5        |
    | XML    |     5.4     |         3.5        |
     
  @rhel-only
  Scenario Outline: Create application with invalid cartridge combinations (RHEL/CentOS)
    Given a new user, create an invalid application with php-<php_version>, ruby-1.9, mysql-5.1, phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API

    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version |
      | JSON   |     5.3     |        3.4         |
      | XML    |     5.3     |        3.4         |

  @fedora-only
  Scenario Outline: Create application with invalid cartridge combinations (Fedora)
    Given a new user, create an invalid application with php-<php_version>, ruby-1.9, mysql-5.1, phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API

    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version |
      | JSON   |     5.4     |         3.5        |
      | XML    |     5.4     |         3.5        |

  @rhel-only
  Scenario Outline: Create application with blank, missing, too long and invalid name (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format with blank, missing, too long and invalid name and verify application creation API
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

  @fedora-only
  Scenario Outline: Create application with blank, missing, too long and invalid name (Fedora)
    Given a new user, create a php-<php_version> application using <format> format with blank, missing, too long and invalid name and verify application creation API

    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  @rhel-only
  Scenario Outline: Retrieve application (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify retrieving application details
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
      
  @fedora-only
  Scenario Outline: Retrieve application (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify retrieving application details
      
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  @rhel-only
  Scenario Outline: Start/Stop/Restart application (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify application <event> API
    
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

  @fedora-only
  Scenario Outline: Start/Stop/Restart application (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify application <event> API
  
    Scenarios: RHEL scenarios
      | format | php_version |    event    |
      | JSON   |     5.4     |    start    |
      | XML    |     5.4     |    start    |
      | JSON   |     5.4     |    stop     |
      | XML    |     5.4     |    stop     |
      | JSON   |     5.4     |   restart   |
      | XML    |     5.4     |   restart   |
      | JSON   |     5.4     | force-stop  |
      | XML    |     5.4     | force-stop  |

  @rhel-only
  Scenario Outline: Add and remove application alias (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify adding and removing application aliases
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

  @fedora-only
  Scenario Outline: Add and remove application alias (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify adding and removing application aliases

    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  
  @rhel-only
  Scenario Outline: Delete application (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify application deletion
  
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

  @fedora-only
  Scenario Outline: Delete application (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify application deletion

    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |


  @rhel-only
  Scenario Outline: Create duplicate application (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify that duplicate application creation fails
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
      
  @fedora-only
  Scenario Outline: Create duplicate application (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify that duplicate application creation fails
      
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  Scenario Outline: Create application with invalid, blank or missing cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
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
    When I send a POST request to "/domains" with the following:"id=api<random>"
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

  @rhel-only
  Scenario Outline: Retrieve application descriptor (RHEL/CentOS)
    Given a new user, create a php-<php_version> application using <format> format verify the application descriptor API

    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
      
  @fedora-only
  Scenario Outline: Retrieve application descriptor (Fedora)
    Given a new user, create a php-<php_version> application using <format> format verify the application descriptor API    
    
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |

  Scenario Outline: Stop and Start embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |

  Scenario Outline: Restart embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"  
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |

  Scenario Outline: Remove embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1,mysql-5.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "204"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "diy-0.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
  
    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |
     
  Scenario Outline: Scale-up and scale-down as application that is not scalable
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=diy-0.1"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-up"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-down"
    Then the response should be "422"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"

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
    When I send a POST request to "/domains" with the following:"id=api<random>"
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
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=ruby-1.9"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=thread-dump"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios: scenarios
      | format |
      | JSON   |
      | XML    |

