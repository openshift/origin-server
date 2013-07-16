# OpenShift JBossAS Cartridge

Provides the JBossAS application server on OpenShift.

## Template Repository Layout

    deployments/       Location for built WARs (details below)
    src/               Example Maven source structure
    pom.xml            Example Maven build file
    .openshift/        Location for OpenShift specific files
      config/          location for configuration files such as standalone.xml
      action_hooks/    See the Action Hooks documentation [1]
      markers/         See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)

Note: Every time you push, everything in your remote repo directory is recreated.
      Please store long term items (like an sqlite database) in the OpenShift
      data directory, which will persist between pushes of your repo.
      The OpenShift data directory is accessible via an environment variable `OPENSHIFT_DATA_DIR`.

## Layout and deployment option details

There are two options for deploying content to the JBoss Application Server within OpenShift. Both options
can be used together (i.e. build one archive from source and others pre-built)

NOTE: Under most circumstances the .dodeploy file markers should not be added to the deployments directory.
These lifecycle files will be created in the runtime deployments directory (can be seen by SSHing into the application),
but should not be added to the git repo.

1) (Preferred) You can upload your content in a Maven src structure as is this sample project and on 
git push have the application built and deployed.  For this to work you'll need your pom.xml at the 
root of your repository and a maven-war-plugin like in this sample to move the output from the build
to the deployments directory.  By default the warName is ROOT within pom.xml.  This will cause the 
webapp contents to be rendered at http://app_name-namespace.rhcloud.com/.  If you change the warName in 
pom.xml to app_name, your base url would then become http://app_name-namespace.rhcloud.com/app_name.

Note: If you are building locally you'll also want to add any output wars/ears under deployments 
from the build to your .gitignore file.

Note: If you are running scaled AS7 then you need an application deployed to the root context (i.e. 
http://app_name-namespace.rhcloud.com/) for the HAProxy load-balancer to recognize that the AS7 instance 
is active.

or

2) You can git push pre-built wars into deployments/.  To do this
with the default repo you'll want to first run 'git rm -r src/ pom.xml' from the root of your repo.

Basic workflows for deploying pre-built content (each operation will require associated git add/commit/push operations to take effect):

A) Add new zipped content and deploy it:

1. cp target/example.war deployments/

B) Add new unzipped/exploded content and deploy it:

1. cp -r target/example.war/ deployments/
2. edit .openshift/config/standalone.xml and replace
<deployment-scanner path="deployments" relative-to="jboss.server.base.dir" scan-interval="5000" deployment-timeout="300"/>
with 
<deployment-scanner path="deployments" relative-to="jboss.server.base.dir" scan-interval="5000" deployment-timeout="300" auto-deploy-exploded="true"/>

C) Undeploy currently deployed content:

1. git rm deployments/example.war

D) Replace currently deployed zipped content with a new version and deploy it:

1. cp target/example.war deployments/

E) Replace currently deployed unzipped content with a new version and deploy it:

1. git rm -rf deployments/example.war/
2. cp -r target/example.war/ deployments/

Note: You can get the information in the uri above from running 'rhc domain show'

If you have already committed large files to your git repo, you rewrite or reset the history of those files in git
to an earlier point in time and then 'git push --force' to apply those changes on the remote OpenShift server.  A 
git gc on the remote OpenShift repo can be forced with (Note: tidy also does other cleanup including clearing log
files and tmp dirs):

rhc app tidy -a appname


Whether you choose option 1) or 2) the end result will be the application 
deployed into the deployments directory. The deployments directory in the 
JBoss Application Server distribution is the location end users can place 
their deployment content (e.g. war, ear, jar, sar files) to have it 
automatically deployed into the server runtime.


## Environment Variables

The `jbossas` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_JBOSSAS_IP                         The IP address used to bind JBossAS
    OPENSHIFT_JBOSSAS_HTTP_PORT                  The JBossAS listening port
    OPENSHIFT_JBOSSAS_CLUSTER_PORT               TODO
    OPENSHIFT_JBOSSAS_MESSAGING_PORT             TODO
    OPENSHIFT_JBOSSAS_MESSAGING_THROUGHPUT_PORT  TODO
    OPENSHIFT_JBOSSAS_REMOTING_PORT              TODO

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).

## Markers

Adding marker files to `.openshift/markers` will have the following effects:

    enable_jpda          Will enable the JPDA socket based transport on the java virtual
                         machine running the JBoss AS 7 application server. This enables
                         you to remotely debug code running inside the JBoss AS 7
                         application server.
    
    skip_maven_build     Maven build step will be skipped
    
    force_clean_build    Will start the build process by removing all non-essential Maven
                         dependencies.  Any current dependencies specified in your pom.xml
                         file will then be re-downloaded.

    hot_deploy           Will prevent a JBoss container restart during build/deployment.
                         Newly build archives will be re-deployed automatically by the
                         JBoss HDScanner component.
    
    java7                Will run JBossAS with Java7 if present. If no marker is present
                         then the baseline Java version will be used (currently Java6)

## JBoss CLI

The `jbossas` cartridge provides an OpenShift compatible wrapper of the JBoss CLI tool on the gear `PATH`, located at
`$OPENSHIFT_JBOSSAS_DIR/tools/jboss-cli.sh`. Use the following command to connect to the JBoss instance with the
CLI tool:

    jboss-cli.sh -c --controller=${OPENSHIFT_JBOSSAS_IP}:${OPENSHIFT_JBOSSAS_MANAGEMENT_NATIVE_PORT}
