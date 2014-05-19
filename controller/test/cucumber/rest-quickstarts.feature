@broker_api
@broker_api4
Feature: quickstarts
  As an API client
  In order to do things with quickstarts
  I want to List and Show quickstarts without authenticating

  Scenario: List quickstarts
    Given I accept "JSON"
    When I send an unauthenticated GET request to "/quickstarts"
    Then the response should be "200"
    And the response should be a list of "quickstarts"

  Scenario: Get a specific quickstart
    Given I accept "JSON"
    And a quickstart UUID
    When I send an unauthenticated GET request to "/quickstarts/<uuid>"
    Then the response should be "200"
    And the response should be a "quickstart"

  Scenario: Get community quickstart URLs
    Given I accept "JSON"
    #And the Rails openshift configuration key community_base_url is "/community/"
    When I send an unauthenticated GET request to "/api"
    Then the response should be "200"
    And the response should have the links "LIST_QUICKSTARTS, SHOW_QUICKSTART"

