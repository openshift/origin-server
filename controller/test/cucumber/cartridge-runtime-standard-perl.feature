#@runtime_extended2
@runtime_extended_other2
@runtime
Feature: Cartridge Runtime Standard Checks (Perl)

  @rhel-only
  Scenario: Perl cartridge checks (RHEL/CentOS)
    Given a new perl-5.10 application, verify it using httpd

  @fedora-only
  Scenario: Perl cartridge checks (Fedora)
    Given a new perl-5.16 application, verify it using httpd
