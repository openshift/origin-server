@runtime_extended3
Feature: V2 SDK Python Cartridge

  @not-fedora-19
  Scenario: Add 2.6 cartridge
  Given a v2 default node
  Given a new python-2.6 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the python-2.6 cartridge private endpoints will be exposed
  And the python-2.6 PYTHON_DIR env entry will exist
  And the python-2.6 PYTHON_LOG_DIR env entry will exist
  And the python-2.6 PYTHON_VERSION env entry will exist

  @not-fedora-19
  Scenario: Destroy application
  Given a v2 default node
  Given a new python-2.6 type application
  When I destroy the application
  Then the application git repo will not exist

  Scenario: Add 2.7 cartridge
  Given a v2 default node
  Given a new python-2.7 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the python-2.7 cartridge private endpoints will be exposed
  And the python-2.7 PYTHON_DIR env entry will exist
  And the python-2.7 PYTHON_LOG_DIR env entry will exist
  And the python-2.7 PYTHON_VERSION env entry will exist
  When I destroy the application
  Then the application git repo will not exist
