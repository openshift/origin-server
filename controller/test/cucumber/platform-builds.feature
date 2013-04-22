@runtime_other
Feature: V2 SDK Mock Cartridge Build Tests

  Scenario: Exercise hot deployment
    Given a v2 default node
    Given a new mock-0.1 type application
    Then the application git repo will exist

    When the application is made publicly accessible 
    And the application is prepared for git pushes
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    And the mock control_start marker will exist
    And the mock control_build marker will exist

    When the mock control_start marker is removed
    And the mock control_stop marker is removed
    And the mock control_build marker is removed
    And the application hot deploy marker is added
    Then the mock control_stop marker will not exist
    Then the mock control_start marker will not exist
    And the mock control_build marker will exist

    When the mock control_build marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will not exist
    Then the mock control_start marker will not exist

    When the mock control_build marker is removed
    And the application hot deploy marker is removed
    Then the mock control_stop marker will exist
    Then the mock control_start marker will exist
    And the mock control_build marker will exist

    When the mock control_build marker is removed
    And the mock control_start marker is removed
    And the mock control_stop marker is removed
    And a simple update is pushed to the application repo
    Then the mock control_stop marker will exist
    Then the mock control_start marker will exist
    And the mock control_build marker will exist
    