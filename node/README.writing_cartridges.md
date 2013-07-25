<!--- chapter-related notes inserted for ECS/Docbook purposes. -->

<!--- begin-chapter Introduction -->
# How To Write An OpenShift Origin Cartridge 2.0

OpenShift cartridges provide the necessary command and control for
the functionality of software that is running users' applications.
OpenShift currently has many language cartridges (JBoss, PHP, Ruby, 
Rails, etc.) as well as many DB cartridges (Postgres, Mysql,
Mongo, etc.). Before writing your own cartridge, you should search the
current list of [Red Hat](https://openshift.redhat.com) and [OpenShift
Community](https://www.openshift.com/community) provided cartridges.

Cartridge configuration and setup is convention based, with an emphasis
on minimizing external dependencies in your cartridge code.

<!--- begin-chapter Cartridge_Directory_Structure -->
## Cartridge Directory Structure

This is an example structure to which your cartridge is expected to
conform when written to disk. Failure to meet these expectations will
cause your cartridge to not function when either installed or used on
OpenShift. You may have additional directories or files as required to meet
the needs of the software you are packaging and the application developers
using your cartridge.

    `cartridge name`
     +- bin                        (required)
     |  +- setup                   (optional)
     |  +- install                 (optional)
     |  +- post-install            (optional)
     |  +- teardown                (optional)
     |  +- control                 (required)
     |- hooks                      (optional)
     |  +- set-db-connection-info  (discretionary)
     +- versions                   (discretionary)
     |  +- `software version`
     |  |  +- bin
     |  |     +- ...
     |  |  +- data
     |  |     +- template          (optional)
     |  |        +- .openshift
     |  |        |   +- ...
     |  |        +- ... (directory/file tree)
     |  |     +- template.git       (discretionary)
     |  |        +- ... (git bare repo)
     |  +- ...
     +- env                        (required)
     |  +- *.erb
     +- template                   (optional)
     |  +- ... (directory/file tree)
     +  template.git               (discretionary)
     +  +- ... (bare git repository)
     +- usr                        (optional)
     |  +- ...
     +- metadata                   (required)
     |  +- manifest.yml            (required)
     |  +- managed_files.yml       (optional)
     +- conf.d                     (discretionary)
     |  +- openshift.conf.erb
     +- conf                       (discretionary)
     |  +- magic

Items marked:
  * `required` must exist for minimal OpenShift support of your cartridge
  * `optional` exist to support additional functionality
  * `discretionary` should be considered best practices for your cartridge and work. E.g.,
    `conf.d` is the usual name for where a web framework would install its `httpd` configuration.


To support multiple software versions within one cartridge,
you may create symlinks between the `bin/control` and the 
`versions/{software version}/bin/control` file. Or, you may choose
to use the `bin/control` file as a shim to call the correct versioned
`control` file.

When creating an instance of your cartridge for use by a gear, OpenShift
will copy the files, links, and directories from the cartridge library
with the exclusion of the `usr` directory. The `usr` directory will be
symlinked into the gear's cartridge instance. This allows for the sharing
of libraries and other data across all cartridge instances.

Later (see Cartridge Locking) we'll describe how, as the cartridge author,
you can customize a cartridge instance.

<!--- begin-chapter Cartridge_Metadata -->
## Cartridge Metadata

The `manifest.yml` file is used by OpenShift to determine what features
your cartridge requires and in turn publishes. OpenShift also uses fields
in the `manifest.yml` to determine what data to present to the cartridge
user about your cartridge.

An example `manifest.yml` file:

```yaml
Name: PHP
Cartridge-Short-Name: PHP
Cartridge-Version: '1.0.1'
Compatible-Versions: ['1.0.1']
Cartridge-Vendor: redhat
Display-Name: PHP 5.3
Description: "PHP is a general-purpose server-side scripting language..."
Version: '5.3'
Versions: ['5.3']
License: "The PHP License, version 3.0"
License-Url: http://www.php.net/license/3_0.txt
Vendor: PHP Group
Categories:
  - service
  - php
  - web_framework
Website: http://www.php.net
Help-Topics:
  "Developer Center": https://openshift.redhat.com/community/developers
Cart-Data:
  - Key: OPENSHIFT_...
    Type: environment
    Description: "How environment variable should be used"
Provides:
  - php-5.3
  - "php"
  - "php(version) = 5.3.2"
Publishes:
  get-php-ini:
    Type: "FILESYSTEM:php-ini"
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
  set-mysql-connection-info:
    Type: "NET_TCP:db:mysql"
    Required : false
  set-postgres-connection-info:
    Type: "NET_TCP:db:postgres"
    Required : false
  set-doc-url:
    Type: "STRING:urlpath"
    Required : false
Scaling:
  Min: 1
  Max: -1
Group-Overrides:
  - components:
    - php-5.3
    - web_proxy
Endpoints:
  - Private-IP-Name:   IP1
    Private-Port-Name: HTTP_PORT
    Private-Port:      8080
    Public-Port-Name:  PROXY_HTTP_PORT
    Mappings:
      - Frontend:      "/front"
        Backend:       "/back"
Additional-Control-Actions:
  - threaddump
```

### Cartridge-Short-Name Element

OpenShift creates a number of environment variables for you when installing your cartridge.
This shortened name is used when creating those variables.
For example, using the example manifest, the following environment variables would be created:

    OPENSHIFT_PHP_DIR
    OPENSHIFT_PHP_IP
    OPENSHIFT_PHP_PORT
    OPENSHIFT_PHP_PROXY_PORT


### Cartridge-Version Element

The `Cartridge-Version` element is a version number identifying a release of your cartridge to OpenShift.
The value follows the format:

    <number>[.<number>[.<number>[...]]]

When you publish new versions of your cartridge to OpenShift, this number will be used to determine what
is necessary to upgrade the application developer's application. YAML will assume number.number is a float; 
be sure to enclose it in quotes so it is read as a string.

### Compatible-Versions Element

`Compatible-Versions` is a list of past cartridge versions that are **compatible** with this version.
To be **compatible** with a previous version, the code changes you made in this version do not require
the cartridge to be restarted or the application developer's application to be restarted.

    Compatible-Versions: ['1.0.1']

By not requiring a restart, you improve the application user's experience since no downtime will
be incurred from your changes. If the cartridge's current version is not in the list when upgraded,
the cartridge will be stopped, the new code will be installed, `setup` will be run, and the cartridge
started.

Today this is a simple list and string matching is used to determine compatible versions.
If this list proves to be unmanageable, future versions of OpenShift may implement maven dependency range style checking.

### Cartridge-Vendor

The `Cartridge-Vendor` element is used to differentiate cartridges when installed in the system.
As an individual, you should use the same unique value for all your cartridges to identify yourself;
otherwise, use your company name.

### Version Element

The `Version` element is the default or only version of the software packaged by this cartridge.

    Version: '5.3'

### Versions Element

`Versions` is the list of the versions of the software packaged by this cartridge.

    Versions: ['5.3']

### Source-Url Element

`Source-Url` is used when you self-distribute your cartridges. They are downloaded at the time
the application is created.

non-Git URL support

| Scheme | Method      | Expected Inputs                         |
| ------ | ------      | ---------------                         |
| https  | GET         | extensions zip, tar, tag.gz, tgz        |
| http   | GET         | extensions zip, tar, tag.gz, tgz        |
| file   | file copy   | cartridge directory tree expected       |

All Git schemes are supported. The cartridge source will be cloned from the given repository.

    Source-Url: https://github.com/example/killer-cartridge.git
    Source-Url: git://github.com/chrisk/fakeweb.git
    Source-Url: https://www.example.com/killer-cartridge.zip
    Source-Url: https://github.com/example/killer-cartridge/archive/master.zip

### Source-Md5 Element

If `Source-Md5` is provided and a non-Git scheme is used for downloading your cartridge, OpenShift will
verify the downloaded file against this MD5 digest.

    Source-Md5: 835ed97b00a61f0dae2e2b7a75c672db

### Additional-Control-Actions Element

The `Additional-Control-Actions` element is a list of optional actions supported by your cartridge. `threaddump` is an example of
one such action. OpenShift will only call optional actions if they are included in this element.
Supported optional actions:

    threaddump


### Endpoints Element
See below.

<!--- begin-chapter Managed_Files -->
## Managed Files
The `metadata/managed_files.yml` file provides an array of files or strings that are
managed or used during different stages of your cartridge lifecycle.
The keys for the entries (such as `locked_files`) can be specified
as either strings or Ruby symbols.  For example:

```yaml
locked_files:
- env/
- ~/.foorc
snapshot_exclusions:
- mydir/*
restore_transforms:
- s|${OPENSHIFT_GEAR_NAME}/data|app-root/data|
process_templates:
- '**/*.erb'
setup_rewritten:
- conf/*
```

### Entry Values

#### File Patterns
Most entries will use file patterns.
These patterns are treated like [Shell
globs](http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob).
Any entry that contains one or more `*` will be processed by `Dir.glob`
(with the `File::FNM_DOTMATCH` flag).
Any entry that ends in a `/` is treated as a directory; otherwise it
will be treated as a single file.

Any lines starting with `~/` will be anchored at the gear directory; 
otherwise, they will be anchored to your cartridge directory.

#### Strings
Some entries allow for string values in the arrays.
In this case, the values will be directly returned without any
modification.

### Allowed Entries
Currently, the following entries are supported:

| Entry               | Type         | Usage                                               |
| -----               | ----         | -----                                               |
| locked_files        | File Pattern | [Cartridge Locking][cart_locking]                   |
| snapshot_exclusions | File Pattern | [Backing up and Restoring your Cartridge][snapshot] |
| restore_transforms  | Strings      | [Backing up and Restoring your Cartridge][snapshot] |
| setup_rewritten     | File Pattern | [bin/setup](#binsetup)                              |
| process_templates   | File Pattern | [ERB Processing][erb_processing]                    |

<!--- begin-chapter Cartridge_Locking -->
## Cartridge Locking

Cartridge instances within a gear will be either `locked` or `unlocked`
at any given time. Locking a cartridge allows the cartridge scripts
to have additional access to the gear's files and directories. Other
scripts and hooks written by the application developer will not be able to
override decisions you make as the cartridge author.

The lock state is controlled by OpenShift. Cartridges are locked and
unlocked at various points in the cartridge lifecycle.

If you fail to provide a `locked_files` entry in
`metadata/managed_files.yml` or the file
is empty, your cartridge will remain always unlocked. For very simple cartridges, 
this may be sufficient.

**Note on security:** Cartridge file locking is not intended to be a
security measure. It is a mechanism to help prevent application developers
from inadvertently breaking their application by modifying files reserved
for use by you, the cartridge author.

### Lock Configuration ###

The `metadata/managed_files.yml` `locked_files` entry lists the files and directories, one
per line, that will be provided to the cartridge author with read/write
access while the cartridge is unlocked, but only read access to the
application developer while the cartridge is locked.

Any non-existent files that are included in the list will be created
before your `setup` script is called.  Any missing parent directories will be
created as needed. The list is anchored at the cartridge's directory.
An entry ending in slash is processed as a directory.  Entries ending
in asterisk are a list of files.  Entries ending in any other character
are considered files.  OpenShift will not attempt to change files to
directories or vice versa, and your cartridge may fail to operate if
files are miscategorized and you depend on OpenShift to create them.

#### Lock Configuration Example

Here is a `locked_files` entry for a PHP cartridge:

```yaml
locked_files:
- ~/.pearrc
- bin/
- conf/*
```

In the above list:
  * The file `~/.pearrc` will be created, if it does not exist, and be made editable by you.
  * The directory `php/bin` is locked but not the files it contains. While you can add files, both you
    and the application developer can edit any files contained.
  * The files in `php/conf` are locked but the directory itself is not, 
    so you or the application developer can add files, but only you can edit them.

Directories like `~/.node-gyp` and `~/.npm` in nodejs are **NOT** candidates
to be created in this manner as they require the application developer to have read
and write access while the application is deploying and running. These
directories would need to be created by the nodejs `setup` or `install` scripts.

The following list is reserved by OpenShift in the gear's home
directory:

    ~/.ssh
    ~/.sandbox
    ~/.tmp
    ~/.env
    any not hidden directory or file

You may create any hidden file or directory (one that starts with a
period) not in the reserved list in the gear's home directory while the
cartridge is unlocked.

<!--- begin-chapter Template_Directories -->
## Template Directories for Language Cartridges

The `template` or `template.git` directory should provide an minimal example of an application
written in the language/framework your cartridge is packaging.
Your application should welcome the application developer to
your cartridge and let them see that your cartridge has indeed been installed and operates.
If you provide a `template` directory, OpenShift will transform it into a bare git repository
for use by the application developer. If you provide a `template.git` directory, OpenShift will
copy the directory for use by the application developer. Your `setup` and `install` scripts should
assume that `template` directories may be converted to `template.git` during the packaging of your 
cartridge for use by OpenShift. The PaaS operator may choose to convert all `template` directories 
to bare git repositories `template.git` to obtain the performance gain when adding your cartridge 
to a gear.  One good workflow point to make this change is when your cartridge is packaged into an RPM.

A `ruby 1.8` with `Passenger` support would have a `public` sub-directory and
a `config.ru` file to define the web application.

    +- template
    |  +- config.ru
    |  +- public
    |  |  +- .gitignore
    |  .openshift
    |  +- markers
    |  |- ...

Note that .gitignore should be placed in empty directories to ensure they survive when the file tree
is loaded into a git repository.

### Application Developer Action Hooks

The sub-directory `.openshift/markers` may contain example files for the application developer.
These files denote behavior you are expected to honor in your cartridge's lifecycle. Current
examples from a Ruby 1.8 cartridge include:

| Marker               | Action |
| ------               | ------ |
| force_clean_build    | Previous output from `bundle install --deployment` will be removed and all gems will be reinstalled according to the current Gemfile/Gemfile.lock.|
| hot_deploy           | Will prevent the apache process from being restarted during build/deployment. Note that mod_passenger will respawn the Rack worker processes if any code has been modified. |
| disable_auto_scaling | Will prevent scalable applications from scaling up or down according to application load. |

You may add additional markers to allow an application developer to control aspects
of your cartridge.

The sub-directory `.openshift/action_hooks` will contain code the application developer
wishes to be run during lifecycle changes. Examples would be:

    pre_start_`cartridge name`
    post_start_`cartridge name`
    pre_stop_`cartridge name`
    ...

<!--- You can obtain a template for the `template` directory from [xxx](http://git...yyy).
You will want to download the repo as a zip file and extract the files into your
cartridge's `template` directory. Further details are in the `README.writing_applications.md`
document. -->

As a cartridge author you do not need to execute the default `action_hooks`.
OpenShift will call them during lifecycle changes based on the actions given to the
`control` script. If you wish to add additional hooks, you are expected to document them
and you will need to run them explicitly in your `control` script.

<!--- begin-chapter Exposing_Services_TCP_Endpoints -->
## Exposing Services / TCP Endpoints

Most cartridges provide a service by binding to one or many ports. Cartridges
must explicitly declare which ports they will bind to, and provide meaningful
variable names to describe the following:

  * Any IP addresses necessary for binding
  * The gear-local ports to which the cartridge services will bind
  * (Optional) Publicly proxied ports which expose gear-local ports for use by the
    application's users or intra-gear. These endpoint ports are only created when the
    application is scalable.

In addition to IP and port definitions, Endpoints are where frontend httpd mappings
for your cartridge are declared to route traffic from the outside world to your
cartridge's services.

These declarations represent Endpoints, and are defined in the cartridge
`manifest.yml` in the `Endpoints` section using the following format:

```
Endpoints:
  - Private-IP-Name:   <name of IP variable>
    Private-Port-Name: <name of port variable>
    Private-Port:      <port number>
    Public-Port-Name:  <name of public port variable>
    Mappings:
      - Frontend:      "<frontend path>"
        Backend:       "<backend path>"
        Options:       { ... }
      - <...>
  - <...>
```

During cartridge installation within a gear, IP addresses will be automatically
allocated and assigned to each distinct IP variable name, with the guarantee
that the specified port will be bindable on the allocated address.

If an endpoint specifies a public port variable, a public port proxy mapping will
be created using a random external port accessible via the gear's DNS entry.

Each portion of the Endpoint definition becomes available via environment variables
located within the gear and accessible to cartridge scripts and application code. The
names of these variables are prefixed with OpenShift namespacing information in the
follow the format:

```
OPENSHIFT_{Cartridge-Short-Name}_{name of IP variable}          => <assigned internal IP>
OPENSHIFT_{Cartridge-Short-Name}_{name of port variable}        => <endpoint specified port>
OPENSHIFT_{Cartridge-Short-Name}_{name of public port variable} => <assigned external port>
```

`Cartridge-Short-Name` is the `Cartridge-Short-Name` element from the cartridge manifest
file. See above.

If an Endpoint specifies a `Mappings` section, each mapping entry will be used
to create a frontend httpd route to your cartridge using the provided options.
The `Frontend` key represents a frontend path element to be connected to a
backend URI specified by the `Backend` key. The optional `Options` hash for a
mapping allows the route to be configured in a variety of ways:

```
Options:
  websocket      Enable web sockets on a particular path
  gone           Mark the path as gone (uri is ignored)
  forbidden      Mark the path as forbidden (uri is ignored)
  noproxy        Mark the path as not proxied (uri is ignored)
  redirect       Use redirection to uri instead of proxy (uri must be a path)
  file           Ignore request and load file path contained in uri (must be path)
  tohttps        Redirect request to https and use the path contained in the uri (must be path)
```

While more than one option is allowed, the above options conflict with each other.

### Endpoint Example

Given a cartridge named `CustomCart` and the following entry in `manifest.yml`:

```
Name: CustomCart
Cartridge-Short-Name: CUSTOMCART

...

Endpoints:
  - Private-IP-Name:   HTTP_IP
    Private-Port-Name: WEB_PORT
    Private-Port:      8080
    Public-Port-Name:  WEB_PROXY_PORT
    Mappings:
      - Frontend:      "/web_front"
        Backend:       "/web_back"
      - Frontend:      "/socket_front"
        Backend:       "/socket_back"
        Options:       { "websocket": true }

  - Private-IP-Name:   HTTP_IP
    Private-Port-Name: ADMIN_PORT
    Private-Port:      9000
    Public-Port-Name:  ADMIN_PROXY_PORT
    Mappings:
      - Frontend:      "/admin_front"
      - Backend:       "/admin_back"

  - Private-IP-Name:   INTERNAL_SERVICE_IP
    Private-Port-Name: 5544
    Public-Port-Name:  INTERNAL_SERVICE_PORT
```

The following environment variables will be generated:

```
# Internal IP/port allocations
OPENSHIFT_CUSTOMCART_HTTP_IP=<assigned internal IP 1>
OPENSHIFT_CUSTOMCART_WEB_PORT=8080
OPENSHIFT_CUSTOMCART_ADMIN_PORT=9000
OPENSHIFT_CUSTOMCART_INTERNAL_SERVICE_IP=<assigned internal IP 2>
OPENSHIFT_CUSTOMCART_INTERNAL_SERVICE_PORT=5544

# Public proxy port mappings
OPENSHIFT_CUSTOMCART_WEB_PROXY_PORT=<assigned public port 1>
OPENSHIFT_CUSTOMCART_ADMIN_PROXY_PORT=<assigned public port 2>
```

In the above example, the public proxy port mappings are as follows:

```
<assigned external IP>:<assigned public port 1> => OPENSHIFT_CUSTOMCART_HTTP_IP:OPENSHIFT_CUSTOMCART_WEB_PORT
<assigned external IP>:<assigned public port 2> => OPENSHIFT_CUSTOMCART_HTTP_IP:OPENSHIFT_CUSTOMCART_ADMIN_PORT
```

And finally, the following frontend httpd routes will be created:

```
http://<app dns>/web_front    => http://OPENSHIFT_CUSTOMCART_HTTP_IP:8080/web_back
http://<app dns>/socket_front => http://OPENSHIFT_CUSTOMCART_HTTP_IP:8080/socket_back
http://<app dns>/admin_front  => http://OPENSHIFT_CUSTOMCART_HTTP_IP:9000/admin_back
```

<!--- begin-chapter Cartridge_Scripts -->
## Cartridge Scripts

How you implement the cartridge scripts in the `bin` directory is
up to you as the author. For easily configured software where your
cartridge is just installing one version, these scripts may include all
the necessary code. For complex configurations or multi-version support,
you may choose to write these scripts as shim code to setup the necessary
environment before calling additional scripts you write. Or, you may
choose to create symlinks from these names to a name of your choosing.
Your API is the scripts and their associated actions.

### Notes on Execution of the Scripts
The scripts will be run directly from the home directory of the cartridge.
They need to have the executable bit turned on, and they should have
UNIX-friendly line endings (`\n`), not DOS ones (`\r\n`).

To ensure this, consider setting the following `git` options (just once)
so that the files have correct line endings in the git repository:

```
git config --global core.autocrlf input # use `true` on Windows
git config --global core.safecrlf true
```

To ensure that the excutable bit is on, on UNIX-like systems, run:

```
chmod +x bin/*
```

On Windows, you can achieve this by running:
```
git update-index --chmod=+x bin/*
```
in the cartridge directory.

### Mandatory Scripts

A cartridge must implement the following scripts:

| Script Name | Usage  |
| ----------- | -----  |
| setup       | prepare this instance of cartridge to be operational for the initial install and each upgrade |
| control     | command cartridge to report or change state                                                   |

### Optional Scripts

A cartridge may implement the following scripts:

| Script Name   | Usage  |
| -----------   | -----  |
| teardown      | prepare this instance of cartridge to be removed                                              |
| install       | prepare this instance of cartridge to be operational for the initial install                  |
| post-install  | an opportunity for configuration after the cartridge has been started for the initial install |

### Exit Status Codes

OpenShift follows the convention that your scripts should return zero
for success and non-zero for failure. Additionally, OpenShift supports
special handling of the following non-zero exit codes:

| Exit Code | Usage |
| --------- | ----- |
| 127       | TODO  |
| 131       | TODO  |

These exit status codes will allow OpenShift to refine its behavior
when returning HTTP status codes for the REST API, whether an internal
operation can continue or should aborted, etc. Should your script return
a value not included in this table, OpenShift will assume the problem
is fatal to your cartridge.

### ERB Processing
In order to provide flexible configuration and environment variables,
you may provide some values as [ERB templates][erb].

Your templates will be rendered at [`safe_level 2`][locking_ruby] and
are processed in 2 passes.

1. The first pass processes any entries in your `env` directory. This
   pass happens before `bin/setup` is called and is mandatory.
1. The second pass processes any entries specified in the
   `process_templates` entry of `metadata/managed_files.yml`. This pass
happens after `bin/setup` but before `bin/install`. This allows
`bin/setup` to create or modify ERB templates if needed. It also allows
for `bin/install` to use these values or processed files.

Examples:

* given `env/OPENSHIFT_MONGODB_DB_LOG_DIR.erb` containing:

  ```erb
  <% ENV['OPENSHIFT_HOMEDIR'] + "/mongodb/log/" %>
  ```

  becomes `env/OPENSHIFT_MONGODB_DB_LOG_DIR` containing:

  ```
  /var/lib/openshift/aa9e0f66e6451791f86904eef0939e/mongodb/log/
  ```

* given `conf/php.ini.erb` containing:

  ```erb
  upload_tmp_dir = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php/tmp/"
  session.save_path = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php/sessions/"
  ```

  becomes `conf/php.ini` containing:

  ```
  upload_tmp_dir = "/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/php/tmp/"
  session.save_path = "/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/php/sessions/"
  ```

Other candidates for templates are httpd configuration files for
`includes`, configuring databases to store persistent data in 
`OPENSHIFT_DATA_DIR`, and setting the application name in the `pom.xml` file.

### bin/setup

##### Synopsis

    setup [--version <version>]

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `setup` script is responsible for creating and/or configuring the
files that were copied from the cartridge repository into the gear's
directory.  Setup must also be reentrant and will be called on every
non-backward compatible upgrade.  Any logic you want to occur only once
should be added to `install`.

Any files created during `setup` should be added to
`setup_rewritten` section of `metadata/managed_files.yml`.
These files will be deleted prior to `setup` being run during upgrades.

If you have used ERB templates for software configuration those files will be
processed for environment variable substitution after `setup` is run.

Lock context: `unlocked`

### bin/install

##### Synopsis

    install [--version <version>]

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `install` script is responsible for creating and/or configuring the
files that were copied from the cartridge repository into the gear's
directory.  `install` will only be called on the initial install of a cartridge.

Any one-time operations, such as generating passwords, creating ssh keys, or adding environment 
variables, should occur in install.

Additionally, any client results/messages should also be reported in `install` rather than `setup`.

`install` may substitute a version dependent of the `template` or `template.git` directories.

Lock context: `unlocked`

### bin/post-install

##### Synopsis

    post-install [--version <version>]

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `post-install` script is an opportunity to configure your cartridge after the cartridge has been 
started and is only called for the initial install of the cartridge.

Lock context: `locked`

<!--- *fotios: Should all messaging options be consolidated? Maybe we can add a section to each script as to what messaging options are available.* -->

### bin/teardown

##### Synopsis

    teardown

##### Description

The `teardown` script prepares the gear for the cartridge to be
removed. This script will not called when the gear is destroyed.  The `teardown`
script is only run when a cartridge is to be removed from the gear.
The gear is expected to continue to operate minus the functionality of your cartridge
cartridge.

Lock context: `unlocked`

### bin/control

##### Synopsis

    control <action>

##### Options

* `action`: which operation the cartridge should perform.

##### Description

The `control` script allows OpenShift or user to control the state of the cartridge.

The list of operations your cartridge may be called to perform:

| Operation | Behavior |
| --------- | -------- |
| update-configuration, pre-build, build, deploy, or post-deploy            | described in the [OpenShift Builds](#openshift-builds) section |
| start         | start the software your cartridge controls                |
| stop          | stop the software your cartridge controls                 |
| status        | return an 0 exit status if your cartridge code is running |
| reload        | your cartridge and the packaged software needs to re-read their configuration information (this operation will only be called if your cartridge is running) |
| restart       | stop current process and start a new one for the code your cartridge packages              |
| threaddump    | if applicable, your cartridge should signal the packaged software to perform a thread dump |
| tidy          | all unused resources should be released (it is at your discretion to determine what should be done; be frugal as on some systems resources may be very limited) |
| pre-snapshot  | prepare the cartridge for a snapshot, e.g. dump database to flat file               |
| post-snapshot | clean up the cartridge after snapshot, e.g. remove database dump file               |
| pre-restore   | prepare the cartridge for restore                                                   |
| post-restore  | clean up the cartridge after being restored, load database with data from flat file |

Some possible `tidy` behaviors:
  * `rm $OPENSHIFT_{Cartridge-Short_Name}_DIR/logs/log.[0-9]`
  * `cd $OPENSHIFT_REPO_DIR ; mvn clean`

OpenShift has the following default `tidy` behaviors:
  * the Git repository will be garbage collected
  * all files will be removed from the `/tmp` directory

Lock context: `locked`

###### `status` Action

For a number of reasons, the application developer will want to be able
to query whether the software your cartridge packages is running and
behaving as expected.  A `0` exit status implies that the software is
running correctly. 

You may direct information to the application developer by writing
to stdout.  Errors may be return on stderr with a non-zero exit status.

OpenShift maintains the expected state of the gear/application in
`~/app-root/runtime/.state`. You may not use this to determine the
status of the software you are packaging.  That software may have
crashed so you would be returning an invalid status if you used this file's
value. Future versions of OpenShift may combine the results from the
`status` action and the value of the `.state` file to automatically
restart failed applications. For completeness, see the following `.state` values:

| Value     | Meaning                                                      |
| -----     | -------                                                      |
| building  | application is currently being built                         |
| deploying | application is currently being deployed                      |
| idle      | application has been shutdown because of no activity         |
| new       | gear has been created, but no application has been installed |
| started   | application has been commanded to start                      |
| stopped   | application has been commanded to stop                       |

### Messaging to OpenShift from Cartridge

Your cartridge may provide one or more services that are consumed by
multiple gears in one application. OpenShift provides the orchestration
necessary for you to publish this service or services. Each message is
written to stdout, one message per line.

* `ENV_VAR_ADD: <variable name>=<value>`
* `CART_DATA: <variable name>=<value>`
* `CART_PROPERTIES: <key>=<value>`
* `APP_INFO: <value>`

<!--- *fotios: This entry seems out of place and should be moved* -->

<!--- begin-chapter Custom_HTTP_Services -->
## Custom HTTP Services

Your cartridge may expose services using the application's URL by
providing one or more snippets of Apache configuration code using ERB templates
in the `httpd.d` directory. The `httpd.d` directory and its contents are
optional.  After OpenShift has run your `setup` script, it will render
each ERB template and write the contents of the node's httpd configuration.

An example of `mongodb.conf.erb`:

    Alias /health <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb/httpd.d/health.html" %>
    Alias / <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb/httpd.d/index.html" %>

<!--- begin-chapter Environment_Variables -->
## Environment Variables

Environment variables are used to communicate information between
this cartridge and others, as well as to OpenShift.  The cartridge controlled
variables are stored in the `env` directory and will be loaded after
system-provided environment variables but before your code is called.
OpenShift-provided environment variables will be loaded and available
to be used for all cartridge entry points.

You cannot override system provided variables by creating new copies in your cartridge `env` directory.
If you attempt to do so, when an application developer attempts to instantiate your cartridge the system
will raise an exception and refuse to do so.

### System Provided Variables (Read Only) ###

| Name                | Value                                                                                                                    |
| ----                | -----                                                                                                                    |
| HOME                | alias for `OPENSHIFT_HOMEDIR`                                                                                            |
| HISTFILE            | bash history file                                                                                                        |
| OPENSHIFT_APP_DNS   | the application's fully qualified domain name that your cartridge is a part of                                           |
| OPENSHIFT_APP_NAME  | the validated user assigned name for the application (black list is system dependent)                                    |
| OPENSHIFT_APP_UUID  | OpenShift-assigned UUID for the application                                                                              |
| OPENSHIFT_DATA_DIR  | the directory where your cartridge may store data                                                                        |
| OPENSHIFT_GEAR_DNS  | the gear's fully qualified domain name that your cartridge is a part of (may or may not be equal to `OPENSHIFT_APP_DNS`) |
| OPENSHIFT_GEAR_NAME | OpenShift-assigned name for the gear (may or may not be equal to `OPENSHIFT_APP_NAME`)                                   |
| OPENSHIFT_GEAR_UUID | OpenShift-assigned UUID for the gear                                                                                     |
| OPENSHIFT_HOMEDIR   | OpenShift-assigned directory for the gear                                                                                |
| OPENSHIFT_REPO_DIR  | the directory where the developer's application is "archived" to and will be run from                                    |
| OPENSHIFT_TMP_DIR   | the directory where your cartridge may store temporary data                                                              |
| TMPDIR              | alias for `OPENSHIFT_TMP_DIR`                                                                                            |
| TMP                 | alias for `OPENSHIFT_TMP_DIR`                                                                                            |

### System Provided Cartridge Variables (Read Only)
  * `OPENSHIFT_{Cartridge-Short-Name}_DIR`
  * `OPENSHIFT_{Cartridge-Short-Name}_IDENT`
  * `OPENSHIFT_PRIMARY_CARTRIDGE_DIR`

### Examples of Cartridge Variables  ###

These are variables provided to you for communicating to the application developer.  You may add
additional variables for your cartridge's or the packaged software's needs. You may provide these files in your
cartridge's `env` directory or choose to create them in your `setup` and `install` scripts.

 * `OPENSHIFT_MYSQL_DB_HOST`                  Backwards compatibility (ERB populate from `OPENSHIFT_MYSQL_DB_IP`)
 * `OPENSHIFT_MYSQL_DB_IP`
 * `OPENSHIFT_MYSQL_DB_LOG_DIR`
 * `OPENSHIFT_MYSQL_DB_PASSWORD`
 * `OPENSHIFT_MYSQL_DB_PORT`
 * `OPENSHIFT_MYSQL_DB_SOCKET`
 * `OPENSHIFT_MYSQL_DB_URL`
 * `OPENSHIFT_MYSQL_DB_USERNAME`
 * `OPENSHIFT_PHP_LOG_DIR`
 * `OPENSHIFT_PHP_DIR`

Some variables may be dictated by the software you are packaging:

 * `JENKINS_URL`
 * `JENKINS_USERNAME`
 * `JENKINS_PASSWORD`

Your environment variables should be prefixed with
`OPENSHIFT_{cartridge short name}_` to prevent overwriting other cartridge
variables in the packaged software's process environment space.

By convention, an environment variable whose value is a directory should have a
name that ends in `_DIR` and the value should have a trailing slash.
The software you are packaging may have environment variable requirements of its own,
for example: `JENKINS_URL`; these would be added to your `env` directory or included in shim code in your `bin` scripts.

Cartridge-provided environment variables are not validated by the
system. Your cartridge may fail to function if you write invalid data
to these files.

You may provide ERB templates in the `env` directory (see above for details). ERB templates in the `env` directory will
be processed before `setup` is called.

The `PATH` variable is set by OpenShift with the base being `/etc/openshift/env/PATH`.
If you provide an `OPENSHIFT_{Cartridge-Short-Name}_PATH_ELEMENT`, OpenShift will include the value when building the
`PATH` when your scripts are run or an application developer does an interactive log on.

<!--- begin-chapter Cartridge_Events -->
## Cartridge Events

Cartridges may need to act when another cartridge is added or removed from an application.
OpenShift supports a simple publish/subscribe system which allows cartridges to communicate
in the context of these events.

The `Publishes` and `Subscribes` sections of the cartridge `manifest.yml` are used to express
the event support for a given cartridge.

### Cartridge Event Publishing

Publish events are defined via the `manifest.yml` for the cartridge, in the following format:
```
Publishes:
  <event name>:
    Type: "<event type>"
  ...
```

When a cartridge is added to an application, each entry in the `Publishes`
section of the manifest is used to construct events dispatched to other cartridges 
in the application. For each publish entry, OpenShift will attempt to execute a
script named `hooks/<event name>`, e.g.:

    hooks/<event name> <gear name> <namespace> <gear uuid>

All lines of output (on stdout) produced by the script will be joined by single spaces and 
used as the input to matching subscriber scripts. All cartridges which declare a subscription 
whose `Type` matches that of the publish event will be notified.

### Cartridge Event Subscriptions

Subscriptions to events published by other carts are defined via the `manifest.yml` for the
cartridge, in the following format:
```
Subscribes:
  <event name>
    Type: "<event type>"
  ...
```

When a cartridge publish event is fired, the subscription entries in the `Subscribes`
section whose `Type` matches that of the publish event will be processed. For each
matching subscription event, OpenShift will attempt to execute a script named
`hooks/<event name>`, e.g.:

    hooks/<event name> <gear name> <namespace> <gear uuid> <publish output>

The format of the `<publish output>` input to the subscription script is defined by the 
implementation of the publisher script, and so the cartridge subscription script must have 
an awareness of the output format of the matching publish script.

### Cartridge Event Example

Consider a simple example of a PHP cartridge which can react when MySQL is added to
an application, so that it can set environment variables on the gear to be able to connect
to the newly added MySQL cartridge on a different gear.

This requires a `Subscribes` section in the PHP cartridge `manifest.yml`:
```
Subscribes:
  set-mysql-connection-info:
    Type: "NET_TCP:db:mysql"
```

And a `Publishes` section in the MySQL cartridge `manifest.yml`:
```
Publishes:
  publish-mysql-connection-info:
    Type: "NET_TCP:db:mysql"
```

The PHP cartridge implements a script in `hooks/set-mysql-connection-info`, and the MySQL
cartridge implements a script in `hooks/publish-mysql-connection-info`.

These events and scripts are matched on the basis of the string value in `Type` (`"NET_TCP:db:mysql"`).

The `publish-mysql-connection-info` script could output the host, port, and password to connect to
the MySQL instance, and it will be fed as input to the `set-mysql-connection-info` script in the 
PHP cart when MySQL is added to an application that has PHP installed.

For example, consider the following output from the `publish-mysql-connection-info` in the MySQL cartridge:

```
OPENSHIFT_MYSQL_DB_USERNAME=username;
OPENSHIFT_MYSQL_DB_PASSWORD=password;
OPENSHIFT_MYSQL_DB_HOST=hostname;
OPENSHIFT_MYSQL_DB_PORT=port;
OPENSHIFT_MYSQL_DB_URL=url;
```

This would be fed as input to `hooks/publish-mysql-connection-info` in the PHP cartridge, as follows:

    hooks/publish-mysql-connection-info gear_name namespace gear_uuid 'OPENSHIFT_MYSQL_DB_USERNAME=username;OPENSHIFT_MYSQL_DB_PASSWORD=password;OPENSHIFT_MYSQL_DB_HOST=hostname;OPENSHIFT_MYSQL_DB_PORT=port;OPENSHIFT_MYSQL_DB_URL=url;'

The `publish-mysql-connection-info` is responsible for being capable of parsing the final argument
and extracting the values provided.

<!--- begin-chapter Backing_Up_and_Restoring_Your_Cartridge -->
## Backing Up and Restoring Your Cartridge

OpenShift provides a snapshot/restore feature for user applications.  This feature is meant to allow OpenShift application developers to:

1. Capture the state ('snapshot') of their application and produce an archive of that state.
1. Use a previously taken snapshot of an application to restore the application to the state in the snapshot.
1. Use a previously taken snapshot of an application to restore a new application to the state in the snapshot.  This could be merely renaming an application or copying an application.

OpenShift uses the `tar` command when backing up and restoring the gear that
contains your cartridge. The file `metadata/managed_files.yml`
`snapshot_exclusions` entry contains an array of patterns of files that will not be backed up or
restored. If you exclude files from being backed up and restored you need
to ensure those files are not required for your cartridge's operation.

The file `metadata/managed_files.yml` `restore_transforms` entry
contains scripts that will be used to transform file names during
restore.

Both entries are optional and may be omitted. Empty files will be
ignored. Patterns are from the `OPENSHIFT_HOMEDIR` directory rather
than your cartridge's directory.  See the man page for `tar` (the `--transform`
and `--exclude-from` options) for more details.

### Understanding OpenShift Behavior: Snapshot

OpenShift creates an archive during `snapshot` as follows:

1. OpenShift stops the application by invoking `gear stop`.
1. OpenShift invokes `control pre-snapshot` for each installed cartridge in the gear.  Cartridges may control their serialization in the snapshot by implementing this control action in conjunction with exclusions (example: cartridge authors want to snapshot/restore to/from a database dump instead of a database file).
1. OpenShift builds a list of exclusions by reading the
   `snapshot_exclusions` list from the `metadata/managed_files.yml` file for each cartridge in the gear.
1. OpenShift creates an archive in tar.gz format and writes it to STDOUT for consumption by the client tools.  The following exclusions are used in addition to the list created from cartridges:
   1. Gear user `.tmp`, `.ssh`, `.sandbox`
   1. Application state file (`app-root/runtime/.state`)
   1. Bash history file (`$OPENSHIFT_DATA_DIR/.bash_history`)
1. OpenShift invokes `control post-snapshot` for each installed cartridge in the gear.
1. OpenShift starts the application by invoking `gear start`.

### Understanding OpenShift Behavior: Restore

OpenShift restores an application from an archive as follows:

1. OpenShift prepares the application for restoration.
   1. If the archive contains a git repo, the platform invokes `gear prereceive`.
   1. Otherwise, the platform invokes `gear stop`.
1. OpenShift invokes `control pre-restore` for each installed cartridge in the gear.  This allows cartridges that control their snapshotted state to prepare their cartridges for restoration (example: delete old database dump, if present).
1. OpenShift builds a list of transforms to apply by reading the
   `restore_transforms` entries from the `metadata/managed_files.yml` file of each cartridge installed in the gear.
1. OpenShift extracts the archive into the gear user's home directory, overwriting existing files, and applying the transformations obtained from cartridges.
1. OpenShift invokes `control post-restore` for each installed cartridge in the gear (example: delete new database dump that the db was restored from). 
1. OpenShift resumes the application.
   1. If the archive contains a git repo, OpenShift invokes `gear postreceive`.
   1. Otherwise, OpenShift invokes `gear start` .

<!--- begin-chapter Sample_confd_openshift_conf_erb -->
## Sample `conf.d/openshift.conf.erb`

```
ServerRoot "<%= ENV['OPENSHIFT_HOMEDIR'] + "/ruby-1.8" %>"
DocumentRoot "<%= ENV['OPENSHIFT_REPO_DIR'] + "/public" %>"
Listen <%= ENV['OPENSHIFT_RUBY_IP'] + ':' + ENV['OPENSHIFT_RUBY_PORT'] %>
User <%= ENV['OPENSHIFT_GEAR_UUID'] %>
Group <%= ENV['OPENSHIFT_GEAR_UUID'] %>

ErrorLog "|/usr/sbin/rotatelogs <%= ENV['OPENSHIFT_HOMEDIR']%>/ruby-1.8/logs/error_log-%Y%m%d-%H%M%S-%Z 86400"
CustomLog "|/usr/sbin/rotatelogs <%= ENV['OPENSHIFT_HOMEDIR']%>/logs/access_log-%Y%m%d-%H%M%S-%Z 86400" combined

PassengerUser <%= ENV['OPENSHIFT_GEAR_UUID'] %>
PassengerPreStart http://<%= ENV['OPENSHIFT_RUBY_IP'] + ':' + ENV['OPENSHIFT_RUBY_PORT'] %>/
PassengerSpawnIPAddress <%= ENV['OPENSHIFT_RUBY_IP'] %>
PassengerUseGlobalQueue off
<Directory <%= ENV['OPENSHIFT_REPO_DIR]%>/public>
  AllowOverride all
  Options -MultiViews
</Directory>
```

<!--- begin-chapter OpenShift_Builds -->
## OpenShift Builds

When changes are pushed to an application's Git repository, OpenShift will build
and deploy the application using the updated changes from the repository. The
specific build lifecycle which manages the build process changes depending on
the presence of a builder cartridge within the application.

### Default Build Lifecycle

When no builder cartridge has been added to the application, changes pushed to
the application Git repository result in the execution of the default build
lifecycle. The default lifecycle consists of a `build` and `deploy` phase, each
of which aggregates several steps.

In this lifecycle, OpenShift manages the start and stop of the application, as
well as moves the newly committed code into `$OPENSHIFT_REPO_DIR`. All other
specific behaviors are defined by the primary cartridge as well as any user
action hooks present.

Note: User action hooks are assumed to reside in
`$OPENSHIFT_REPO_DIR/.openshift/action_hooks`.

During the `build` phase:

1. The application is stopped.
1. The primary cartridge `pre-receive` control action is executed.
1. The primary cartridge `pre-repo-archive` control action is executed.
1. The newly committed application source code is copied to `$OPENSHIFT_REPO_DIR`.
   **Note**: This step is the only time the application source code is copied by 
   OpenShift during this lifecycle.
1. The primary cartridge `update-configuration` control action is executed.
1. The primary cartridge `pre-build` control action is executed.
1. The `pre-build` user action hook is executed, if present.
1. The primary cartridge `build` control action is executed.
1. The `build` user action hook is executed.

Next, during the `deploy` phase:

1. All secondary cartridges in the application are started.
1. The primary cartridge `deploy` control action is executed.
1. The `deploy` user action hook is executed, if present.
1. The primary cartridge is started (the application is now fully started).
1. The primary cartridge `post-deploy` control action is executed.
1. The `post-deploy` user action hook is executed, if present.

At this point, the application has been fully built and restarted.

### Default Scaling Build Lifecycle

A scalable application build proceeds exactly the same way as a regular application during the `build` phase on the head gear (i.e. the primary gear on which the web_proxy runs).

The difference in behavior comes during the `deploy` phase:

1. All secondary cartridges in the application are started on the head gear.
1.  The web_proxy cartridge `deploy` hook is executed on the head gear; it is responsible for distributing the code/build artifacts to the other gears and run the `deploy` steps on them as well.
1. The following steps are executed by the default web_proxy, i.e. haproxy: 
  1. The secondary gears are stopped.
  1. The code/build artifacts from the head gear are synced to secondary gears.
  1. The primary cartridge `update-configuration` control action is called on secondary gears.
  1. All secondary cartridges in the application are started on secondary gears.
  1. The primary cartridge `deploy` control action is executed on secondary gears.
  1. The `deploy` user action hook is executed, if present, on secondary gears.
  1. The primary cartridge is started (the application is now fully started) on secondary gears.
  1. The primary cartridge `post-deploy` control action is executed on secondary gears.
  1. The `post-deploy` user action hook is executed, if present, on secondary gears.
1. The primary cartridge `deploy` control action is executed on the head gear.
1. The `deploy` user action hook is executed, if present, on the head gear.
1. The primary cartridge is started (the application is now fully started) on the head gear.
1. The primary cartridge `post-deploy` control action is executed on the head gear.
1. The `post-deploy` user action hook is executed, if present, on the head gear.

### Builder Cartridge Lifecycle

If a builder cartridge is present in the application, changes pushed to the
application Git repository will execute using an alternate build lifecycle which
hands over operations to the builder cartridge. In this lifecycle, OpenShift
provides no specific behavior for the build beyond giving the builder cartridge
the opportunity to perform work. The sequence of events follows:

During the Git `pre-receive` hook:

1. The builder cartridge `pre-receive` control action is executed.

During the Git `post-receive` hook:

1. The builder cartridge `post-receive` control action is executed.

### Builder Tips

Any build implementation should take care to avoid duplicating source or copying
artifacts any more than necessary. The space a cartridge's build implementation
consumes during the build cycle is the application developer's, and so cartridge
authors should take care to be as conservative as possible.

[cart_locking]: #cartridge-locking
[snapshot]: #backing-up-and-restoring-your-cartridge
[erb_processing]: #erb-processing
[erb]: http://ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB.html
[locking_ruby]: http://www.ruby-doc.org/docs/ProgrammingRuby/html/taint.html).

## OpenShift Upgrades

The OpenShift runtime contains an upgrade system used to upgrade the cartridges in a gear to the latest available version and to apply gear-scoped changes which are orthogonal to cartridges to a gear.  The `oo-admin-upgrade` command provides the CLI for the upgrade system and can be used to upgrade all gears in an OpenShift environment, all gears on a node, or a single gear.  This command queries the openshift broker to determine the locations of the indicated gears to migrate and makes mcollective calls to trigger the upgrade for a gear.

During upgrades, OpenShift follows the following high-level process to upgrade a gear:

1.  Load the gear upgrade extension, if configured.
1.  Inspect the gear state.
1.  Run the gear extension's pre-upgrade method, if it exists.
1.  Compute the upgrade itinerary for the gear.
1.  If the itinerary contains an incompatible upgrade, stop the gear.
1.  Upgrade the cartridges in the gear according to the itinerary.
1.  Run the gear extension's post-upgrade method, if it exists.
1.  If the itinerary contains an incompatible upgrade, restart and validate the gear.
1.  Clean up after the upgrade by deleting pre-upgrade state and upgrade metadata.

### Upgrade Itinerary

The upgrade process must be re-entrant; if it fails or times out, a subsequent upgrade operation must pick up where the last one left off without losing any data about which operations must be performed to fully upgrade a gear.  The upgrade itinerary stores information about which cartridges in a gear must be upgraded and which type of upgrade to perform.

There are two types of cartridge upgrade process: compatible and incompatible.  Whether an upgrade from version X to version Y is compatible is driven by the presence of version X in version Y's `Compatible-Versions` manifest element.  Though compatible and incompatible upgrades differ in various ways, the chief difference is that when an incompatible upgrade is to be applied to any cartridge in a gear, that gear is stopped before the cartridge upgrades are performed and restarted after all cartridges have been upgraded.

The upgrade itinerary is computed as follows for each cartridge in a gear:

1.  Read in the current IDENT of the cartridge.
1.  If the vendor is not 'redhat', skip the cartridge.
1.  Select the name and software version of the cartridge from the cartridge repository; this will
    yield the manifest for the latest version of the cartridge.  If the manifest does not exist in the cartridge repository or does not include the software version, skip the cartridge.
1.  If the latest manifest is for the same cartridge version as that currently installed in the
    gear, skip the cartridge unless the `ignore_cartridge_version` parameter is set.  If the `ignore_cartridge_version` parameter is set, record an incompatible upgrade for the cartridge in the itinerary.  (TODO: case where manifest declares itself as compatible version).
1.  If the latest manifest includes the current cartridge version in the `Compatible-Versions`
    element, record a compatible upgrade for the cartridge in the itinerary.  Otherwise, record an incompatible upgrade for the cartridge in the itinerary.

### Compatible Upgrades

The compatible upgrade process for a cartridge is as follows:

1.  The new version of the cartridge is overlaid in the gear.
1.  The files declared in the `Processed-Templates` section of the cartridge's `managed-files.yml`
    are removed.
1.  The cartridge directory is unlocked.
1.  The cartridge directory is secured.
1.  If the cartridge provides an `upgrade` script, that script is executed.
1.  The cartridge directory is locked.

### Incompatible Upgrades

The incompatible upgrade process for a cartridge is as follows:

1.  The files and directories declared in the `Setup-Rewritten` section of the cartridge's 
    `managed_files.yml` are removed.
1.  The new version of the cartridge is overlaid in the gear.
1.  The cartridge directory is unlocked.
1.  The cartridge directory is secured.
1.  The cartridge `setup` script is run.
1.  The erb templates for the cartridge are processed.
1.  If the cartridge provides an `upgrade` script, that script is executed.
1.  The cartridge directory is locked.
1.  The frontend is connected.

### Cartridge Upgrade Script

A cartridge may provide an `upgrade` script in the `bin` directory which will be executed during the upgrade process.  The purpose of this script is to allow for arbitrary actions to occur during the upgrade process which are not accounted for by the compatible or incompatible processes.  If the `upgrade` script is provided, it will be passed the following arguments:

1.  The software version of the cartridge.
1.  The current cartridge version.
1.  The cartridge version being upgraded to.

A non-zero exit code from this script will result in the upgrade operation failing until the exit code is corrected.
