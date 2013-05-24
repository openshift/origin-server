Feature: Adding and deleteing domain environment variable

  @runtime_extended3
  @domain_env_var_1
  Scenario: Add and remove new env variable after creating applications that are in the same namespace
    Given a v2 default node
    And a new client created mock-0.1 application
    And an additional ruby-1.9 application in the same namespace as the previous application
    And an additional scalable python-2.6 application in the same namespace as the previous application
  
    When the domain environment variable TEST_VAR_1 with value 'Foo' is added
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the current namespace

    When the domain environment variable TEST_VAR_1 is deleted
    Then the domain environment variable TEST_VAR_1 will not exist for all the applications in the current namespace
 
    #For cleanup           
    And the applications are destroyed

 @runtime_extended3
  @domain_env_var_2
  Scenario: Add and remove new env variable in between setting up the applications in the same namespace
    Given a v2 default node
    And a new client created mock-0.1 application
    
    When the domain environment variable TEST_VAR_1 with value 'Foo' is added
    And an additional ruby-1.9 application in the same namespace as the previous application
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the current namespace

    When the domain environment variable TEST_VAR_1 is deleted
    Then the domain environment variable TEST_VAR_1 will not exist for all the applications in the current namespace
    
    #For cleanup
    And the applications are destroyed

  @runtime_extended3
  @domain_env_var_3
  Scenario: Add and remove new env variable in between setting up the applications in the same namespace
    Given a v2 default node
    And a new client created mock-0.1 application
    And an additional ruby-1.9 application in the same namespace as the previous application
   
    When the domain environment variable TEST_VAR_1 with value 'Foo' is added
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the current namespace

    #Create another app in a different namespace then check to see if TEST_VAR_1 var that is for the previous namespace is not in the new namespace
    When a new client created mock-0.2 application
    And the domain environment variable TEST_VAR_1 will not exist

    #For cleanup
    And the applications are destroyed


