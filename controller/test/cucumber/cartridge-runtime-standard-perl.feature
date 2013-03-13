@runtime
Feature: Cartridge Runtime Standard Checks (Perl)

  #@runtime_other2
  @runtime2
  Scenario Outline: Perl cartridge checks
    Given a new <perl_version> application, verify it using httpd
  
    @rhel-only
    Scenarios: RHEL scenarios
      | perl_version |
      | perl-5.10    |
      
    @fedora-only
    Scenarios: Fedora 18 scenarios
      | perl_version |
      | perl-5.16    |