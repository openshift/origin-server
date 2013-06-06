@broker_api
@broker_api1
Feature: keys
  As an API client
  In order to do things with keys
  I want to List, Create, Retrieve, Update and Delete keys
  
  Scenario Outline: List keys
    Given a new user
    And I accept "<format>"
    When I send a GET request to "/user/keys"
    Then the response should be "200"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Create key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123567"
    Then the response should be "201"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123567"

    Scenarios:
     | format | 
     | JSON   |
     | XML    |


  Scenario Outline: Create key with with blank, missing and invalid content
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123=567[dfhhfl]"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content="
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |

  Scenario Outline: Create key with with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=cucum?*ber&type=ssh-rsa&content=XYZ123"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"name=&type=ssh-rsa&content=XYZ123"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"type=ssh-rsa&content=XYZ123"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"name=cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc&type=ssh-rsa&content=XYZ123"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
 
  Scenario Outline: Create key with blank, missing and invalid type
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-xyz&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a POST request to "/user/keys" with the following:"name=api&type=&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a POST request to "/user/keys" with the following:"name=api&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Retrieve key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
     
  Scenario Outline: Retrieve non-existent key
    Given a new user
    And I accept "<format>"
    When I send a GET request to "/user/keys/api"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
  
  Scenario Outline: Update key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content=ABC890"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=ABC890"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    

  Scenario Outline: Update key with with blank, missing and invalid content
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content="
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content=ABC8??#@@90"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Update key with blank, missing and invalid type
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a PUT request to "/user/keys/api" with the following:"type=&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a PUT request to "/user/keys/api" with the following:"&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-abc&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Update non-existent key
    Given a new user
    And I accept "<format>"
    When I send a PUT request to "/user/keys/api1" with the following:"type=ssh-rsa&content=ABC890"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Delete key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a POST request to "/user/keys" with the following:"name=api1&type=ssh-rsa&content=XYZ123456"
    Then the response should be "201"
    When I send a DELETE request to "/user/keys/api1"
    Then the response should be "200"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Delete last key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a DELETE request to "/user/keys/api"
    Then the response should be "200"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Delete non-existent key
    Given a new user
    And I accept "<format>"
    When I send a DELETE request to "/user/keys/api"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |
    
  Scenario Outline: Create duplicate key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123"
    Then the response should be "201"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ1234"
    Then the response should be "409"
    When I send a POST request to "/user/keys" with the following:"name=apiX&type=ssh-rsa&content=XYZ123"
    Then the response should be "409"
    
    Scenarios:
     | format | 
     | JSON   |
     | XML    |

  
    


    
