@runtime
@runtime2
@not-origin
Feature: PHP Application

  Scenario: Test Alias Hooks
    Given a new php-5.3 type application
    And I add-alias the php application
    Then the php application will be aliased
    And the php file permissions are correct
    When I remove-alias the php application
    Then the php application will not be aliased 
    When I destroy the application
    Then the application http proxy file will not exist
