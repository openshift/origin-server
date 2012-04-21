@internals
@node
Feature: PERL Application

  Scenario: Create Delete one PERL Application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed

    When I configure a perl application
    Then a perl application http proxy file will exist
    And a perl application git repo will exist
    And a perl application source tree will exist
    And a perl application httpd will be running 
    And perl application log files will exist

    When I stop the perl application
    Then the perl application will not be running
    And a perl application httpd will not be running
    And the perl application is stopped

    When I start the perl application
    Then the perl application will be running
    And a perl application httpd will be running    

    When I deconfigure the perl application
    Then a perl application http proxy file will not exist
    And a perl application git repo will not exist
    And a perl application source tree will not exist
    And a perl application httpd will not be running   
