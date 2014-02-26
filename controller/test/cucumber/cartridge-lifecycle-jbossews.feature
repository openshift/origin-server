@cartridge_extended3
@cartridge_extended
@jboss
@jbossews

Feature: Cartridge Lifecycle JBossEWS Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible

#  Scenario: Application Modification
    Given an existing <cart_name> application
    And JAVA_OPTS_EXT is available
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible
    And the jvm is using JAVA_OPTS_EXT

#  Scenario: Application Restarting
#    Given an existing <cart_name> application
    When the application is restarted
    Then the application should be accessible

#  Scenario: Application Destroying
#    Given an existing <cart_name> application
    When the application is destroyed
    Then the application should not be accessible

    Scenarios: Version scenarios
      | cart_name    |
      | jbossews-1.0 |
      | jbossews-2.0 |
