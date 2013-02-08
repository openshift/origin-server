@runtime_other
Feature: V2 SDK Mock Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new mock type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the mock cartridge private endpoints will be exposed
  And the mock setup_version marker will exist
  And the mock setup_failure marker will not exist
  And the mock MOCK_EXAMPLE env entry will exist
  And the mock MOCK_SERVICE_URL env entry will exist

  Scenario: Destroy application
  Given a v2 default node
  Given a new mock type application
  When I destroy the application
  Then the application git repo will not exist

  Scenario: Start application
  Given a v2 default node
  Given a new mock type application
  When I start the application
  Then the mock control_start marker will exist

  Scenario: Stop application
  Given a v2 default node
  Given a new mock type application
  When I start the application
  Then the mock control_start marker will exist
  When I stop the application
  Then the mock control_stop marker will exist

  Scenario: Application status
  Given a v2 default node
  Given a new mock type application
  When I status the application
  Then the mock control_status marker will exist

  Scenario: Restart application
  Given a v2 default node
  Given a new mock type application
  When I restart the application
  Then the mock control_restart marker will exist  

  # Scenario: Update application

  # Scenario: Add cartridge w/ user-specified repo

  # Scenario: Move
 
  # Scenario: Tidy

  # Scenario: Access via SSH