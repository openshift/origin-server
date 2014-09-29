@cartridge_extended4
@not-enterprise
@jboss
@jbossas

Feature: Cartridge Lifecycle Wildfly Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jboss-wildfly-8 applications are created
    Then the applications should display default content on first attempt
    Given an existing jboss-wildfly-8 application
    When the application is restarted
    Then the application should be accessible

    # Ensure normal repository edit of standalone.xml is seen.
    When a property with key repo1 and value repo1234 is added to the wildfly repository config
    Then the application should be accessible
    And the WILDFLY config will contain a property with the value repo1234

    # Ensure direct edits to the standalone.xml get overwritten by the repo1234 config on app restart
    When a property with key direct1 and value direct1234 is added directly to the WILDFLY config
    And the application is restarted
    Then the WILDFLY config will not contain a property with the value direct1234
    Then the WILDFLY config will contain a property with the value repo1234

    When the application is destroyed
    Then the application should not be accessible
