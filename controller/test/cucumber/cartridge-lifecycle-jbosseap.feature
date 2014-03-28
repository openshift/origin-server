@cartridge_extended
@cartridge_extended2
@jboss
@jbosseap

Feature: Cartridge Lifecycle JBossEAP Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 jbosseap-6 applications are created
    Then the applications should display default content on first attempt

  #Scenario: Multiartifact 
    Given an existing jbosseap-6 application
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

  #Scenario: Application Restarting
    When the application is restarted
    Then the application should be accessible

  #Scenario: Application Tidy
    When I tidy the application
    Then the application should be accessible

  #Scenario: Application Modification and Snapshot 
    When I snapshot the application
    Then the application should be accessible
    When a new file is added and pushed to the client-created application repo
    And the application is changed
    Then it should be updated successfully
    And the application should be accessible
    When I restore the application
    Then the application should be accessible
    And the application should display default content on first attempt
    And the new file will not be present in the gear app-root repo

  #Scenario:  Editing standalone.xml via repository changes vs directly
    # Ensure normal repository edit of standalone.xml is seen.
    When a property with key repo1 and value repo1234 is added to the jboss repository config
    Then the application should be accessible
    And the JBOSSEAP config will contain a property with the value repo1234
    
    # Ensure direct edits to the standalone.xml get overwritten by the repo1234 config on app restart
    When a property with key direct1 and value direct1234 is added directly to the JBOSSEAP config
    And the application is restarted
    Then the JBOSSEAP config will not contain a property with the value direct1234
    Then the JBOSSEAP config will contain a property with the value repo1234
    
    # Ensure direct edits to the standalone.xml get overwritten by the backup config
    # on app restart, when there is no standalone.xml in the repository.
    When a property with key direct1 and value direct1234 is added directly to the JBOSSEAP config
    And the jboss repository config file is renamed
    #And the application is restarted
    Then the JBOSSEAP config will not contain a property with the value direct1234
    Then the JBOSSEAP config will contain a property with the value repo1234

    # Ensure the env variable override prevents direct edits from being overwritten
    # by repository content
    When a new environment variable key=DISABLE_OPENSHIFT_MANAGED_SERVER_CONFIG value=true is added
    And a property with key direct1 and value direct1234 is added directly to the JBOSSEAP config
    And the jboss repository config file is restored without restart
    And a property with key repo1b and value repo1234B is added to the jboss repository config
    Then the JBOSSEAP config will contain a property with the value direct1234
    # repo1234 value is still here because it was in the file when it was directly edited above
    Then the JBOSSEAP config will contain a property with the value repo1234
    Then the JBOSSEAP config will not contain a property with the value repo1234B

    # Ensure removing the env variable results in the repo1234 config taking over again
    When a new environment variable key=DISABLE_OPENSHIFT_MANAGED_SERVER_CONFIG value=false is added
    And the application is restarted
    Then the JBOSSEAP config will not contain a property with the value direct1234
    Then the JBOSSEAP config will contain a property with the value repo1234
    Then the JBOSSEAP config will contain a property with the value repo1234B        

  #Scenario: Application Destroying
    When the application is destroyed
    Then the application should not be accessible
