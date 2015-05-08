Feature: Adding and deleting domain environment variable

  @node_extended3
  @domain_env_var_test_1
  Scenario: Add and remove new env variable after creating applications that are in the same namespace
    And a new client created mock-0.1 application named "mock01app1" in the namespace "randomNamespaceA"
    And an additional client created mock-0.1 application named "mock01app2" in the namespace "randomNamespaceA"
    And an additional client created scalable mock-0.1 application named "mock01app3" in the namespace "randomNamespaceA"

    When the domain environment variable TEST_VAR_1 with value 'Foo' is added in the namespace "randomNamespaceA"
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the namespace "randomNamespaceA"

    When the domain environment variable TEST_VAR_1 is deleted in the namespace "randomNamespaceA"
    Then the domain environment variable TEST_VAR_1 will not exist for all the applications in the namespace "randomNamespaceA" 


  @node_extended3
  @domain_env_var_test_2
  Scenario: Add and remove new env variable in between setting up the applications in the same namespace
    And a new client created mock-0.1 application named "mock01app1" in the namespace "randomNamespaceA"

    When the domain environment variable TEST_VAR_1 with value 'Foo' is added in the namespace "randomNamespaceA"
    And an additional client created mock-0.1 application named "mock01app2" in the namespace "randomNamespaceA"

    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the namespace "randomNamespaceA"

    When the domain environment variable TEST_VAR_1 is deleted in the namespace "randomNamespaceA"
    Then the domain environment variable TEST_VAR_1 will not exist for all the applications in the namespace "randomNamespaceA"   


  @node_extended3
  @domain_env_var_test_3
  Scenario: Adding a domain env variable in a first namespace should not update the new application created in another namespace
    And a new client created mock-0.1 application named "mock01app1" in the namespace "randomNamespaceA"
    And an additional client created mock-0.1 application named "mock01app2" in the namespace "randomNamespaceA"

    When the domain environment variable TEST_VAR_1 with value 'Foo' is added in the namespace "randomNamespaceA"
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the namespace "randomNamespaceA"

    #Create another app in a different namespace then check to see if TEST_VAR_1 var that is for the previous namespace is not in the new namespace
    When a new client created mock-0.2 application named "mock02app3" in the namespace "randomNamespaceB"
    Then the domain environment variable TEST_VAR_1 will not exist for the application "mock02app3"

    When the domain environment variable TEST_VAR_2 with value 'Foo2' is added in the namespace "randomNamespaceB"
    And the domain environment variable TEST_VAR_2 will equal 'Foo2' for the application "mock02app3"
    And the domain environment variable TEST_VAR_2 will not exist for all the applications in the namespace "randomNamespaceA"


  @node_extended3
  @domain_env_var_test_4
  Scenario: Previously created application in a different namespace should not contain the domain variable added to another namespace

    And a new client created mock-0.1 application named "mock01app1" in the namespace "randomNamespaceA"
    And a new client created mock-0.1 application named "mock02app2" in the namespace "randomNamespaceB"
    And an additional client created mock-0.1 application named "mock01app3" in the namespace "randomNamespaceB"

    When the domain environment variable TEST_VAR_1 with value 'Foo' is added in the namespace "randomNamespaceB"
    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the namespace "randomNamespaceB"
    And the domain environment variable TEST_VAR_1 will not exist for the application "mock01app1"


  @node_extended3
  @domain_env_var_test_5
  Scenario: Adding a domain env variable to an empty namespace and only the applications to be created in the namespace will get the domain env variable

    When I create a new namespace called "randomNamespaceA"
    And the domain environment variable TEST_VAR_1 with value 'Foo' is added in the namespace "randomNamespaceA"
    And an additional client created mock-0.1 application named "mock01app1" in the namespace "randomNamespaceA"
    And an additional client created mock-0.1 application named "mock02app2" in the namespace "randomNamespaceA" 
    And a new client created mock-0.1 application named "mock01app3" in the namespace "randomNamespaceB"

    Then the domain environment variable TEST_VAR_1 will equal 'Foo' for all the applications in the namespace "randomNamespaceA"
    And the domain environment variable TEST_VAR_1 will not exist for the application "mock01app3"

  @node_extended3
  @domain_member_test_1
  Scenario: Add and remove a member from a namespace

    Given a new user with login "foo1" and namespace "bar1"
    Given a new user with login "foo2" and namespace "bar2"
    When the user "foo1" is added to the namespace "bar2"
    Then the user "foo1" is a member of the domain "bar2"
    When the user "foo1" is removed from the namespace "bar2"
    Then the user "foo1" is not a member of the domain "bar2"

  @node_extended3
  @domain_member_test_2
  Scenario: Add a member to a namespace and modify the members role

    Given a new user with login "foo1" and namespace "bar1"
    Given a new user with login "foo2" and namespace "bar2"
    When the user "foo1" is added to the namespace "bar2"
    Then the user "foo1" is a member of the domain "bar2"
    When the "foo1" user's role is modified to "edit" in the namespace "bar2"
    Then the user "foo1" has the role "edit" in the namespace "bar2"

