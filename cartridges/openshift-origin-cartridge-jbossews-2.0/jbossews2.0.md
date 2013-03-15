## JBoss EWS 2.0 Cartridge ##

       - openshift-origin-cartridge-jbossews-2.0
          ├── info
          │   ├── bin
          │   │   ├── app_ctl_impl.sh
          │   │   ├── app_ctl.sh
          │   │   ├── build.sh
          │   │   ├── deploy_httpd_proxy.sh
          │   │   ├── deploy.sh
          │   │   ├── post_receive_app.sh
          │   │   ├── pre_receive_app.sh
          │   │   ├── tidy.sh
          │   │   └── tomcat7
          │   ├── configuration
          │   │   ├── catalina.policy
          │   │   ├── catalina.properties
          │   │   ├── context.xml
          │   │   ├── jenkins_job_template.xml
          │   │   ├── logging.properties
          │   │   ├── node_ssl_template.conf
          │   │   ├── postgresql_module.xml
          │   │   ├── server.xml
          │   │   ├── settings.base.xml
          │   │   ├── settings.prod.xml
          │   │   ├── settings.stg.xml
          │   │   ├── tomcat-users.xml
          │   │   └── web.xml
          │   ├── control
          │   ├── data
          │   ├── hooks
          │   │   ├── conceal-port
          │   │   ├── configure
          │   │   ├── deconfigure
          │   │   ├── expose-port
          │   │   ├── jboss.version
          │   │   ├── pre-install
          │   │   ├── show-port
          │   │   └── threaddump
          │   └── manifest.yml
          └── template
              ├── .openshift
              │   ├── action_hooks
              │   │   ├── build
              │   │   ├── deploy
              │   │   ├── post_deploy
              │   │   ├── post_start_jbossews-1.0
              │   │   ├── post_stop_jbossews-1.0
              │   │   ├── pre_build
              │   │   ├── pre_start_jbossews-1.0
              │   │   └── pre_stop_jbossews-1.0
              │   ├── cron
              │   │   ├── ...
              │   └── markers
              │       ├── java7
              │       └── README
              ├── pom.xml
              ├── README
              ├── src ...
              └── webapps

### INFO ###

- control: This file lists package provides and dependencies, and cartridge conflicts, and meta info about the cartridge such as display name and description

- manifest.yml: his file lists meta info about the cartridge similar to the control file. (which set of meta info is used?). This file also lists all the environment variables created, a list of packages provided. There is a publishes/subscribes for connectivity for http, gear endpoints, database

### BIN ###

- app_ctl_impl.sh: This script has the implementation details on how to [start|restart|graceful|graceful-stop|stop|threaddump] JBoss EWS. A few more things to note:
    1. You can add a marker to enable jpda for debugging - .openshift/markers/enable_jpda.  Doing so will enable remote debugging on port 8787.
    2. If there are any user defined pre_start hooks defined, those are sourced before the tomcat6 script is invoked to start JBoss. Then any post_start hooks are executed.

- app_ctl.sh: This script just delegates to app_ctl_impl.sh after doing some environment variable translation

- build.sh: When java applications are pushed to the remote git repository, the application needs to be compiled. This script sets everything up to do a build, including the maven repo mirror, maven memory allocation. You can change the build behavior by adding command marker files in your git repo under .openshift/markers (skip_maven_build, force_clean_build, java7). Maven3 is used for the build.

- deploy_httpd_proxy.sh: This script sets up the vhost configuration for the proxy that sits in front of the JBoss application server. This script directly edits httpd drop files to add vhost and mod_proxy directivesfor the gear. The proxy uses HTTP to route requests and does not use AJP.

- deploy.sh: As the name suggests, this script deploys the application. It also starts any databases that have been configured. If a hot deployment is requested, the tmp dir will not be cleaned out and the database is assumed to already be running. This script will invoke user_deploy.sh, which will in turn source any environment variables and invoke the deploy hook.

- post_receive_app.sh: This script will source all the environment variables then call the post_start_app function in {CARTRIDGE_BASE_PATH}/abstract/info/lib/util, which calls app_ctl.sh start on all the dbs first then the apps.

