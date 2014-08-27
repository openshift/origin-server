@cartridge_amq
@xpaas
@amq

Feature: Cartridge Lifecycle AMQ Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
#    When 1 <cart_name> applications are created
    When I create a amq app
    Given an existing <cart_name> application
    Then the application should be accessible with path /hawtio/index.html

#  Scenario: Application Restarting
#    Given an existing <cart_name> application
    When the application is restarted
    Then the application should be accessible with path /hawtio/index.html

    When a container named mqc is created using the example-mq profile
    Then 2 containers should exist
    
    Given an existing application named mqc
    Then the logs should contain Sent: test message
    And the logs should contain Received test message
      

#  Scenario: Application Destroying
    Given an existing <cart_name> application
    When the application is destroyed
    Then the application should not be accessible with path /hawtio/index.html

    Scenarios: Version scenarios
      | cart_name    |
      | amq |
