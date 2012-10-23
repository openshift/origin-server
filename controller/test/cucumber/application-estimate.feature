@broker_api
@broker_api1
Feature: Application estimate
  As an OpenShift user
  Given an application descriptor, I should be able to estimate gear usage and 
  list of components that will reside on each gear before creating the application.

  Scenario: Estimate application gear usage
    Given a new user
    And I accept "JSON"
    When I provide applicaton descriptor with name 'TestApp1' and dependencies:'php-5.3,mysql-5.1' and groups:''
    Then the response should be "200"
	
  Scenario: Estimate application gear usage when groups are explicitly specified
    Given a new user
    And I accept "JSON"
    When I provide applicaton descriptor with name 'TestApp2' and dependencies:'php-5.3,mysql-5.1' and groups:'php-5.3;mysql-5.1'
    Then the response should be "200"
    And should get 1 gears
    And should get 1 gear with 'php-5.3,mysql-5.1' components
#FIXME: once group override is enabled, this scenario will fail and 
#       the correct expected result is given below
#    And should get 2 gears
#    And should get 1 gear with 'php-5.3' component
#    And should get 1 gear with 'mysql-5.1' component
