@runtime
@runtime1
Feature: 10gen-mms-agent Embedded Cartridge

  Scenario Outline: Add Remove 10gen-mms-agent to one application
    Given a new <type> type application
    And I embed a mongodb-2.0 cartridge into the application
    And an agent settings.py file is created
    And I embed a 10gen-mms-agent-0.1 cartridge into the application

    Then 1 process named python will be running
    And the embedded 10gen-mms-agent-0.1 cartridge subdirectory named mms-agent will exist
    And the embedded 10gen-mms-agent-0.1 cartridge log files will exist
    And the embedded 10gen-mms-agent-0.1 cartridge control script named 10gen_mms_agent will exist

    When I stop the 10gen-mms-agent-0.1 cartridge
    Then 0 processes named python will be running

    When I start the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I restart the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I destroy the application
    Then 0 processes named python will be running
    And the embedded 10gen-mms-agent-0.1 cartridge subdirectory named mms-agent will not exist
    And the embedded 10gen-mms-agent-0.1 cartridge log files will not exist
    And the embedded 10gen-mms-agent-0.1 cartridge control script named 10gen_mms_agent will not exist

  Scenarios: Add Remove 10gen-mms-agent to one Application Scenarios
    |type|
    |php-5.3|
