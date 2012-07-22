@runtime
@runtime1
Feature: PYTHON Application

  Scenario: Create Delete one PYTHON Application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed
    When I configure a python application
    Then a python application http proxy file will exist
    And a python application git repo will exist
    And a python application source tree will exist
    And a python application httpd will be running 
    And python application log files will exist

    When I stop the python application
    Then the python application will not be running
    And a python application httpd will not be running
    And the python application is stopped

    When I start the python application
    Then the python application will be running
    And a python application httpd will be running
 
    When I deconfigure the python application
    Then a python application http proxy file will not exist
    And a python application git repo will not exist
    And a python application source tree will not exist
    And a python application httpd will not be running

  Scenario: Push a code change to a new Python application
    Given an accepted node
    And a new guest account
    And the guest account has no application installed
    When I configure a python application
    And the application is prepared for git pushes
    Then a python application httpd will be running 
    When the python-2.6 application code is changed
    Then a python application httpd will be running 
    And the python-2.6 application should change pids
