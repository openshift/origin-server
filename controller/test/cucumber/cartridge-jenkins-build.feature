@jenkins
@runtime_extended1
@not-origin
Feature: Jenkins Application
  Scenario: Create and Deploy a DIY and Jenkins Application
    Given the libra client tools
    And an accepted node
    When I configure a hello_world diy application with jenkins enabled
    And I push an update to the diy application
    Then the application will be updated
    Then I deconfigure the diy application with jenkins enabled
