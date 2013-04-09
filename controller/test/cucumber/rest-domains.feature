@broker_api
@broker_api3
Feature: domains
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Update and Delete domains
  
  Scenario Outline: List domains
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a GET request to "/domains"
    Then the response should be "200"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Create domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "id=api<random>"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Create domain with blank, missing, too long and invalid id
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id="
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:""
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:"id=cucum?ber"
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:"id=namethatistoolongtobeavaliddomain"
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Retrieve domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "id=api<random>"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Retrieve non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Update domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"id=apix<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "id=apix<random>"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Update domain with blank, missing, too long and invalid id
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"id="
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a PUT request to "/domains/api<random>" with the following:""
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a PUT request to "/domains/api<random>" with the following:"id=api?"
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a PUT request to "/domains/api<random>" with the following:"id=namethatistoolongtobeavaliddomain"
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=106"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "id=api<random>"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Update non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/apix<random>" with the following:"id=apiY<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

  @rhel-only     
  Scenario Outline: Update domain with applications
    Given a new user, verify updating a domain with an php-<php_version> application in it over <format> format  

    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

  @fedora-only     
  Scenario Outline: Update domain with applications
    Given a new user, verify updating a domain with an php-<php_version> application in it over <format> format  

    Scenarios: Fedora 18 scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |
     
     
  Scenario Outline: Update the domain of another user
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    Given a new user

    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    When I send a PUT request to "/domains/api<random>" with the following:"id=apix<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
     
  Scenario Outline: Delete domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "204"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML |
      
  Scenario Outline: Delete non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/apix<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML |   
     
  Scenario Outline: Delete domain of another user
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    Given a new user

    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "404"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML |  
     
  @rhel-only
  Scenario Outline: Delete domain with existing applications
    Given a new user, verify deleting a domain with an php-<php_version> application in it over <format> format  
    
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
  
  @fedora-only
  Scenario Outline: Delete domain with existing applications
    Given a new user, verify deleting a domain with an php-<php_version> application in it over <format> format      

    Scenarios: Fedora scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |
      
  @rhel-only
  Scenario Outline: Delete domain with existing applications
    Given a new user, verify force deleting a domain with an php-<php_version> application in it over <format> format  
  
    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |
  
  @fedora-only
  Scenario Outline: Delete domain with existing applications
    Given a new user, verify force deleting a domain with an php-<php_version> application in it over <format> format      

    Scenarios: Fedora scenarios
      | format | php_version |
      | JSON   |     5.4     |
      | XML    |     5.4     |      
     
  Scenario Outline: Create more than one domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "id=api<random>"
    When I send a POST request to "/domains" with the following:"id=apix<random>"
    Then the response should be "409"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 
     
  Scenario Outline: Create duplicate domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains" with the following:"id=api<random>"
    Then the response should be "422"
    And the error message should have "field=id&severity=error&exit_code=103"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

    