- pre_receive_app.sh: This script is what drives the initial shutdown of the application prior to applying incoming commits. It must respect the precence of the hot_deploy marker, this becomes a bit tricky as we must take into account the possibility the marker is being added or removed during the commit, possibly for the first time. The stop should only occur if the marker is present and will remain present after the commit is applied.

- tidy.sh: empties the tmp directory of standalone/tmp

- tomcat7: This script starts tomcat after setting the memory limits to whatever the cgroup configuration has specified as the maximum avaialable memory for the gear.


### CONFIGURATION ###

- catalina.policy: java security policy for tomcat7

- catalina.properties: class loader configuration parameters

- context.xml: specifies which resource to monitor.  If you have any custom valves to add, this is the file to do so in.

- jenkins_job_template.xml:  This config file is just as the name implies, it's just a template file used for all jenkins jobs.

- logging.properties: This config file is the logger properties for application server logging

- node_ssl_template.conf: The SSL configuration template for  the node httpd.

- postgresql_module.xml: This config file is the posgresql jdbc driver configuration.

- server.xml: This config file sets all the tomcat server config values.

- settings.base.xml: This is an empty maven configuration file.

- settings.prod.xml: This config file points maven to the OpenShift production maven mirror.

- settings.stg.xml: This config file points maven to the OpenShift stage maven mirror.

- tomcat-users.xml: This config file sets up users and roles for the tomcat admin application.

- web.xml: This config file sets up the default web appliation configuration settings.


### HOOKS ###

- conceal-port: This hook is always called by the deconfigure hook and can be directly invoked through the broker's REST api. This script uses the openshift-port-proxy to remove the proxy entry for this gear.

- configure: In addition to the typical configure functionality {disable cgroups, verify the cartridge doesn't already exist, git repo creation, dir structure creation}, this configure hook does the following:
    1. creates a .m2 dir for the Maven settings and jar cloning
    2. creates a .java for any java preferences
    3. creates the bin, conf, logs directories for JBoss
    4. creates a symlink - ln -s "$APP_REPO_DIR"/webapps "$APP_JBOSS"/webapps, doing this allows JBoss to pick up the deployed application
    5. creates a symlink - ln -s ${jboss_version}/logs "$JBOSS_INSTANCE_DIR"/logs, this is necessary to allow a standard logging location in the application
    6. there may be other configuration steps needed by the concrete cartridge, those are also invoked in here
    7. copies the ROOT.war to the webapps directory
    8. initializes environment variables with the network settings
    9. initializes the JAVA_HOME and M2_HOME environment variables, then appends the PATH environment variable with both JAVA_HOME and M2_HOME
    10. starts the application using start_app.
    11. creates a virtual host for apache using deploy_http_proxy.sh

- deconfigure: In addtion to the typical deconfigure functionality {disable cgroups, destroy git repo, stop the application, makes sure the pid is gone, remove the cartridge instance directory, renable cgroups, disconnect from proxy front end}, this deconfigure hook does the following:
    1. removes the maven repository directory
    2. removes the java preferences directory
    3. removes the virtual host from httpd

- expose-port: This hook sets up several proxy ports and writes them to the gear's .env directory.  The environment variables configured by this hook are:
    1. OPENSHIFT_${CART_NS}_PROXY_PORT
    2. PROXY_HOST
    3. PROXY_PORT
    4. HOST
    5. PORT

- jboss.version: This hook sets the jboss_home to /etc/alternatives/jbossews-1.0, which is used by the abstract jboss cartridge configure hook.

- pre-install: This hook makes sure dependency packages are installed. Currently, this just checks for the presence of the java-1.6.0-openjdk rpm and makes sure jbossews-1.0 is installed

- show-port: This hook will set several environment variables to include:
    1. PROXY_HOST
    2. PROXY_PORT
    3. HOST
    4. PORT
    5. ${CART_NS}_CLUSTER_PROXY_HOST
    6. ${CART_NS}_CLUSTER_PROXY_PORT
    7. ${CART_NS}_CLUSTER_HOST

- threaddump: This is invoked via an rhc client threaddump command.  This hook wraps the app_ctl_impl.sh threaddump implementation.  The implementation uses kill -3 to get the JVM's thread dump.
