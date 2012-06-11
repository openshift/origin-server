@verify
@verify2
Feature: Rest Quick tests
  As an developer I want to make sure I didn't break anything that is going to prevent others from working
    
  Scenario Outline: Typical Workflow
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=cucumber&type=ssh-rsa&content=XYZ123567"
    Then the response should be "201"
    And the response should be a "key" with attributes "name=cucumber&type=ssh-rsa&content=XYZ123567"
    When I send a GET request to "/user/keys/cucumber"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=cucumber&type=ssh-rsa&content=XYZ123567"
    When I send a POST request to "/domains" with the following:"id=cucumber<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/cucumber<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-5.3"
    When I send a GET request to "/domains/cucumber<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=php-5.3"
    When I send a GET request to "/domains/cucumber<random>/applications"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=force-stop"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=add-alias&alias=app-cucumber.foobar.com"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=remove-alias&alias=app-cucumber.foobar.com"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/cartridges" with the following:"cartridge=mysql-5.1"
    Then the response should be "201"
    When I send a GET request to "/domains/cucumber<random>/applications/app/descriptor"
    Then the response descriptor should have "php-5.3,mysql-5.1" as dependencies
    When I send a POST request to "/domains/cucumber<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/cucumber<random>/applications/app/cartridges/mysql-5.1/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/cucumber<random>/applications/app/cartridges/mysql-5.1"
    Then the response should be "200"
    When I send a PUT request to "/domains/cucumber<random>" with the following:"id=cucumberX<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "id=cucumberX<random>"
    When I send a DELETE request to "/domains/cucumberX<random>/applications/app"
    Then the response should be "204"
    When I send a GET request to "/domains/cucumberX<random>/applications/app"
    Then the response should be "404"
    When I send a DELETE request to "/domains/cucumberX<random>"
    Then the response should be "204"
    When I send a DELETE request to "/user/keys/cucumber"
    Then the response should be "204"
    
    Scenarios:
     | format | 
     | JSON | 
     | XML | 

