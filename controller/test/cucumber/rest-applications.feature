@broker_api
@broker_api2
Feature: applications
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Start, Stop, Restart, Force-stop and Delete applications
  
  Scenario Outline: List applications
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  Scenario Outline: Create application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  Scenario Outline: Create application with multiple cartridges
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=<php_version>&cartridges=mysql-5.1&cartridges=<phpmyadmin_version>&initial_git_url=https://github.com/openshift/wordpress-example"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version | phpmyadmin_version |
      | JSON   | php-5.3     | phpmyadmin-3.4     |
      | XML    | php-5.3     | phpmyadmin-3.4     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version | phpmyadmin_version |
      | JSON   | php-5.4     | phpmyadmin-3.5     |
      | XML    | php-5.4     | phpmyadmin-3.5     |
     
  Scenario Outline: Create application with invalid cartridge combinations
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=mysql-5.1&cartridges=<phpmyadmin_version>"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=<php_version>&cartridges=ruby-1.9"
    Then the response should be "422"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | phpmyadmin_version |
      | JSON   | phpmyadmin-3.4     |
      | XML    | phpmyadmin-3.4     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | phpmyadmin_version |
      | JSON   | phpmyadmin-3.5     |
      | XML    | phpmyadmin-3.5     |

  Scenario Outline: Create application with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=&cartridge=<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"cartridge=<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app?one&cartridge=<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=appone1234567890123456789012345678901234567890&cartridge=<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  Scenario Outline: Retrieve application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=<php_version>"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Start application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Stop application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Restart application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Force-stop application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=force-stop"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
  
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  
  @rhel-only
  Scenario Outline: Threaddump application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<ruby_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=thread-dump"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | ruby_version |
      | JSON   | ruby-1.8     |
      | XML    | ruby-1.8     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | ruby_version |
      | JSON   | ruby-1.9     |
      | XML    | ruby-1.9     |

  Scenario Outline: Add and remove application alias
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=add-alias"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=add-alias&alias=app-api.foobar.com"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=remove-alias&alias=app-api.foobar.com"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=add-alias&alias=app-@#$api.foobar.com"
    Then the response should be "422"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  
  Scenario Outline: Delete application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "404"
  
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Create duplicate application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=100"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


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

  Scenario Outline: Retrieve application descriptor
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<php_version>,mysql-5.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  Scenario Outline: Stop and Start embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<php_version>,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Restart embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"  
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<php_version>,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |


  Scenario Outline: Remove embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<php_version>,mysql-5.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<php_version>" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
  
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

     
     
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
    When I send a POST request to "/domains/bogus/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    When I send a POST request to "/domains/bogus/applications/app/events" with the following:"event=scale-up"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"

    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |

  Scenario Outline: Resolve application dns
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<php_version>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/dns_resolvable"
    Then the response should be one of "200,404"
    
    @rhel-only
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   | php-5.3     |
      | XML    | php-5.3     |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   | php-5.4     |
      | XML    | php-5.4     |
