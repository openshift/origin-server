@runtime_extended
@runtime_extended3
Feature: Descriptor parsing and elaboration tests

  Scenario: Descriptor parsing
    Given an accepted node
    And a descriptor file is provided
    When the descriptor file is parsed as a cartridge
    Then the descriptor profile exists
    And atleast 1 component exists


  #Scenario: Descriptor elaboration of empty application
    #Given an accepted node
    #When a new application object with no framework is created
    #And the application is elaborated
    #Then the application contains atleast one group instance
    #And the application contains atmost one group instance
#
  #Scenario: Descriptor elaboration of application with dependencies
    #Given an accepted node
    #When a new application object with php-5.3 framework is created
    #And the application is elaborated
    #Then the application contains atleast one group instance
    #And the application contains atmost one group instance
    #And the application does contain php-5.3 components
#
  #Scenario: Descriptor elaboration after dynamically adding and removing dependencies
    #Given an accepted node
    #When a new application object with php-5.3 framework is created
    #And the application is elaborated
    #Then the application does contain php-5.3 components
    #When the cartridge mongodb-2.2 is added
    #And the application is elaborated
    #Then the application does contain mongodb-2.2 components
    #When the cartridge mongodb-2.2 is removed
    #And the application is elaborated
    #Then the application does not contain mongodb-2.2 components
#
