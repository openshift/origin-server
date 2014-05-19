@broker_api
@broker_api4
Feature: authentication
  As an API client
  I want make sure authentication is required whenever necessary

  Scenario Outline: Attempt unauthenticationed requests
    Given a new user
    And I manually set <header> to a valid user and User-Agent to <agent>
    When I send an unauthenticated GET request to "/domains"
    Then the response should be "401"

    Scenarios: Hacker
      | header        | agent |
      | X-Remote-User | openshift |
      | X-REMOTE-USER | openshift |
      | X_Remote_User | openshift |
      | X_REMOTE_USER | openshift |
      | X-Remote-User | poo |
      | Remote-User   | openshift |
      | REMOTE-USER   | openshift |
      | Remote_User   | openshift |
      | REMOTE_USER   | openshift |
      | Remote_User   | openshift_passthrough |

