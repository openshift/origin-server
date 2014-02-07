@broker_api
@broker_api3
Feature: domains
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Update and Delete domains

  Scenario Outline: Create, List, Update, Delete domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "name=api<random>"
    When I send a GET request to "/domains"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=api<random>"
    When the user has MAX_DOMAINS set to 1
    And I send a POST request to "/domains" with the following:"name=apix<random>"
    Then the response should be "409"
    When the user has MAX_DOMAINS set to 2
    And I send a POST request to "/domains" with the following:"name=apix<random>"
    Then the response should be "201"
    And the response should be a "domain" with attributes "name=apix<random>"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apiy<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=apiy<random>"
    When I send a DELETE request to "/domains/apiy<random>"
    Then the response should be "200"
    When I send a GET request to "/domains/apiy<random>"
    Then the response should be "404"
    When I send a DELETE request to "/domains/apiy<random>"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=127"

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

  Scenario Outline: Update, Delete domain with applications
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
    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=128"
    When I send a DELETE request to "/domains/api<random>?force=true"
    Then the response should be "200"

    Scenarios: RHEL scenarios
      | format | php_version |
      | JSON   |     5.3     |
      | XML    |     5.3     |

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

  Scenario Outline: Create duplicate domain
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When the user has MAX_DOMAINS set to 1
    And I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "409"
    And the error message should have "severity=error&exit_code=103"
    When the user has MAX_DOMAINS set to 2
    And I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=103"

    Scenarios:
     | format |
     | JSON   |
     | XML    |
