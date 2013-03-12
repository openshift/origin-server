@runtime_other
Feature: V2 SDK Ruby Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new ruby18 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the ruby18 cartridge private endpoints will be exposed
  And the ruby18 RUBY_DIR env entry will exist
  And the ruby18 RUBY_LOG_DIR env entry will exist
  And the ruby18 RUBY_VERSION env entry will exist

  Scenario: Destroy application
  Given a v2 default node
  Given a new ruby18 type application
  When I destroy the application
  Then the application git repo will not exist

#  Scenario: Start application
#  Given a v2 default node
#  Given a new ruby type application
#  When I start the application
#  Then the ruby control_stop marker will exist

#  Scenario: Stop application
#  Given a v2 default node
#  Given a new ruby type application
#  When I start the application
#  Then the ruby control_start marker will exist
#  When I stop the application
#  Then the ruby control_stop marker will exist

#  Scenario: Application status
#  Given a v2 default node
#  Given a new ruby type application
#  When I status the application
#  Then the ruby control_status marker will exist

#  Scenario: Restart application
#  Given a v2 default node
#  Given a new ruby type application
#  When I restart the application
#  Then the ruby control_restart marker will exist  

  # Scenario: Update application

  # Scenario: Add cartridge w/ user-specified repo

  # Scenario: Move
 
  # Scenario: Tidy

  # Scenario: Access via SSH
