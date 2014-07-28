@cartridge_fuse
@xpaas
@fuse

Feature: Cartridge Lifecycle Fuse Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    When 1 <cart_name> applications are created
    Given an existing <cart_name> application
    Then the application should be accessible with path /hawtio/index.html

#  Scenario: Application Restarting
#    Given an existing <cart_name> application
    When the application is restarted
    Then the application should be accessible with path /hawtio/index.html

#  Scenario: Application Destroying
#    Given an existing <cart_name> application
    When the application is destroyed
    Then the application should not be accessible with path /hawtio/index.html

    Scenarios: Version scenarios
      | cart_name    |
      | fuse |
