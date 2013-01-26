TODO:

- [ ] Gear log design. Read access.
- [ ] Template git repo needs to be controlled by setup and then promoted by node platform

# How To Write An OpenShift Origin Cartridge 2.0

OpenShift cartridges provide the necessary command and control for
the functionality of software that is running user's applications.
OpenShift currently has many language cartridges JBoss, PHP, Ruby
(Rails) etc. as well as many DB cartridges such as Postgres, Mysql,
Mongo etc. Before writing your own cartridge you should search the
current list of [Red Hat](https://openshift.redhat.com) and [OpenShift
Community](https://openshift.redhat.com/community) provided cartridges.

Cartridge configuration and setup is convention based, with an emphasis
on minimizing external dependencies in the cartridge code.

## Cartridge Directory Structure

This is an example structure to which your cartridge is expected to
conform when written to disk. Failure to meet these expectations will
cause your cartridge to not function when either installed or used on
OpenShift. You may have additional directories or files.

    `cartridge name`-`cartridge version`
     +- bin                        (required)
     |  +- setup                   (required)
     |  +- teardown                (optional)
     |  +- control                 (required)
     |  +- build                   (optional)
     +- versions                   (discretionary)
     |  +- `cartridge name`-`software version`
     |  |  +- bin
     |  |     +- build
     |  |  +- data
     |  |     +- git_template.git
     |  |        +- ... (bare git repository)
     |  +- ...
     +- env                        (required)
     |  +- *.erb
     +- opt                        (optional)
     |  +- ...
     +- metadata
     |  +- manifest.yml
     |  +- locked_files.txt        (optional)
     |  +- snapshot_exclusions.txt (optional)
     |  +- snapshot_transforms.txt (optional)
     +- httpd.d                    (discretionary)
     |  +- `cartridge name`-`cartridge version`.conf.erb
     |  +- ...
     +- conf.d                     (discretionary)
     |  +- openshift.conf.erb
     +- conf                       (discretionary)
     |  +- magic

To support multiple software versions within one cartridge,
you may create symlinks between the bin/control and the setup
versions/{cartridge version}/bin/control file. Or, you may choose
to use the bin/control file as a shim to call the correct versioned
control file.

When creating an instance of your cartridge for use by a gear, OpenShift
will copy the files, links and directories from the cartridge library
with the exclusion of the opt directory. The opt directory will be
sym-linked into the gear's cartridge instance. This allows for sharing
of libraries and other data across cartridge instances.

Later (see Cartridge Locking) we'll describe how, as the cartridge author,
you can customize a cartridge instance.

## Cartridge Metadata

The `manifest.yml` file is used by OpenShift to determine what features
your cartridge requires and in turn publishes. OpenShift also uses fields
in the `manifest.yml` to determine what data to present to the cartridge
user about your cartridge.

An example `manifest.yml` file:

```yaml
Name: diy-0.1
Display-Name: diy v1.0.0 (noarch)
Description: "Experimental cartridge providing a way to try unsupported languages, frameworks, and middleware on OpenShift"
Version: 1.0.0
License: "ASL 2.0"
License-Url: http://www.apache.org/licenses/LICENSE-2.0.txt
Vendor:
Categories:
  - cartridge
  - web-framework
Website:
Help-Topics:
  "Getting Started": https://www.openshift.com/community/videos/getting-started-with-diy-applications-on-openshift
Cart-Data:
  - Key: OPENSHIFT_...
    Type: environment
    Description: "How environment variable should be used"
Suggests:

Provides:
  - "diy-0.1"
Requires:
Conflicts:
Native-Requires:
Architecture: noarch
Publishes:
  get-doc-root:
    Type: "FILESYSTEM:doc-root"
  publish-http-url:
    Type: "NET_TCP:httpd-proxy-info"
  publish-gear-endpoint:
    Type: "NET_TCP:gear-endpoint-info"
Subscribes:
  set-db-connection-info:
    Type: "NET_TCP:db:connection-info"
    Required: false
  set-nosql-db-connection-info:
    Type: "NET_TCP:nosqldb:connection-info"
    Required: false
Endpoints:
  HTTP: 8080
  SERVICE_A: 6666
  SERVICE_B: 7777
  ...
Reservations:
  - MEM >= 10MB
Scaling:
  Min: 1
  Max: -1
```

*jwh: How do we want to cover the manifest.yml features?*

## Cartridge Locking

Cartridge instances within a gear will be either `locked` or `unlocked`
at any given time.  Unlocking a cartridge allows the cartridge scripts
to have additional access to the gear's files and directories. Other
scripts and hooks written by the application developer will not be able to
override decisions you make as the cartridge author.

The lock state is controlled by OpenShift. Cartridges are locked and
unlocked at various points in the cartridge lifecycle.

If you fail to provide a `metadata/locked_files.txt` file or the file
is empty, your cartridge will remain always locked. For a very simple cartridges
this may be sufficient.

**Note on security:** Cartridge file locking is not intended to be a
security measure. It is a mechanism to help prevent application developers
from inadvertently breaking their application by modifying files reserved
for use by the cartridge author.

### Lock configuration ###

The `metadata/locked_files.txt` lists the files and directories, one
per line, that will be provided to the cartridge author with read/write
access while the cartridge is unlocked, but only read access to the
application developer while the cartridge is locked.

Any non-existent files that are included in the list will be created
when the cartridge is unlocked.  Any missing parent directories will be
created as needed. The list is anchored at the gear's home directory.
An entry ending in slash is processed as a directory.  Entries ending
in asterisk are a list of files.  Entries ending in an other character
are considered files.  OpenShift will not attempt to change files to
directories or vice versa, and your cartridge may fail to operate if
files are miscatergorized and you depend on OpenShift to create them.

#### Lock configuration example

Here is a `locked_files.txt` for a PHP cartridge:

    .pearrc
    php-5.3/bin/
    php-5.3/conf/*

Note in the above list the files in the `php-5.3/conf` directory are
unlocked but the directory itself is not.  Directories like `.node-gyp`
and `.npm` in nodejs are **NOT** candidates to be created in this
manner as they require the gear to have read and write access while
the application is deploying and running. These directories would need
to be created by the nodejs `setup` script which is run while the gear
is unlocked.

The following list is reserved by OpenShift in the the gear's home
directory:

    .ssh
    .sandbox
    .tmp
    .env
    any not hidden directory or file

You may create any hidden file or directory (one that starts with a
period) not in the reserved list in the gear's home directory while the
cartridge is unlocked.


## Exposing Services / TCP Endpoints

All cartridges expose endpoints to provide service or services to related gears
in an application. The exposed endpoints are available via environment variables
whose names are derived from endpoint names provided in the cartridge metadata.
All endpoints route within a node to an assigned internal IP address and port
specified in the endpoint metadata.

Endpoint environment variables are namespaced. The full variable name is
generated by OpenShift and follows the form
`OPENSHIFT_{CART_NS}_{ENDPOINT_NAME}:{PORT}`. The `{CART_NS}` segment is
generated according to [TODO: DOC EXISTING ALGORITHM]. The `{ENDPOINT_NAME}` is
specified by the cartridge endpoint metadata. The external port assignment
itself is random.

Endpoints are defined via the cartridge `manifest.yml` file, in the `Endpoints`
section. Each entry is a key-value pair, where the key is the name of the
endpoint, and the value is the endpoint's port.

### Endpoint Example

Given a cartridge named `CustomCart` and the following entry in `manifest.yml`:

```
Endpoints:
  - HTTP: 8080
  - SERVICE_A: 55555
  - SERVICE_B: 66666
```

The following proxy port mappings will be generated:

```
<assigned external IP>:<assigned port 0> => <assigned internal IP>:8080
<assigned external IP>:<assigned port 1> => <assigned internal IP>:5555
<assigned external IP>:<assigned port 2> => <assigned internal IP>:6666
```

The following environment variables will be created:

```
OPENSHIFT_CUSTOMCART_HTTP=<assigned external IP>:<assigned port 0>
OPENSHIFT_CUSTOMCART_SERVICE_A=<assigned external IP>:<assigned port 1>
OPENSHIFT_CUSTOMCART_SERVICE_B=<assigned external IP>:<assigned port 2>
```


## Cartridge Scripts

How you implement the cartridge scripts in the `bin` directory is
up to you as the author. For easily configured software where your
cartridge is just installing one version, these scripts may include all
the necessary code. For complex configurations or multi-version support,
you may choose to write these scripts as shim code to setup the necessary
environment before calling additional scripts you write. Or, you may
choose to create symlinks from these names to a name of your choosing.
Your API is the scripts and their associated actions. The scripts will
be run from the home directory of the gear.

A cartridge must implement the following scripts:

* `setup`: prepare this instance of cartridge to be operational
* `control`: command cartridge to report or change state

A cartridge may implement the following scripts:
* `teardown`: prepare this instance of cartridge to be removed

### Exit Status Codes

OpenShift follows the convention that your scripts should return zero
for success, and non-zero success. Additionally, OpenShift follows the
conventions from sysexit.h below:

```
    0. Success
   64. Usage: The command was used incorrectly, e.g., with the wrong number of arguments, a bad flag, a bad syntax in a parameter, or whatever.
   65. Data Error: The input data was incorrect in some way.  This should only be used for user's data and not system files.
   66. No Input: An input file (not a system file) did not exist or was not readable.  This could also include errors like "No message" to a mailer.
   67. No User: The user specified did not exist.  This might be used for mail addresses or remote logins.
   68. No Host: The host specified did not exist.  This is used in mail addresses or network requests.
   69. A service is unavailable.  This can occur if a support program or file does not exist.
       This can also be used as a catchall message when something you wanted to do doesn't work, but you don't know why.
   70. Software Error: An internal software error has been detected.  This should be limited to non-operating system related errors as possible.
   71. OS Error: An operating system error has been detected.  This is intended to be used for such things as "cannot fork",
       "cannot create pipe", or the like.  It includes things like getuid returning a user that does not exist in the passwd file.
   72. OS File: Some system file (e.g., /etc/passwd, /etc/utmp, etc.) does not exist, cannot be opened, or has some sort of error (e.g., syntax error).
   73. Cannot Create: A (user specified) output file cannot be created.
   74. IO Error: An error occurred while doing I/O on some file.
   75. Temporary Failure: Failure is something that is not really an error.  In sendmail, this means that a mailer (e.g.) could not create a connection,
        and the request should be reattempted later.
   76. Protocol: the remote system returned something that was "not possible" during a protocol exchange.
   77. No Permission: You did not have sufficient permission to perform the operation.  This is not intended for file system problems,
       which should use NOINPUT or CANTCREAT, but rather for higher level permissions.
   78. Configuration Error: A fatal configuration problem was found, but this does not necessarily mean that
       the problem was found while reading the configuration file.
   80-128. reserved for OpenShift usage
   128 + n. Where N is the signal that killed your script

Copyright (c) 1987, 1993 The Regents of the University of California.  All rights reserved.
```

These exit status codes will allow OpenShift to refine it's behavior
when returning HTTP status codes for the REST API, whether an internal
operation can continue or should aborted etc. Should your script return
a value not included in this table, OpenShift will assume the problem
is fatal to your cartridge.

## bin/setup

##### Synopsis

`setup [--version=<version>]`

##### Options

* `--version=<version>`: Selects which version of cartridge to install. If no version is provided,
the default from `manifest.yml` will be installed.
* `--homedir` provides the parent directory where your cartridge is installed.
If no homedir is provided, the default is OPENSHIFT_HOMEDIR.

##### Description

The `setup` script is responsible for creating and/or configuring the
files that were copied from the cartridge library into the gear's
directory. If you have used ERB templates for software configuration
this is where you would processes those files.  An example would be
PHP's php.ini file:

    upload_tmp_dir = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php-5.3/tmp/"
    session.save_path = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php-5.3/sessions/"

Other candidates for templates are httpd configuration files for
`includes`, configuring database to store persistent data in the
OPENSHIFT_DATA_DIR, and setting the application name in the pom.xml file.

Lock context: `unlocked`

##### Messaging to OpenShift from cartridge

Your cartridge may provide a service or services that is consumed by
multiple gears in one application. OpenShift provides the orchestration
necessary for you to publish this service or services. Each message is
written to stdout, one message per line.

* `ENV_VAR_ADD: <variable name>=<value>`
* `CART_DATA: <variable name>=<value>`
* `CART_PROPERTIES: <key>=<value>`
* `APP_INFO: <value>`

*jwh: need to explain when/where to use each...  May need to change format to match Lock context*
*jwh: See Krishna when he is back in town. He wished to make changes in this area with the model refactor.*

## Custom HTTP Services

Your cartridge may expose services using the application's URL by
providing snippet(s) of Apache configuration code using ERB templates
in the httpd.d directory. The httpd.d directory and it's contents are
optional.  After OpenShift has run your `setup` script it will render
each ERB template, and write the contents the node's httpd configuration.

An example of `mongodb-2.2.conf.erb`:

    Alias /health <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/httpd.d/health.html" %>
    Alias / <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/httpd.d/index.html" %>

Your templates will be rendered at `safe_level 2`.  [Locking Ruby in
the Safe](http://www.ruby-doc.org/docs/ProgrammingRuby/html/taint.html).

## bin/teardown

##### Synopsis

`teardown`

##### Description

The `teardown` script prepares the gear for the cartridge to be
removed. This is not called when the gear is destroyed.  The `teardown`
script is only run when a cartridge is to be removed from the gear.
The gear will continue to operate minus the functionality of this
cartridge.

Lock context: `unlocked`

*jwh: If all future gears are scaled, should teardown just always be called?*

##### Messaging to OpenShift from cartridge

After `teardown` your cartridge's services are no longer available. For
each environment variable you published, you must now un-publish it by
writing to stdout the following message(s):

* `ENV_VAR_REMOVE: <name>`

*jwh: See Krishna when he is back in town. He wished to make changes in this area with the model refactor.*

## bin/control

##### Synopsis

`control <action>`

##### Options

* `action`: which operation the cartridge should perform.

##### Description

The `control` script allows OpenShift or user to control the state of the cartridge.

The actions that must be supported:

   * `start` start the software your cartridge controls
   * `stop` stop the software your cartridge controls
   * `status` return an 0 exit status if your cartridge code is running.
   * `reload` your cartridge and it's controlled code needs to re-read their
      configuration information. Depending on the software your cartridge is controlling
      this may equate to a restart.
   * `restart` stop current process and start a new one for the code your cartridge controls
   * `tidy` all unused resources should be released. It is at your discretion to
      determine what should be released. Be frugal, on some systems resources may be
      very limited. Some possible behaviors:
```
    rm .../logs/log.[0-9]
    mvn clean
```
     OpenShift has the following default behaviors:
        * the git repository will be garbage collected
        * all files will be removed from the /tmp directory

Lock context: `locked`

###### `status` Action

For a number of reasons the application developer will want to be a
to query whether the software your cartridge controls is running and
behaving as expected.  A `0` exit status implies that the software is
running correctly. 

You may direct information to the application developer by writing
to stdout.  Errors may be return on stderr with an non-zero exit status.

OpenShift maintains the expected state of the gear/application in
`~/app-root/runtime/.state`. You may not use this to determine the
status of the software you are controlling.  That software may have
crashed so you would be returning invalid status if you used this file's
value. Future versions of OpenShift may combine the results from the
`status` action and the value of the `.state` file to automatically
restart failed applications. For completeness, `.state` values:

    * `building`    application is currently being built
    * `deploying`   application is currently being deployed
    * `idle`        application has been shutdown because of no activity
    * `new`         gear has been created, but no application has been installed
    * `started`     application has been commanded to start
    * `stopped`     application has been commanded to stop

## bin/build

##### Synopsis

`build`

##### Description

The `build` script is called during the `git push` to perform builds of the user's new code.

Lock context: `locked`


## Environment Variables

Environment variables are use to communicate setup information between
this cartridge and others, and to OpenShift.  The cartridge controlled
variables are stored in the env directory and will be loaded after
system provided environment variables but before your code is called.
OpenShift provided environment variables will be loaded and available
to be used for all cartridge entry points.

*jwh: ruby 1.9 makes providing environments when executing commands very easy. We should exploit that.*

### System Provided Variables (Read Only) ###
 * `HISTFILE` bash history file
 * `OPENSHIFT_APP_DNS` the application's fully qualified domain name that your cartridge is a part of
 * `OPENSHIFT_APP_NAME` the validated user assigned name for the application. Black list is system dependent.
 * `OPENSHIFT_APP_UUID` OpenShift assigned UUID for the application
 * `OPENSHIFT_DATA_DIR` the directory where your cartridge may store data
 * `OPENSHIFT_GEAR_DNS` the gear's fully qualified domain name that your cartridge is a part of. May or may not be equal to
                        `OPENSHIFT_APP_DNS`
 * `OPENSHIFT_GEAR_NAME` OpenShift assigned name for the gear. May or may not be equal to `OPENSHIFT_APP_NAME`
 * `OPENSHIFT_GEAR_UUID` OpenShift assigned UUID for the gear
 * `OPENSHIFT_HOMEDIR` OpenShift assigned directory for the gear
 * `OPENSHIFT_INTERNAL_IP` the private IP address for this gear *jwh: may go away*
 * `OPENSHIFT_INTERNAL_PORT` the private PORT for this gear *jwh: may go away*
 * `OPENSHIFT_REPO_DIR` the directory where the developer's application is "archived" to and will be run from.
 * `OPENSHIFT_TMP_DIR` the directory where your cartridge may store temporary data

### Examples of Cartridge Provided Variables ###

*jwh: Is this true? or should the manifest call these out and the node do the work? Or, are these ERB candidates?*

 * `OPENSHIFT_MYSQL_DB_HOST`
 * `OPENSHIFT_MYSQL_DB_LOG_DIR`
 * `OPENSHIFT_MYSQL_DB_PASSWORD`
 * `OPENSHIFT_MYSQL_DB_PORT`
 * `OPENSHIFT_MYSQL_DB_SOCKET`
 * `OPENSHIFT_MYSQL_DB_URL`
 * `OPENSHIFT_MYSQL_DB_USERNAME`
 * `OPENSHIFT_PHP_IP`
 * `OPENSHIFT_PHP_LOG_DIR`
 * `OPENSHIFT_PHP_PORT`

*jwh: now these are very cartridge dependent*

 * JENKINS_URL
 * JENKINS_USERNAME
 * JENKINS_PASSWORD

Your environment variables should be prefixed with
`OPENSHIFT_{cartridge name}_` to prevent overwriting other cartridge
variables in the process environment space. By convention, an environment
variable whos value is a directory should have a name that ends in
_DIR and the value should have a trailing slash. The software you are
controlling may require environment variables of it's own, for example:
`JENKINS_URL`. Those you would add to your `env` directory or include
in shim code in your `bin` scripts.

Cartridge provided environment variables are not validated by the
system. Your cartridge may fail to function if you write invalid data
to these files. If you provide ERB templates in the `env` directory,
OpenShift will render those files and remove the .erb suffix. They will
be processed before your `setup` script is run. You could write the
`env/JENKINS_URL.erb` as:

    export JENKINS_URL='https://<%= ENV['OPENSHIFT_APP_DNS'] %>/'

which would then be rendered as `env/JENKINS_URL`:

    export JENKINS_URL='http://jenkins-namespace.rhcloud.com/'

Or, `env/OPENSHIFT_MONGODB_DB_LOG_DIR.erb`:

    export OPENSHIFT_MONGODB_DB_LOG_DIR='<% ENV['OPENSHIFT_HOMEDIR'] %>/mongodb-2.2/log/'

renders as `env/OPENSHIFT_MONGODB_DB_LOG_DIR`:

    export OPENSHIFT_MONGODB_DB_LOG_DIR='/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/mongodb-2.2/log/'

Your templates will be rendered at `safe_level 2`.  [Locking Ruby in
the Safe](http://www.ruby-doc.org/docs/ProgrammingRuby/html/taint.html).

You may assume the
`PATH=$OPENSHIFT_HOMEDIR/{cartridge name}-{cartridge version}/bin:/bin:/usr/bin/`
when your code is executed. Any additional directories your code requires
will need to be added in your shim code.

## Backing up and Restoring your cartridge

OpenShift uses the tar command when backing up and restoring the gear that
contains your cartridge. The file `metadata/snapshot_exclusions.txt`
contains a pattern per line of files that will not be backed up or
restored. If you exclude files from being backed up and restored you need
to ensure those files are not required for your cartridge's operation.

The file `metadata/snapshot_transforms.txt` contains sed replace
expressions one per line and is used to transform file names during
restore.

Both files are optional and may be omitted. Empty files will be
ignored. Patterns are from the OPENSHIFT_HOMEDIR parent directory rather
than your cartridge's directory.  See the man page for tar the --transform
and --exclude-from for more details.

The following files and directories are never backed up:

```
.tmp
.ssh
.sandbox
*/conf.d/openshift.conf
*/run/httpd.pid
haproxy-\*/run/stats
app-root/runtime/.state
app-root/data/.bash_history
```
