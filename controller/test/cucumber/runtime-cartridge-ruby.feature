Feature: V2 SDK Ruby Cartridge
  @runtime_extended3
  @cartridge_v2_ruby
  @cartridge_v2_ruby_19
  Scenario: Add cartridge, create and destroy an app
    Given a v2 default node
    Given a new ruby-1.9 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the ruby-1.9 cartridge private endpoints will be exposed
    And the ruby-1.9 RUBY_DIR env entry will exist
    And the ruby-1.9 RUBY_LOG_DIR env entry will exist
    And the ruby-1.9 RUBY_VERSION env entry will equal '1.9'
    ## 'passenger-status' can't be run in the gear context
    And a ruby process for Passenger will be running
    When I destroy the application
    Then the application git repo will not exist


  @runtime_extended1
  @cartridge_v2_ruby
  @cartridge_v2_ruby_18
  Scenario: Add cartridge, create and destroy an app
    Given a v2 default node
    Given a new ruby-1.8 type application
    Then the application git repo will exist
    And the platform-created default environment variables will exist
    And the ruby-1.8 cartridge private endpoints will be exposed
    And the ruby-1.8 RUBY_DIR env entry will exist
    And the ruby-1.8 RUBY_LOG_DIR env entry will exist
    And the ruby-1.8 RUBY_VERSION env entry will equal '1.8'
    ## 'passenger-status' can't be run in the gear context
    And a ruby process for Passenger will be running
    When I destroy the application
    Then the application git repo will not exist
