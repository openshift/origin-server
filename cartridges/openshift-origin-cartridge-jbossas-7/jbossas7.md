# JBoss AS 7 Cartridge #

The JBoss AS 7 cartridge relies upon functionlity from an abstract cartridge implementation. You should be familiar with the [Abstract Cartridge](../openshift-origin-cartridge-abstract/abstract-jboss/README.md) before reading the rest of this document.

This is the latest JBoss Application Server, more information about AS 7 can be found on the [JBoss AS site](http://www.jboss.org/jbossas)

       - openshift-origin-cartridge-jbossas-7
          ├── info
          │   ├── bin
          │   │   ├── build.sh
          │   │   ├── migrate_standalone_xml_as_user.sh
          │   │   ├── migrate_standalone_xml.sh
          │   │   ├── standalone.conf
          │   │   ├── standalone.sh
          │   │   └── update_namespace.sh
          │   ├── configuration
          │   │   ├── as-7.0.2-as-7.1.0-full.xsl
          │   │   ├── as-7.0.2-as-7.1.0.xsl
          │   │   ├── jenkins_job_template.xml
          │   │   ├── logging.properties
          │   │   ├── node_ssl_template.conf
          │   │   ├── postgresql_module.xml
          │   │   ├── settings.base.xml
          │   │   ├── settings.rhcloud.xml
          │   │   └── standalone.xml
          │   ├── control
          │   ├── hooks
          │   │   ├── jboss.version
          │   │   └── pre-install
          │   └── manifest.yml
          ├── java
          │   ├── build.xml
          │   └── src ...
          └── template
              ├── deployments
              │   └── .gitkeep
              ├── .openshift
              │   ├── action_hooks
              │   │   ├── build
              │   │   ├── deploy
              │   │   ├── post_deploy
              │   │   ├── post_start_jbossas-7
              │   │   ├── post_stop_jbossas-7
              │   │   ├── pre_build
              │   │   ├── pre_start_jbossas-7
              │   │   └── pre_stop_jbossas-7
              │   ├── config
              │   │   └── modules
              │   │       └── README
              │   ├── cron
              │   │   ├── ...
              │   └── markers
              │       ├── java7
              │       └── README
              ├── pom.xml
              ├── README
              └── src ...

### INFO ###

-control - This file lists package provides and dependencies, and cartridge conflicts, and meta info about the cartridge such as display name and description

-manifest.yml - this file lists meta info about the cartridge similar to the control file. (which set of meta info is used?).  This file also lists all the environment variables created, a list of packages provided. There is a publishes/subscribes for connectivity for http, jboss clustering, gear endpoints, database, rmi.

### BIN ###

- build.sh - When java applications are pushed to the remote git repository, the application needs to be compiled.  This script sets everything up to do a build, including the maven repo mirror, maven memory allocation.  You can change the build behavior by adding command marker files in your git repo under .openshift/markers (force_clean_build, java7).  Maven3 is used for the build.

- migrate_standalone_xml.sh - This script calls the migrate_standalone_xml_as_user.sh script after setting the the GIT and WORKING dir locations.

- migrate_standalone_xml_as_user.sh - This script transforms sets up the standalone.xml based upon the as-7.0.2-as-7.1.0.xsl file.  It does so by first clone the application git repo, then does an xsl transform, then commits the change and pushes the change to the application git repo.

- standalone.conf - This config file sets up the standalone configuration settings

- standalone.sh - This script starts JBoss EAP 7 using all the configuration settings from standalone.conf

- update_namespace.sh - This script changes the namespace of the hosts in the OPENSHIFT_JBOSSEAP_CLUSTER env var.  Namespace changes are initiated through the REST api and will change the DNS of existing gears.

### CONFIGURATION ###

- as-7.0.2-as-7.1.0-full.xsl - This file is used to configures the application server to load add the module extensions

- as-7.0.2-as-7.1.0.xsl - This file is used by the migrate_standalone_xml_as_user.sh.  Several of the module extensions are commented out, namely (org.jboss.as.cmp, org.jboss.as.configadmin, org.jboss.as.jacorb, org.jboss.as.jaxr, org.jboss.as.jsr77, org.jboss.as.messaging, org.jboss.as.osgi, org.jboss.as.remoting, org.jboss.as.webservices).  Additionally, the management interface is commented out.

- jenkins_job_template.xml - This config file is just as the name implies, it's just a template file used for all jenkins jobs.

- logging.properties - This config file is the logger properties for application server logging

- postgresql_module.xml - This config file adds the postgreqsql jdbc driver module

- settings.base.xml - This config file is empty by default, all the settings.*.xml file are for maven configuration

- settings.rhcloud.xml - This config file sets up the maven configuration, pointing to the OpenShift maven repository mirror

- standalone.xml - This config file is the default standalone.xml file.  This will get altered via the migrate_standalone_xml_as_user.sh script.

### HOOKS ###

- jboss.version - This hook sets the jboss_home to /etc/alternatives/jbossas-7, which is used by the abstract jboss cartridge configure hook.

- pre-install - This hook makes sure dependency packages are installed.  Currently, this just checks for the presence of the java-1.6.0-openjdk rpm and makes sure JBoss AS 7 is installed.

### TEMPLATE ###

The template directory is used to prime the git repository for the application when the gear is created.

- deployments - The deployment directory is where prebuilt archive files are placed. If you want to deploy an application that is prebuilt into an archive, you'll need to remove the pom.xml file and the src directory from the git repo in addition to placing the archive in this directory.

- src - This is where the java source code is placed.  It's expected that the src directory structure is Maven compliant.  [For more info on Maven directory layout](http://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html)

- pom.xml - This is the root Maven configuration file.  The default name of an application is ROOT.  For scaled applications it's important to have the name remain as ROOT so that the application is available at the root context.

- README - This describes all the things you need to know to deploy a java application in using JBoss EAP 7.
