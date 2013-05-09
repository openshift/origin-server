@runtime_extended_other2
@runtime_extended2
Feature: Cartridge Runtime Extended Checks (Perl)

  @rhel-only
  @runtime_extended_other2
  @runtime_extended2
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new perl-5.10 application, verify when hot deploy is not enabled, it does change pid of httpd proc

  @fedora-only
  @runtime_extended2
  Scenario Outline: Hot deployment tests (Fedora)
    Given a new perl-5.16 application, verify when hot deploy is not enabled, it does change pid of httpd proc
