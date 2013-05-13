Feature: Cartridge Runtime Standard Checks (Perl)
  @runtime_extended_other2
  @runtime
  @rhel-only
  Scenario: Perl cartridge checks (RHEL/CentOS)
    Given a new perl-5.10 application, verify it using httpd

  @runtime_extended_other2
  @runtime
  @fedora-only
  Scenario: Perl cartridge checks (Fedora)
    Given a new perl-5.16 application, verify it using httpd

  @rhel-only
  @runtime_extended_other2
  @runtime_extended2
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new perl-5.10 application, verify when hot deploy is not enabled, it does change pid of httpd proc

  @fedora-only
  @runtime_extended2
  Scenario Outline: Hot deployment tests (Fedora)
    Given a new perl-5.16 application, verify when hot deploy is not enabled, it does change pid of httpd proc
