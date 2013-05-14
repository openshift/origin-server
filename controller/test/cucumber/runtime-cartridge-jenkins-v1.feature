@runtime_extended_other2
@rhel-only
@runtime
@jenkins
Feature: Jenkins Application

   Scenario: Create Delete one Jenkins Application
     #Given a new jenkins-1.4 application, verify it using java
     Given a new jenkins-1.4 type application
     Then the http proxy will exist
     And a java process will be running
     And the application git repo will exist
     And the application source tree will exist
     And the application log files will exist
     When I stop the application
     Then a java process will not be running
     When I start the application
     Then a java process will be running
     When I status the application
     Then a java process will be running
     When I restart the application
     Then a java process will be running
     When I destroy the application
     Then the http proxy will not exist
     And a java process will not be running
     And the application git repo will not exist
     And the application source tree will not exist
