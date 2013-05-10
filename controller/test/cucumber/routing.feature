Feature: OpenShift routing tests 
  Scenario: Successful override of HTTP_HOST
    Given a new client created mock-0.1 application
    Then the application should be accessible
    When the http host header is overridden with a valid host, ensure routing succeeds

Scenario: UnSuccessful override of HTTP_HOST
    Given a new client created mock-0.1 application
    Then the application should be accessible
    When the http host header is overridden with an invalid host, ensure routing fails
