@runtime
Feature: Cartridge Runtime Standard Checks (Perl)

  #@runtime_other2
  @runtime2
  @rhel-only
  Scenario: Perl cartridge checks (RHEL/CentOS)
    Given a new perl-5.10 application, verify it using httpd

  @runtime2
  @fedora-only
  Scenario: Perl cartridge checks (Fedora)
    Given a new perl-5.16 application, verify it using httpd
