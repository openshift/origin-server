@internals
@node
Feature: JBossAS Application

   Scenario: Create Delete one JBoss AS Application
     Given an accepted node
     And a new guest account
     When I configure a jbossas application
     Then a jbossas application directory will exist
     And the jbossas application directory tree will be populated
     And the jbossas server and module files will exist
     And the jbossas server configuration files will exist
     And the jbossas standalone scripts will exist
     And a jbossas git repo will exist
     And the jbossas git hooks will exist
     And a jbossas source tree will exist
     And a jbossas deployments directory will exist
     And the maven repository will exist
     #And the openshift environment variable files will exist
     And a jbossas service startup script will exist
     And a jbossas application http proxy file will exist
     And a jbossas application http proxy directory will exist
     And a jbossas daemon will be running
     And the jbossas daemon log files will exist
     When I deconfigure the jbossas application
     Then a jbossas application http proxy file will not exist
     Then a jbossas application directory will not exist
     And a jbossas git repo will not exist
     And a jbossas source tree will not exist
     And the maven repository will not exist
     #And the openshift environment variable files will not exist
     And a jbossas daemon will not be running     

   Scenario: Stop Start Restart a JBoss AS Application
     Given an accepted node
     And a new guest account
     And a new jbossas application
     And the jbossas service is running
     When I stop the jbossas service
     Then a jbossas daemon will not be running
     And the jbossas service is stopped
     When I start the jbossas service
     Then a jbossas daemon will be running
     When I restart the jbossas service
     Then a jbossas daemon will be running
     

