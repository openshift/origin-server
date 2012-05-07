@api
Feature: gear-groups
  As an API client
  I want to check the application state on each of the gears within each gear group

  Scenario Outline: Check application state on gear with xml
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"id=cucumber<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/cucumber<random>/applications" with the following:"name=app&cartridge=php-5.3"
    Then the response should be "201"

    When I send a GET request to "/domains/cucumber<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a GET request to "/domains/cucumber<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=stopped"

    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a GET request to "/domains/cucumber<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a POST request to "/domains/cucumber<random>/applications/app/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a GET request to "/domains/cucumber<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a DELETE request to "/domains/cucumber<random>/applications/app"
    Then the response should be "204"

    Scenarios:
     | format |
     | XML |
