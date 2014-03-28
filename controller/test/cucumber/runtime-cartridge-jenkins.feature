@jenkins
@cartridge_extended3
Feature: Jenkins Application
  Scenario: Create and Deploy a DIY and Jenkins Application
    Given the libra client tools
    When I configure a hello_world diy-0.1 application with jenkins enabled
    And I push an update to the diy application
    Then the diy application will be updated
    Then I deconfigure the application with jenkins enabled

  Scenario: Create and Deploy a downloadable Go cartridge and Jenkins Application
    Given the libra client tools
    When I configure a hello_world "https://cartreflect-claytondev.rhcloud.com/reflect?github=smarterclayton/openshift-go-cart" application with jenkins enabled
    And I push an update to the Go application
    Then the Go application will be updated
    Then I deconfigure the application with jenkins enabled
