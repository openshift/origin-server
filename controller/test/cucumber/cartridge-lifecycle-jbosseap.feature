@runtime_extended
@runtime_extended2
@rhel-only
@not-fedora-19
@jboss
@jbosseap

Feature: Cartridge Lifecycle JBossEAP Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbosseap-6.0 applications are created
    Then the applications should display default content on first attempt

  #Scenario: Multiartifact 
    Given an existing jbosseap-6.0 application
    And JAVA_OPTS_EXT is available
    When the jboss application is changed to multiartifact
    Then the application should display default content for deployed artifacts on first attempt
    And default artifacts should be deployed
    And the jvm is using JAVA_OPTS_EXT

  #Scenario: Deployment Scanner Modification
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

  #Scenario: Management Interface Unavailable
    When the jboss management interface is disabled
    Then deployment verification should be skipped with management unavailable message

  #Scenario: Application Modification
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  #Scenario: Application Restarting
    When the application is restarted
    Then the application should be accessible

  #Scenario: Application Tidy
    When I tidy the application
    Then the application should be accessible

  #Scenario: Application Snapshot
    When I snapshot the application
    Then the application should be accessible
    When a new file is added and pushed to the client-created application repo
    When I restore the application
    Then the application should be accessible
    And the new file will not be present in the gear app-root repo

  #Scenario: Application Destroying
    When the application is destroyed
    Then the application should not be accessible
