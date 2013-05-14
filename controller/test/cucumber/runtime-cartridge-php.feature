@runtime1
Feature: V2 SDK PHP Cartridge

  Scenario Outline: Add cartridge
    Given a v2 default node
    Given a new <cart_name> type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the <cart_name> cartridge private endpoints will be exposed
    And the <cart_name> PHP_VERSION env entry will exist
    When I destroy the application
    Then the application git repo will not exist

    @rhel-only
    Scenarios: RHEL scenarios
      | cart_name |
      | php-5.3   |

    @fedora-19-only
    Scenarios: RHEL scenarios
      | cart_name |
      | php-5.5   |
