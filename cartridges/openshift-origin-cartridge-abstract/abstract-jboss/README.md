## Abstract JBoss Cartridge ##

The JBoss cartridges inherit functionality from the openshift-origin-cartridge-abstract cartridge. The openshift-origin-cartridge-abstract.spec builds two rpms.  These two rpms are:
openshift-origin-cartridge-abstract
openshift-origin-cartridge-abstract-jboss

The jboss cartridges require the openshift-origin-cartridge-abstract-jboss package. The following structure of the abstract jboss cartridge will be discussed further below.

       - openshift-origin-cartridge-abstract/abstract-jboss
          └── info
              ├── bin
              │   ├── app_ctl_impl.sh
              │   ├── app_ctl.sh
              │   ├── deploy_httpd_proxy.sh
              │   ├── deploy.sh
              │   ├── post_receive_app.sh
              │   └── pre_receive_app.sh
              ├── connection-hooks
              │   ├── publish_jboss_cluster
              │   ├── publish_jboss_remoting
              │   ├── set_jboss_cluster
              │   └── set_jboss_remoting
              ├── data
              └── hooks
                  ├── conceal-port
                  ├── configure
                  ├── deconfigure
                  ├── expose-port
                  ├── show-port
                  └── threaddump

### BIN ###

- app_ctl_impl.sh: This script has the implementation details on how to [start|restart|graceful|graceful-stop|stop|threaddump] JBoss.  A few more things to note:
    1. You can add a marker to enable jpda for debugging - .openshift/markers/enable_jpda.  Doing so will enable remote debugging on port 8787.
    2. If there are any user defined pre_start hooks defined, those are sourced before the standanlone.sh script is invoked to start JBoss. The concrete cartridges have a template for {pre,post}_start hooks.

- app_ctl.sh: This script just delegates to app_ctl_impl.sh after doing some environment variable translation

- deploy_httpd_proxy.sh: This script sets up the vhost configuration for the proxy that sits in front of the JBoss application server.  This script directly edits httpd drop files to add vhost and mod_proxy directivesfor the gear. The proxy uses HTTP to route requests and does not use AJP.

- deploy.sh: As the name suggests, this script deploys the application.  It also starts any databases that have been configured.  If a hot deployment is requested, the tmp dir will not be cleaned out and the database is assumed to already be running. This script will invoke user_deploy.sh, which will in turn source any environment variables and invoke the deploy hook.

#### CONNECTION-HOOKS ####

Define methods to which the cartridge responds. Connection hooks are executed directly by hooks and facilitate inter-cartridge communication. A typical example is that a database cartridge provides a connection hook that outputs the URL for connecting to the database. The output of connection hooks is unstructured data

- publish_jboss_cluster: publishes OPENSHIFT_JBOSS_CLUSTER_PROXY_PORT, OPENSHIFT_GEAR_DNS.  These are used to complete the standalone.xml
- publish_jboss_remoting: publishes OPENSHIFT_GEAR_DNS, OPENSHIFT_JBOSS_REMOTING_PORT
- set_jboss_cluster: publishes OPENSHIFT_${CART_NS}_HAPROXY_CLUSTER, OPENSHIFT_${CART_NS}_CLUSTER
- set_jboss_remoting: publishes OPENSHIFT_${CART_NS}_HAPROXY_REMOTING

#### HOOKS ####

Define methods to which the cartridge responds. Hooks are executed by the mcollective agent on the node on behalf of the broker. Hooks are used to handle instantiation and deletion of instances (lifecycle control) Hooks output a sequence of commands in a DSL that is parsed by the broker

- conceal-port - This hook is always called by the deconfigure hook and can be directly invoked through the broker's REST api. This script uses the openshift-port-proxy to remove the proxy entry for this gear.

- configure - In addition to the typical configure functionality {disable cgroups, verify the cartridge doesn't already exist, git repo creation, dir structure creation}, this configure hook does the following:
    1. creates a .m2 dir for the Maven settings and jar cloning
    2. creates a .java for any java preferences
    3. creates the jboss tmp directory
    4. creates the bin, standalone, configuration directories for JBoss
    5. creates a symlink - ln -s "$APP_REPO_DIR"/deployments "$APP_JBOSS"/standalone/deployments, doing this allows JBoss to pick up the deployed application
    6. creates a symlink - ln -s ${jboss_version}/standalone/log "$JBOSS_INSTANCE_DIR"/logs, this is necessary to allow a standard logging location in the application
    7. since this is an abstract cart, there may be other configuration steps needed by the concrete cartridge, those are also invoked in here
    8. copies the ROOT.war to the deployments directory
    9. makes the standalone start script executable
    10. initializes environment variables with the JBoss network settings
    11. initializes the JAVA_HOME and M2_HOME environment variables, then appends the PATH environment variable with both JAVA_HOME and M2_HOME
    12. starts the application using abstract-jboss/info/bin/app_ctl_impl.sh.  The JBoss EWS cartridges will override this as they have different start up scripts.

- deconfigure - In addtion to the typical deconfigure functionality {disable cgroups, destroy git repo, stop the application, makes sure the pid is gone, remove the cartridge instance directory, renable cgroups, disconnect from proxy front end}, this deconfigure hook does the following:
    1. removes the maven repository directory
    2. removes the java preferences directory

- expose-port - This hook sets up several proxy ports and writes them to the gear's .env directory.  The environment variables configured by this hook are:
    1. OPENSHIFT_${CART_NS}_PROXY_PORT
    2. OPENSHIFT_${CART_NS}_CLUSTER_PROXY_PORT
    3. OPENSHIFT_${CART_NS}_MESSAGING_PORT
    4. OPENSHIFT_${CART_NS}_MESSAGING_THROUGHPUT_PORT
    5. OPENSHIFT_${CART_NS}_REMOTING_PORT

- threaddump - This is invoked via an rhc client threaddump command.  This hook wraps the app_ctl_impl.sh threaddump implementation.  The implementation uses kill -3 to get the JVM's thread dump.


