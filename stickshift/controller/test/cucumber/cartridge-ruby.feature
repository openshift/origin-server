@internals
@internals2
@node
Feature: RUBY Application

  # runcon -u ?? -r system_r -t libra_initrc_t

  Scenario: Create Delete one RUBY Application
    Given a new guest account
    And the guest account has no application installed

    When I configure a ruby application
    Then a ruby application http proxy file will exist
    And a ruby application git repo will exist
    And a ruby application source tree will exist
    And a ruby application httpd will be running 
    And ruby application log files will exist

    When I stop the ruby application
    Then the ruby application will not be running
    And a ruby application httpd will not be running
    And the ruby application is stopped

    When I start the ruby application
    Then the ruby application will be running
    And a ruby application httpd will be running

    When I deconfigure the ruby application
    Then a ruby application http proxy file will not exist
    And a ruby application git repo will not exist
    And a ruby application source tree will not exist
    And a ruby application httpd will not be running

  Scenario: Push a code change to a new Ruby application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed
    When I configure a ruby application
    And the application is prepared for git pushes
    Then a ruby application httpd will be running 
    When the ruby-1.8 application code is changed
    Then a ruby application httpd will be running 
    And the ruby-1.8 application should change pids