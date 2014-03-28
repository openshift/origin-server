@cartridge_extended4
Feature: Python Cartridge

  Scenario Outline: Add python cartridge
    Given a new <cart_name> type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the <cart_name> cartridge private endpoints will be exposed
    And the <cart_name> PYTHON_DIR env entry will exist
    And the <cart_name> PYTHON_VERSION env entry will exist
    When I destroy the application
    Then the application git repo will not exist

    Scenarios: Python Versions
      |    cart_name     |
      |    python-2.7    |
