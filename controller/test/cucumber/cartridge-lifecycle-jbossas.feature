@runtime_extended
@runtime_extended2
@not-enterprise
@jboss
@jbossas

Feature: Cartridge Lifecycle JBossAS Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbossas-7 applications are created
    Then the applications should display default content on first attempt
    Given an existing jbossas-7 application
    And JAVA_OPTS_EXT is available
    When the application is restarted
    Then the application should be accessible
    And the jvm is using JAVA_OPTS_EXT
    When the jboss application is changed to multiartifact
    Then the application should display default content for deployed artifacts on first attempt
    And default artifacts should be deployed
    When the jboss application deployment-scanner is changed to all
    Then the application should display default content for deployed artifacts on first attempt
    And all artifacts should be deployed
    When the jboss application deployment-scanner is changed to exploded only
    Then only exploded artifacts should be deployed
    When the jboss application deployment-scanner is changed to none
    Then no artifacts should be deployed
    When the jboss application deployment-scanner is changed to disabled
    Then deployment verification should be skipped with scanner disabled message
    When the jboss application deployment-scanner is changed to archive only
    Then only archive artifacts should be deployed
    When the jboss management interface is disabled
    Then deployment verification should be skipped with management unavailable message
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible
    When I tidy the application
    Then the application should be accessible
    When I snapshot the application
    Then the application should be accessible
    When a new file is added and pushed to the client-created application repo
    When I restore the application
    Then the application should be accessible
    And the new file will not be present in the gear app-root repo
    When the application is destroyed
    Then the application should not be accessible
