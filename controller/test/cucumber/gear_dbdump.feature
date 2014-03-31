Feature: gear_dbdump.feature
  # @author ofayans@redhat.com
  # @testcase_id 
  Scenario Outline: Dbdump 
    Given a new mock-0.1 type application
    And the application is made publicly accessible
    When I embed a <cartridge> cartridge into the application
    Then I can run "gear dbdump > test.tar.gz" with exit code: 0
    Examples:
     |cartridge|
     |postgresql-9.2|
     |mysql-5.5|
     |mongodb-2.4|
