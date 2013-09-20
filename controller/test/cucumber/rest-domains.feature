@broker_api
@broker_api3
Feature: domains
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Update and Delete domains
  
  Scenario Outline: List domains
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a GET request to "/domains"
    Then the response should be "200"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Create domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "name=api<random>"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Create domain with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name="
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:""
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:"name=cucum?ber"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a POST request to "/domains" with the following:"name=namethatistoolongtobeavaliddomain"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Retrieve domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=api<random>"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Retrieve non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Update domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=apix<random>"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Update domain with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"name="
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a PUT request to "/domains/api<random>" with the following:""
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=133"
    When I send a PUT request to "/domains/api<random>" with the following:"name=api?"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a PUT request to "/domains/api<random>" with the following:"name=namethatistoolongtobeavaliddomain"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=106"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=api<random>"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |

  Scenario Outline: Update non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a PUT request to "/domains/apix<random>" with the following:"name=apiY<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |

  Scenario Outline: Update domain with applications
    #Given a new user, verify updating a domain with an php-<php_version> application in it over <format> format
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=128"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=apix<random>"

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
     
  Scenario Outline: Update the domain of another user
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    Given a new user

    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
     
  Scenario Outline: Delete domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "404"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
      
  Scenario Outline: Delete non-existent domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/apix<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Delete domain of another user
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    Given a new user

    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "404"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Delete domain with existing applications
    #Given a new user, verify deleting a domain with an php-<php_version> application in it over <format> format
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=128"
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

  Scenario Outline: Delete domain with existing applications
    #Given a new user, verify force deleting a domain with an php-<php_version> application in it over <format> format
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-<php_version>"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>?force=true"
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
     
  Scenario Outline: Create more than one domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "name=api<random>"
    When I send a POST request to "/domains" with the following:"name=apix<random>"
    Then the response should be "409"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Create duplicate domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "409"
    And the error message should have "severity=error&exit_code=103"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |

    
