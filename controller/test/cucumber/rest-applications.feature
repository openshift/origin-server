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
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

    
  Scenario Outline: Create application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-5.3"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Create application with multiple cartridges
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-5.3&cartridges=mysql-5.1&cartridges=phpmyadmin-3.4&initial_git_url=https://github.com/openshift/wordpress-example"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-5.3"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Create application with invalid cartridge combinations
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=mysql-5.1&cartridges=phpmyadmin-3.4"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-5.3&cartridges=ruby-1.9"
    Then the response should be "422"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Create application with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=&cartridge=php-5.3"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"cartridge=php-5.3"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app?one&cartridge=php-5.3"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=appone1234567890123456789012345678901234567890&cartridge=php-5.3"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Retrieve application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=php-5.3"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Start application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Stop application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Restart application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Force-stop application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=force-stop"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
  
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
  
  @rhel-only
  Scenario Outline: Threaddump application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=ruby-1.8"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=thread-dump"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
  Scenario Outline: Add and remove application alias
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
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
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
  
  Scenario Outline: Delete application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "404"
  
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Create duplicate application
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=100"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

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
     | JSON | 
     | XML | 

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
     | JSON | 
     | XML | 

  Scenario Outline: Retrieve application descriptor
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3,mysql-5.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Stop and Start embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=start"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Restart embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"  
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3,mysql-5.1" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  Scenario Outline: Remove embedded cartridge
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3,mysql-5.1" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "204"
  
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
     
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
     | JSON | 
     | XML | 
     
  Scenario Outline: add application or application event to a non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains/bogus/applications" with the following:"name=app&cartridge=jbossas-7"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    When I send a POST request to "/domains/bogus/applications/app/events" with the following:"event=scale-up"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Resolve application dns
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/dns_resolvable"
    Then the response should be one of "200,404"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

