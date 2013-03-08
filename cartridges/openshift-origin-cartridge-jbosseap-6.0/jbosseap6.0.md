## JBoss EAP 6.0 Cartridge ##

The JBoss EAP 6.0 cartridge relies upon functionlity from an abstract cartridge implementation. You should be familiar with the [Abstract Cartridge](../openshift-origin-cartridge-abstract/abstract-jboss/README.md) before reading the rest of this document.

More information about EAP 6 can be found on the [JBoss AS site](http://www.jboss.org/jbossas/docs/6-x)

       - openshift-origin-cartridge-jbosseap-6.0
          ├── info
          │   ├── bin
          │   │   ├── build.sh
          │   │   ├── product.conf
          │   │   ├── standalone.conf
          │   │   └── standalone.sh
          │   ├── configuration
          │   │   ├── jenkins_job_template.xml
          │   │   ├── logging.properties
          │   │   ├── node_ssl_template.conf
          │   │   ├── postgresql_module.xml
          │   │   ├── settings.base.xml
          │   │   ├── settings.rhcloud.xml
          │   │   └── standalone.xml
          │   ├── control
          │   ├── hooks
          │   │   ├── configure-jbosseap-6.0
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
              │   │   ├── post_start_jbosseap-6.0
              │   │   ├── post_stop_jbosseap-6.0
              │   │   ├── pre_build
              │   │   ├── pre_start_jbosseap-6.0
              │   │   └── pre_stop_jbosseap-6.0
              │   ├── config
              │   │   └── modules
              │   │       └── README
              │   ├── cron
              │   │   └── ...
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

- product.conf - This is used as a product branding configuration file.

- standalone.conf - This config file sets up the standalone configuration settings

- standalone.sh - This script starts JBoss EAP 6 using all the configuration settings from standalone.conf


### CONFIGURATION ###

- jenkins_job_template.xml - This config file is just as the name implies, it's just a template file used for all jenkins jobs.

- logging.properties - This config file is the logger properties for application server logging

- node_ssl_template.conf - This has the default ssl configuration  (TODO: when is this used)

- postgresql_module.xml - This config file adds the postgreqsql jdbc driver module

- settings.base.xml - This config file is empty by default, all the settings.*.xml file are for maven configuration

- settings.rhcloud.xml - This config file sets up the maven configuration, pointing to the OpenShift maven repository mirror

- standalone.xml - This config file is the default standalone.xml file.

### HOOKS ###

- configure-jbosseap-6.0 - This is invoked from the abstract jboss configure script (see concreate_configure above). This is needed to link the cartridge product.conf to the gear instance root.

- jboss.version - This hook sets the jboss_home to /etc/alternatives/jbosseap-6.0, which is used by the abstract jboss cartridge configure hook.

- pre-install - This hook makes sure dependency packages are installed.  Currently, this just checks for the presence of the java-1.6.0-openjdk rpm and makes sure JBoss AS 7 is installed.

### TEMPLATE ###

The template directory is used to prime the git repository for the application when the gear is created.

- deployments - The deployment directory is where prebuilt archive files are placed. If you want to deploy an application that is prebuilt into an archive, you'll need to remove the pom.xml file and the src directory from the git repo in addition to placing the archive in this directory.

- src - This is where the java source code is placed.  It's expected that the src directory structure is Maven compliant.  [For more info on Maven directory layout](http://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html)

- pom.xml - This is the root Maven configuration file.  The default name of an application is ROOT. For scaled applications it's important to deploy your application to the root context.

- README - This describes all the things you need to know to deploy a java application in using JBoss EAP 6.

## General Questions ##

- What happens when a scale up event occurs on a scaled JBoss gear?
EAP has clustering capabilities, so in addition to connecting to the HA Proxy on the head gear, it joins the existing cluster.  It joins the existing cluster by first knowing who the existing group members are via the initial_hosts setting in the standalone.xml, then it announces itself to the existing members of the cluster.  It also adds itself to the OPENSHIFT_JBOSSEAP_CLUSTER environment variable to prepare the variable for the next member that comes online.

[More on scaled JBoss applications](http://blog-judcon.rhcloud.com/?p=62)

- If I want to open (for loopback-only connection) a JMX port for a gear, how do I do that?  How do I determine what ports are available for the gears to open?
SELinux locks down most ports. Here's a (hopefully not too dated) list
of the open ports and their intended use. JMX is exposed by default
via Remoting on 4447.

        postgresql_port_t: 5432
        ssh_port_t: 22
        mssql_port_t: 1433-1434
        memcache_port_t: 11211
        pulseaudio_port_t: 4713
        oracle_port_t: 1521,2483,2484
        flash_port_t: 843,1935
        pop_port_t: 106,109,110,143,220,993,995,1109
        dns_port_t: 53

        jacorb_port_t: 3528,3529
        mysqld_port_t: 1186,3306,63132-63164
        munin_port_t: 4949
        jboss_debug_port_t: 8787
        jboss_messaging_port_t:
        amqp_port_t: 5671-5672
        jboss_management_port_t: 4712,4447,7600,9123,9990,9999,18001
        smtp_port_t: 25,465,587
        virt_migration_port_t: 49152-49216
        ftp_port_t: 21,990
        git_port_t: 9418
        mongod_port_t: 27017
        http_cache_port_t: 8080,8118,8123,10001-10010
        http_port_t: 80,443,488,8008,8009,8443
        ocsp_port_t: 9080
        kerberos_port_t: 88,750,4444

- Are EAP6 clustering ports known, or is it just one of the 35531-65535 range available for the gears?
ssh into the gear and cat .env/*JBOSS*, you'll see all the JBoss env variables, including the clustering ports, something like:

        export OPENSHIFT_JBOSSEAP_CLUSTER=uuid-demo.example.com[35562],jbs-demo.example.com[35557]
        export OPENSHIFT_JBOSSEAP_CLUSTER_PORT='7600'
        export OPENSHIFT_JBOSSEAP_CLUSTER_PROXY_PORT=35557
        export OPENSHIFT_JBOSSEAP_CLUSTER_REMOTING=uuid-demo.example.com[35565],jbs-demo.example.com[35560]
        export OPENSHIFT_JBOSSEAP_IP='127.0.252.129'
        export OPENSHIFT_JBOSSEAP_LOG_DIR='/var/lib/openshift/uuid/jbosseap-6.0/logs/'
        export OPENSHIFT_JBOSSEAP_MESSAGING_PORT=35558
        export OPENSHIFT_JBOSSEAP_MESSAGING_THROUGHPUT_PORT=35559
        export OPENSHIFT_JBOSSEAP_PORT='8080'
        export OPENSHIFT_JBOSSEAP_PROXY_PORT=35556
        export OPENSHIFT_JBOSSEAP_REMOTING_PORT=35560
