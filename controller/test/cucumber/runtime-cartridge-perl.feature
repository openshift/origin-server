@runtime_extended3
Feature: V2 SDK Perl Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new perl-5.10 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the perl-5.10 cartridge private endpoints will be exposed
  And the perl-5.10 PERL_DIR env entry will exist
  And the perl-5.10 PERL_LOG_DIR env entry will exist
  And the perl-5.10 PERL_VERSION env entry will exist

  Scenario: Destroy application
  Given a v2 default node
  Given a new perl-5.10 type application
  When I destroy the application
  Then the application git repo will not exist
