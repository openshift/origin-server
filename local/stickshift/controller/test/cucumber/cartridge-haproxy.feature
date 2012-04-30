@internals                                                                                                                                                                       
@node
Feature: HAProxy Application Sub-Cartridge
  
  Scenario Outline: Create Delete one application with haproxy
    Given an accepted node
    And a new gear with namespace "ns1" and app name "app1"
    And the guest account has no application installed
    When I configure a <type> application
    Then the <type> application will be running
    When I configure haproxy
    Then the haproxy directory will exist
    And the haproxy configuration file will exist
    And the haproxy PATH override will exist
    And the haproxy daemon will be running
    And the <type> application will not be running
#    And the status-page will respond
    When I deconfigure haproxy
    Then the haproxy daemon will not be running
    And the <type> application will be running
    And the haproxy PATH override will not exist
    And the haproxy configuration file will not exist
    And the haproxy directory will not exist
    When I deconfigure the <type> application
    And I delete the guest account
    Then an account password entry should not exist

  Scenarios: Create Delete Application With Database Scenarios
    |type|
    |php|
    |python|
    |nodejs|
    |perl|
    
#  Scenario Outline: Stop Start Restart a MySQL database
#    Given an accepted node
#    And a new guest account
#    And a new <type> application
#    And a new mysql database
#    And the mysql daemon is running
#    When I stop the mysql database
#    Then the mysql daemon will not be running
#    When I start the mysql database
#    Then the mysql daemon will be running
#    When I restart the mysql database
#    Then the mysql daemon will be running
#    And the mysql daemon pid will be different
#    And I deconfigure the mysql database
#
#  Scenarios: Stop Start Restart a MySQL database scenarios
#    |type|
#    |php|
