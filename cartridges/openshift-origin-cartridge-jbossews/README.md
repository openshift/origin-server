# OpenShift Tomcat (JBossEWS) Cartridge

The `jbossews` cartridge provides Tomcat on OpenShift via the JBoss EWS package.

This cartridge has special functionality to enable integration with OpenShift and with other
cartridges. See the [Cartridge Integrations](#cartridge-integrations) and
[Environment Variable Replacement Support](#environment-variable-replacement-support) sections
for details.

## Template Repository Layout

    webapps/           Location for built WARs (details below)
    src/               Example Maven source structure
    pom.xml            Example Maven build file
    .openshift/        Location for OpenShift specific files
      config/          Location for configuration files such as server.xml
      action_hooks/    See the Action Hooks documentation [1]
      markers/         See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)

Note: Every time you push, everything in your remote repo directory is recreated.
      Please store long term items (like an sqlite database) in the OpenShift
      data directory, which will persist between pushes of your repo.
      The OpenShift data directory is accessible via an environment variable `OPENSHIFT_DATA_DIR`.

## Layout and deployment option details
There are two options for deploying content to the Tomcat Server within OpenShift. Both options
can be used together (i.e. build one archive from source and others pre-built)

1) (Preferred) You can upload your content in a Maven src structure as is this sample project and on 
Git push have the application built and deployed.  For this to work you'll need your pom.xml at the 
root of your repository and a maven-war-plugin like in this sample to move the output from the build
to the webapps directory.  By default the warName is ROOT within pom.xml.  This will cause the 
webapp contents to be rendered at `http://app_name-namespace.rhcloud.com/`.  If you change the warName in 
`pom.xml` to app_name, your base url would then become `http://app_name-namespace.rhcloud.com/app_name`.

Note: If you are building locally you'll also want to add any output wars under webapps 
from the build to your `.gitignore` file.

Note: If you are running scaled EWS then you need an application deployed to the root context (i.e. 
http://app_name-namespace.rhcloud.com/) for the HAProxy load-balancer to recognize that the EWS instance 
is active.

or

2) You can commit pre-built wars into `webapps`.  To do this
with the default repo, first run `git rm -r src/ pom.xml` from the root of your repo.

Basic workflows for deploying pre-built content (each operation will require associated
Git add/commit/push operations to take effect):

1. Add new zipped content and deploy it:
  * `cp target/example.war webapps/`
2. Undeploy currently deployed content:
  * `git rm webapps/example.war`
3. Replace currently deployed zipped content with a new version and deploy it:
  * `cp target/example.war webapps/`

Note: You can get the information in the uri above from running `rhc domain show`

If you have already committed large files to your Git repo, you rewrite or reset the history of those files in Git
to an earlier point in time and then `git push --force` to apply those changes on the remote OpenShift server.  A 
`git gc` on the remote OpenShift repo can be forced with (Note: tidy also does other cleanup including clearing log
files and tmp dirs):

`rhc app tidy -a appname`

Whether you choose option 1) or 2) the end result will be the application 
deployed into the `webapps` directory. The `webapps` directory in the 
Tomcat distribution is the location end users can place 
their deployment content (e.g. war, ear, jar, sar files) to have it 
automatically deployed into the server runtime.

## Environment Variables

The Tomcat cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_JBOSSEWS_IP          The IP address used to bind EWS
    OPENSHIFT_JBOSSEWS_HTTP_PORT   The EWS listening port
    OPENSHIFT_JBOSSEWS_JPDA_PORT   The EWS JPDA listening port

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).

### Environment Variable Replacement Support

The `jbossews` cart provides special environment variable replacement functionality for some of the Tomcat configuration files.
For the following configuration files:

  * `.openshift/config/server.xml`
  * `.openshift/config/context.xml`

Ant-style environment replacements are supported for all `OPENSHIFT_`-prefixed environment variables in the application. For
example, the following replacements are valid in `server.xml`:

      <Connector address="${OPENSHIFT_JBOSSEWS_IP}"
                 port="${OPENSHIFT_JBOSSEWS_HTTP_PORT}"
                 protocol="HTTP/1.1"
                 connectionTimeout="20000"
                 redirectPort="8443" />

During server startup, the configuration files in the source repository are processed to replace `OPENSHIFT_*` values, and the
resulting processed file is copied to the live Tomcat configuration directory.


## Cartridge Integrations

The `jbossews` cart has out-of-the-box integration support with the RedHat `postgresql` and `mysql` cartridges. The default
`context.xml` contains two basic JDBC `Resource` definitions, `jdbc/MysqlDS` and `jdbc/PostgreSQLDS`, which will be automatically
configured to work with their respective cartridges if installed into your application.


## Markers

Adding marker files to `.openshift/markers` will have the following effects:

    enable_jpda          Will enable the JPDA socket based transport on the java virtual
                         machine running the Tomcat server. This enables
                         you to remotely debug code running inside Tomcat.
    
    skip_maven_build     Maven build step will be skipped
    
    force_clean_build    Will start the build process by removing all non-essential Maven
                         dependencies.  Any current dependencies specified in your pom.xml
                         file will then be re-downloaded.
    
    java7                Will run Tomcat with Java7 if present. If no marker is present
                         then the baseline Java version will be used (currently Java6)
