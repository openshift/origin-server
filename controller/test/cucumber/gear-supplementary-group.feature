Feature: Gear Supplementary Group 
  @gear_supplementary_group
  @gear_supplementary_group_test_1
  Scenario: Adding a single supplementary group when creating new gears on a node
    And the group "groupFoo" is added on the node
    And the group "groupFoo" is assigned as supplementary group to upcoming new gears on the node 
    When a new client created scalable mock-0.1 application
    Then the application should be assigned to the supplementary group "groupFoo" as shown by the node's /etc/group
    And the application has the group "groupFoo" as a secondary group 

    #For clean up 
    And I delete the supplementary group setting from /etc/openshift/node.conf
    And the group "groupFoo" is deleted from the node

  @gear_supplementary_group
  @gear_supplementary_group_test_2
  Scenario: Adding multiple supplementary group when creating new gears on a node
    And the group "groupFoo1" is added on the node
    And the group "groupFoo2" is added on the node
    And the groups "groupFoo1,groupFoo2" is assigned as supplementary groups to upcoming new gears on the node
    When a new client created scalable mock-0.1 application
    Then the application should be assigned to the supplementary groups "groupFoo1,groupFoo2" as shown by the node's /etc/group
    And the application has the group "groupFoo1" as a secondary group 
    And the application has the group "groupFoo2" as a secondary group 

    #For clean up 
    And I delete the supplementary group setting from /etc/openshift/node.conf
    And the group "groupFoo1" is deleted from the node
    And the group "groupFoo2" is deleted from the node

  @gear_supplementary_group
  @gear_supplementary_group_test_3
  Scenario: Attempting to add non-existent group as supplementary group when creating new gears should not update the new gears' groups
    #"groupNull" does not exist on the node
    When the group "groupNull" is assigned as supplementary group to upcoming new gears on the node
    Then creating a new client mock-0.1 application should fail

    #For clean up 
    And I delete the supplementary group setting from /etc/openshift/node.conf

