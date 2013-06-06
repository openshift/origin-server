@not-fedora-19
Feature: Cartridge Runtime Standard Checks (Perl)
  @runtime_extended_other2
  @runtime
  @rhel-only
  Scenario: Perl cartridge checks (RHEL/CentOS)
    #Given a new perl-5.10 application, verify it using httpd
    Given a new perl-5.10 type application
    Then the http proxy will exist
    And a httpd process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I stop the application
    Then a httpd process will not be running
    When I start the application
    Then a httpd process will be running
    When I status the application
    Then a httpd process will be running
    When I restart the application
    Then a httpd process will be running
    When I destroy the application
    Then the http proxy will not exist
    And a httpd process will not be running
    And the application git repo will not exist
    And the application source tree will not exist

  @rhel-only
  @runtime_extended_other2
  @runtime_extended2
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    #Given a new perl-5.10 application, verify when hot deploy is not enabled, it does change pid of httpd proc
    Given a new perl-5.10 type application
    And the application is made publicly accessible
    And hot deployment is not enabled for the application
    And the application cartridge PIDs are tracked
    When an update is pushed to the application repo
    Then a httpd process will be running
    And the tracked application cartridge PIDs should be changed
    When I destroy the application
    Then a httpd process will not be running
