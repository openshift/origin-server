@internals
@internals1
@node
Feature: JBossEAP Application

   Scenario: Create Delete one JBoss AS Application
     Given an accepted node
     And a new guest account
     When I configure a jbosseap application
     Then a jbosseap application directory will exist
     And the jbosseap application directory tree will be populated
     And the jbosseap server and module files will exist
     And the jbosseap server configuration files will exist
     And the jbosseap standalone scripts will exist
     And a jbosseap git repo will exist
     And the jbosseap git hooks will exist
     And a jbosseap source tree will exist
     And a jbosseap deployments directory will exist
     And the maven repository will exist
     #And the openshift environment variable files will exist
     And a jbosseap service startup script will exist
     And a jbosseap application http proxy file will exist
     And a jbosseap application http proxy directory will exist
     And a jbosseap daemon will be running
     And the jbosseap daemon log files will exist
     When I deconfigure the jbosseap application
     Then a jbosseap application http proxy file will not exist
     Then a jbosseap application directory will not exist
     And a jbosseap git repo will not exist
     And a jbosseap source tree will not exist
     And the maven repository will not exist
     #And the openshift environment variable files will not exist
     And a jbosseap daemon will not be running     

   Scenario: Stop Start Restart a JBoss AS Application
     Given an accepted node
     And a new guest account
     And a new jbosseap application
     And the jbosseap service is running
     When I stop the jbosseap service
     Then a jbosseap daemon will not be running
     And the jbosseap service is stopped
     When I start the jbosseap service
     Then a jbosseap daemon will be running
     When I restart the jbosseap service
     Then a jbosseap daemon will be running
     

