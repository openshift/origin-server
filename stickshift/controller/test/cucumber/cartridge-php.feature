@internals
@internals2
@node
Feature: PHP Application

  Scenario: Create Delete one PHP Application
    Given a new guest account
    And the guest account has no application installed
    When I configure a php application
    Then a php application http proxy file will exist
    And a php application git repo will exist
    And a php application source tree will exist
    And a php application httpd will be running 
    And php application log files will exist
    And the file permissions are correct
    When I deconfigure the php application
    Then a php application http proxy file will not exist
    And a php application git repo will not exist
    And a php application source tree will not exist
    And a php application httpd will not be running

  Scenario: Start/Stop/Restart one PHP Application
    Given a new guest account
    And the guest account has no application installed
    When I configure a php application
    And I stop the php application
    Then the php application will not be running
    And a php application httpd will not be running
    And the php application is stopped
    When I start the php application
    Then the php application will be running
    And a php application httpd will be running
    When I status the php application
    Then the php application will be running
    When I restart the php application
    Then the php application will be running
    And a php application httpd will be running
    When I deconfigure the php application
    Then a php application http proxy file will not exist

  Scenario: Test Alias Hooks
    Given a new guest account
    And the guest account has no application installed
    When I configure a php application
    And I add-alias the php application
    Then the php application will be aliased
    When I remove-alias the php application
    Then the php application will not be aliased 
    When I deconfigure the php application
    Then a php application http proxy file will not exist

