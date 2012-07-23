@runtime
Feature: RUBY Application

  @runtime2
  Scenario Outline: Create Delete one RUBY Application
    Given a new guest account
    And the guest account has no application installed

    When I configure a ruby-<version> application
    Then a ruby application http proxy file will exist
    And a ruby application git repo will exist
    And a ruby-<version> application source tree will exist
    And a ruby application httpd will be running 
    And ruby application log files will exist

    When I stop the ruby-<version> application
    Then the ruby-<version> application will not be running
    And a ruby application httpd will not be running
    And the ruby-<version> application is stopped

    When I start the ruby-<version> application
    Then the ruby-<version> application will be running
    And a ruby application httpd will be running

    When I deconfigure the ruby-<version> application
    Then a ruby application http proxy file will not exist
    And a ruby application git repo will not exist
    And a ruby-<version> application source tree will not exist
    And a ruby application httpd will not be running

  Scenarios: Create Delete one RUBY Application Scenarios
   | version |
   |   1.8   |
   |   1.9   |

  @runtime1
  Scenario Outline: Push a code change to a new Ruby application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed
    When I configure a ruby-<version> application
    And the application is prepared for git pushes
    Then a ruby application httpd will be running 
    When the ruby-<version> application code is changed
    Then a ruby application httpd will be running 
    And the ruby-<version> application should change pids

  Scenarios: Push a code change to a new Ruby application Scenarios
   | version |
   |   1.8   |
   |   1.9   |
