#@runtime_other2
@runtime
@runtime2
Feature: PHP Application

  Scenario Outline: Test Alias Hooks
    Given a new <php_version> type application
    And I add an alias to the application
    Then the php application will be aliased
    And the php file permissions are correct
    When I remove an alias from the application
    Then the php application will not be aliased 
    When I destroy the application
    Then the http proxy will not exist

    @fedora-only
    Scenario: Fedora 18
     | php_version |
     | php-5.4     |

    @rhel-only
    Scenario: RHEL
     | php_version |
     | php-5.3     |
