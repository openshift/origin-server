Repo layout
=========== 
deployments/ - location for built wars (Details below)
src/ - Maven src structure
pom.xml - Maven build file  
.openshift/ - location for openshift specific files
.openshift/config/ - location for configuration files such as standalone.xml (used to modify jboss config such as datasources) 
.openshift/action_hooks/pre_build - Script that gets run every git push before the build (on the CI system if available)
.openshift/action_hooks/build - Script that gets run every git push as part of the build process (on the CI system if available)
.openshift/action_hooks/deploy - Script that gets run every git push after build but before the app is restarted
.openshift/action_hooks/post_deploy - Script that gets run every git push after the app is restarted
.openshift/action_hooks/pre_start_jbosseap-6.0 - Script that gets run prior to starting EAP6.0
.openshift/action_hooks/post_start_jbosseap-6.0 - Script that gets run after EAP6.0 is started
.openshift/action_hooks/pre_stop_jbosseap-6.0 - Script that gets run prior to stopping EAP6.0
.openshift/action_hooks/post_stop_jbosseap-6.0 - Script that gets run after EAP6.0 is stopped
.openshift/markers - directory for files used to control application behavior. See README in markers directory


Notes about layout
==================
Note: Every time you push, everything in your remote repo dir gets recreated
      please store long term items (like an sqlite database) in the OpenShift
      data directory, which will persist between pushes of your repo.
      The OpenShift data directory is accessible relative to the remote repo
      directory (../data) or via an environment variable OPENSHIFT_DATA_DIR.


Details about layout and deployment options
==================
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

Note: If you are running scaled EAP6.0 then you need an application deployed to the root context (i.e. 
http://app_name-namespace.rhcloud.com/) for the HAProxy load-balancer to recognize that the EAP6.0 instance 
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

Environment Variables
=====================

OpenShift provides several environment variables to reference for ease
of use.  The following list are some common variables but far from exhaustive:

    System.getenv("OPENSHIFT_APP_NAME")  - Application name
    System.getenv("OPENSHIFT_DATA_DIR")  - For persistent storage (between pushes)
    System.getenv("OPENSHIFT_TMP_DIR")   - Temp storage (unmodified files deleted after 10 days)
    System.getenv("OPENSHIFT_INTERNAL_IP")  - The IP address used to bind EAP6.0

When embedding a database using 'rhc cartridge add', you can reference environment
variables for username, host and password. For example, when embedding MySQL 5.1, the 
following variables will be available:

    System.getenv("OPENSHIFT_MYSQL_DB_HOST")      - DB host
    System.getenv("OPENSHIFT_MYSQL_DB_PORT")      - DB Port
    System.getenv("OPENSHIFT_MYSQL_DB_USERNAME")  - DB Username
    System.getenv("OPENSHIFT_MYSQL_DB_PASSWORD")  - DB Password

To get a full list of environment variables, simply add a line in your
.openshift/action_hooks/build script that says "export" and push.
