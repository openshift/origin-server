# How To Write An OpenShift Origin Cartridge 2.0

OpenShift cartridges provide the necessary command and control for
the functionality of software that is running user's applications.
OpenShift currently has many language cartridges JBoss, PHP, Ruby
(Rails) etc. as well as many DB cartridges such as Postgres, Mysql,
Mongo etc. Before writing your own cartridge you should search the
current list of [Red Hat](https://openshift.redhat.com) and [OpenShift
Community](https://openshift.redhat.com/community) provided cartridges.

Cartridge configuration and setup is convention based, with an emphasis
on minimizing external dependencies in your cartridge code.

## Cartridge Directory Structure

This is an example structure to which your cartridge is expected to
conform when written to disk. Failure to meet these expectations will
cause your cartridge to not function when either installed or used on
OpenShift. You may have additional directories or files as required to meet
the needs of the software you are packaging and the application developers
using your cartridge.

    `vendor name`-`cartridge name`
     +- bin                        (required)
     |  +- setup                   (optional)
     |  +- install                 (optional)
     |  +- post-setup              (optional)
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
    `conf.d` is the usual name for where a web framework would install it's `httpd` configuration.


To support multiple software versions within one cartridge,
you may create symlinks between the bin/control and the 
versions/{software version}/bin/control file. Or, you may choose
to use the bin/control file as a shim to call the correct versioned
control file.

When creating an instance of your cartridge for use by a gear, OpenShift
will copy the files, links and directories from the cartridge library
with the exclusion of the `usr` directory. The `usr` directory will be
sym-linked into the gear's cartridge instance. This allows for sharing
of libraries and other data across all cartridge instances.

Later (see Cartridge Locking) we'll describe how, as the cartridge author,
you can customize a cartridge instance.

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
Cartridge-Versions: ['1.0.1']
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

OpenShift creates a number of environment variables for you, when installing your cartridge.
This shorten name is used when creating those variables.
For example, using the example manifest the following environment variables would be created:

    OPENSHIFT_PHP_DIR
    OPENSHIFT_PHP_IP
    OPENSHIFT_PHP_PORT
    OPENSHIFT_PHP_PROXY_PORT


### Cartridge-Version Element

The `Cartridge-Version` element is a version number identifying a release of your cartridge to OpenShift.
The value follows the format:

    <number>[.<number>[.<number>[...]]]

When you publish new versions of your cartridge to OpenShift, this number will be used to determine what
is necessary to upgrade the application developer's application. YAML will assume number.number is a float
be sure to enclose it in quotes so it is read as a string.

### Cartridge-Versions Element

`Cartridge-Versions` is a list of past cartridge versions that are **compatible** with this version.
To be **compatible** with a previous version, the code changes you made in this version do not require
the cartridge to be re-started or the application developer's application to be restarted.

    Cartridge-Versions: ['1.0.1']

By not requiring a restart, you improve the application user's experience since no downtime will
be incurred from your changes. If the cartridge's current version is not in the list when upgraded,
the cartridge will be stopped, the new code will be installed, `setup` will be run, the cartridge
started and `post-setup` will be run.

Today this is a simple list and string matching is used to determine compatible versions.
If this list proves to be unmanageable, future versions of OpenShift may implement maven dependency range style checking.

### Cartridge-Vendor

The `Cartridge-Vendor` element is used to differentiate cartridges when installed in the system.
As an individual you should use the same unique value for all your cartridges to identify yourself,
otherwise use your company name.

### Version Element

The `Version` element is the default or only version of the software packaged by this cartridge.

    Version: '5.3'

### Versions Element

`Versions` is the list of the versions of the software packaged by this cartridge.

    Versions: ['5.3']

### Source-Url Element

`Source-Url` is used when you self distribute your cartridges. They are downloaded at the time
the application is created.

 - non-Git Schemes supported:
    - https(get): zip, tar, tar.gz/tgz files
    - http(get):  zip, tar, tar.gz/tgz files
    - file(copy): files in directories in tree

 - Git Schemes:
    - Cartridge source will be cloned from these repository

    ```
    Source-Url: https://github.com/exampe/killer-cartridge.git
    Source-Url: git://github.com/chrisk/fakeweb.git
    Source-Url: https:://www.example.com/killer-cartridge.zip
    Source-Url: https://github.com/example/killer-cartridge/archive/master.zip
    ```

### Source-Md5 Element

If `Source-Md5` is provided and a non-Git scheme is used for downloading your cartridge, OpenShift will
verify the downloaded file against this MD5 digest.

    Source-Md5: 835ed97b00a61f0dae2e2b7a75c672db

 - Git clones are not verified.

### Additional-Control-Actions Element

The `Additional-Control-Actions` element is a list of optional actions supported by your cartridge.  `threaddump` is an example of
one such action. OpenShift will only call optional actions if they are included in this element.
Supported optional actions:

    threaddump


### Endpoints Element
See below.

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
- **/*.erb
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
Any entry that ends in a `/` is treated as a directory, otherwise it
will be treated as a single file.

Any lines starting with `~/` will be anchored at the gear directory,
otherwise they will be anchored to your cartridge directory.

#### Strings
Some entries allow for string values in the arrays.
In this case, the values will be directly returned without any
modification.

### Allowed Entries
Currently, the following entries are supported

| Entry                 | Type         | Usage                                               |
| -----                 | ----         | -----                                               |
| `locked_files`        | File Pattern | [Cartridge Locking][cart_locking]                   |
| `snapshot_exclusions` | File Pattern | [Backing up and Restoring your Cartridge][snapshot] |
| `restore_transforms`  | Strings      | [Backing up and Restoring your Cartridge][snapshot] |
| `setup_rewritten`     | File Pattern | [bin/setup](#binsetup)                              |
| `process_templates`   | File Pattern | [ERB Processing][erb_processing]                    |

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
is empty, your cartridge will remain always unlocked. For a very simple cartridges
this may be sufficient.

**Note on security:** Cartridge file locking is not intended to be a
security measure. It is a mechanism to help prevent application developers
from inadvertently breaking their application by modifying files reserved
for use by you, the cartridge author.

### Lock configuration ###

The `metadata/managed_files.yml` `locked_files` entry lists the files and directories, one
per line, that will be provided to the cartridge author with read/write
access while the cartridge is unlocked, but only read access to the
application developer while the cartridge is locked.

Any non-existent files that are included in the list will be created
before your `setup` script is called.  Any missing parent directories will be
created as needed. The list is anchored at the cartridge's directory.
An entry ending in slash is processed as a directory.  Entries ending
in asterisk are a list of files.  Entries ending in an other character
are considered files.  OpenShift will not attempt to change files to
directories or vice versa, and your cartridge may fail to operate if
files are miscategorized and you depend on OpenShift to create them.

#### Lock configuration example

Here is a `locked_files` entry for a PHP cartridge:

```yaml
locked_files:
- ~/.pearrc
- bin/
- conf/*
```

In the above list:
  * the file `~/.pearrc` will be created, if it does not exists, and be made editable by you.
  * the directory `php/bin` is locked but not the files it contains. While you can add files, both you
    and the application developer can edit any files contained.
  * the files in `php/conf` are locked but the directory itself is not.
    So you or the application developer can add files, but only you can edit them.

Directories like `~/.node-gyp` and `~/.npm` in nodejs are **NOT** candidates
to be created in this manner as they require the application developer to have read
and write access while the application is deploying and running. These
directories would need to be created by the nodejs `setup` or `install` scripts.

The following list is reserved by OpenShift in the the gear's home
directory:

    ~/.ssh
    ~/.sandbox
    ~/.tmp
    ~/.env
    any not hidden directory or file

You may create any hidden file or directory (one that starts with a
period) not in the reserved list in the gear's home directory while the
cartridge is unlocked.

## template vs template.git (for language cartridges)

`template` or `template.git` directory should provide an minimal example of an application
written in the language/framework your cartridge is packaging.
Your application should welcome the application developer to
your cartridge and let them see that your cartridge has indeed been installed and operating.
If you provide a `template` directory, OpenShift will transform it into a bare git repository
for use by the application developer. If you provide a `template.git` directory, OpenShift will
copy the directory for use by the application developer. Your `setup` and `install` scripts should
assume that `template` directories may be converted to `template.git` during the packaging of your 
cartridge for use by OpenShift. The PaaS operator may choose to convert all `template` directories 
to bare git repositories `template.git` to obtain the performance gain when adding your cartridge 
to gear.  One good workflow point to make this change is when your cartridge is packaged into an RPM.

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
These files denote behavior you are expected to honor in your cartridges lifecycle. Current
examples from a Ruby 1.8 cartridge include:

    force_clean_build     Previous output from bundle install --deployment will be
                          removed and all gems will be reinstalled according to the
                          current Gemfile/Gemfile.lock.
    hot_deploy            Will prevent the apache process from being restarted during
                          build/deployment. Note that mod_passenger will respawn the
                          Rack worker processes if any code has been modified.
    disable_auto_scaling  Will prevent scalable applications from scaling up
                          or down according to application load.

You may add additional markers to allow an application developer to control aspects
of your cartridge.

The sub-directory `.openshift/action_hooks` will contain code the application developer
wishes run during lifecycle changes. Examples would be:

    pre_start_`cartridge name`
    post_start_`cartridge name`
    pre_stop_`cartridge name`
    ...

You can obtain a template for the `template` directory from [xxx](http;//git...yyy).
You will want to down the repo as a zip file and extract the files into your
cartridge's `template` directory. Further details are in the README.writing_applications.md
document.

As a cartridge author you do not need to execute the default `action_hooks`.
OpenShift will call them during lifecycle changes based on the actions given to the
`control` script. If you wish to add additional hooks, you are expected to document them
and you will need to run them explicitly in your `control` script.

## Exposing Services / TCP Endpoints

Most cartridges provide a service by binding to one or many ports. Cartridges
must explicitly declare which ports they will bind to, and provide meaningful
variable names to describe:

  * Any IP addresses necessary for binding
  * The gear-local ports to which the cartridge services will bind
  * (Optional) Publicly proxied ports which expose gear-local ports for use by the
    application's users or intra-gear. These endpoint ports are only created when the
    application is scalable.

In addition to IP and port definitions, Endpoints are where frontend httpd mappings
for your cartridge are declared to route traffic from the outside world to your
cartridge's services.

These declarations represent "Endpoints," and are defined in the cartridge
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

Each portion of the endpoint definition becomes available via environment variables
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

If an endpoint specifies a `Mappings` section, each mapping entry will be used
to create a frontend httpd  route to your cartridge using the provided options.
The `Frontend` key represents a frontend path element  to be connected to a
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

* `setup` and/or `install`: prepare this instance of cartridge to be operational for the initial install and each upgrade
* `control`: command cartridge to report or change state

A cartridge may implement the following scripts:
* `teardown`: prepare this instance of cartridge to be removed
* `install`: prepare this instance of cartridge to be operational for the initial install
* `post-setup`: an opportunity for setup after the cartridge has been started for the initial install and each upgrade
* `post-install`: an opportunity for setup after the cartridge has been started for the initial install

### Exit Status Codes

OpenShift follows the convention that your scripts should return zero
for success, and non-zero for failure. Additionally, OpenShift supports
special handling of the following non-zero exit codes:

    127. TODO
    131. TODO

These exit status codes will allow OpenShift to refine it's behavior
when returning HTTP status codes for the REST API, whether an internal
operation can continue or should aborted etc. Should your script return
a value not included in this table, OpenShift will assume the problem
is fatal to your cartridge.

## ERB Processing
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

* `env/OPENSHIFT_MONGODB_DB_LOG_DIR.erb`

  ```erb
  <% ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/log/" %>
  ```

  becomes `env/OPENSHIFT_MONGODB_DB_LOG_DIR`

  ```
  /var/lib/openshift/aa9e0f66e6451791f86904eef0939e/mongodb-2.2/log/
  ```

* `conf/php.ini.erb`

  ```erb
  upload_tmp_dir = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php/tmp/"
  session.save_path = "<%= ENV['OPENSHIFT_HOMEDIR'] %>php/sessions/"
  ```

  becomes `conf/php.ini`

  ```
  upload_tmp_dir = "/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/php/tmp/"
  session.save_path = "/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/php/sessions/"
  ```

Other candidates for templates are httpd configuration files for
`includes`, configuring database to store persistent data in the
`OPENSHIFT_DATA_DIR`, and setting the application name in the pom.xml file.

## bin/setup

##### Synopsis

`setup [--version <version>]`

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `setup` script is responsible for creating and/or configuring the
files that were copied from the cartridge repository into the gear's
directory.  Setup must also be reentrant and will be called on every
non backward compatible upgrade.  Any logic you want to occur only once
should be added to install.

Any files created during `setup` should be added to
`setup_rewritten` section of `metadata/managed_files.yml`.
These files will be deleted prior to `setup` being run during upgrades.

If you have used ERB templates for software configuration those files will be
processed for environment variable substitution after `setup` is run.

Lock context: `unlocked`

## bin/install

##### Synopsis

`install [--version <version>]`

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `install` script is responsible for creating and/or configuring the
files that were copied from the cartridge repository into the gear's
directory.  `install` will only be called on the initial install of a cartridge.

Any one time operations such as generating passwords, creating ssh keys, adding environment 
variables should occur in install.

Also any client results/messages should also be reported in install rather than setup.

`install` may substitute a version dependent of the `template` or `template.git` directories.

Lock context: `unlocked`

## bin/post-setup

##### Synopsis

`post-setup [--version <version>]`

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `post-setup` script is an opportunity to configure your cartridge after the cartridge has been 
started.  Like setup it must also be reentrant and is called for each non backward compatible cartridge 
upgrade.

Any files created during `post-setup` should be added to
`setup_rewritten` section of `metadata/managed_files.yml`
so that they may be cleared before upgrades.

Lock context: `locked`

## bin/post-install

##### Synopsis

`post-install [--version <version>]`

##### Options

* `--version <version>`: Selects which version of cartridge to install. If no version is provided,
the version denoted by the `Version` element from `manifest.yml` will be installed.

##### Description

The `post-install` script is an opportunity to configure your cartridge after the cartridge has been 
started and is only called for the initial install of the cartridge.

Lock context: `locked`

*fotios: Should all messaging options be consolidated? Maybe we can add a section to each script as to what messaging options are available.*
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

*fotios: This entry seems out of place and should be moved*
## Custom HTTP Services

Your cartridge may expose services using the application's URL by
providing snippet(s) of Apache configuration code using ERB templates
in the httpd.d directory. The httpd.d directory and it's contents are
optional.  After OpenShift has run your `setup` script it will render
each ERB template, and write the contents the node's httpd configuration.

An example of `mongodb-2.2.conf.erb`:

    Alias /health <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/httpd.d/health.html" %>
    Alias / <%= ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/httpd.d/index.html" %>

## bin/teardown

##### Synopsis

`teardown`

##### Description

The `teardown` script prepares the gear for the cartridge to be
removed. This script will not called when the gear is destroyed.  The `teardown`
script is only run when a cartridge is to be removed from the gear.
The gear is expected to continue to operate minus the functionality of your cartridge
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

The list of operations your cartridge may be called to perform:

   * `process-version`, `pre-build`, `build`, `deploy`, and `post-deploy` are called at various
     points during the build lifecycle, described in the [OpenShift Builds](#openshift-builds) section.
   * `start` start the software your cartridge controls
   * `stop` stop the software your cartridge controls
   * `status` return an 0 exit status if your cartridge code is running.
   * `reload` your cartridge and the packaged software needs to re-read their
      configuration information. This operation will only be called if your cartridge is
      running.
   * `restart` stop current process and start a new one for the code your cartridge packages
   * `threaddump` if applicable, your cartridge should signal the packaged software to perform a thread dump.
   * `tidy` all unused resources should be released. It is at your discretion to
     determine what should be done. Be frugal, on some systems resources may be
     very limited. Some possible behaviors: 
      * `rm $OPENSHIFT_CART_DIR/logs/log.[0-9]`
      * `cd $OPENSHIFT_REPO_DIR ; mvn clean`
   * `pre-snapshot` prepare the cartridge for snapshot
   * `post-snapshot` clean up the cartridge after snapshot
   * `pre-restore` prepare the cartridge for restore
   * `post-restore` clean up the cartridge after being restored
     
    OpenShift has the following default behaviors:
      * the Git repository will be garbage collected
      * all files will be removed from the `/tmp` directory

Lock context: `locked`

###### `status` Action

For a number of reasons the application developer will want to be a
to query whether the software your cartridge packages is running and
behaving as expected.  A `0` exit status implies that the software is
running correctly. 

You may direct information to the application developer by writing
to stdout.  Errors may be return on stderr with an non-zero exit status.

OpenShift maintains the expected state of the gear/application in
`~/app-root/runtime/.state`. You may not use this to determine the
status of the software you are packaging.  That software may have
crashed so you would be returning invalid status if you used this file's
value. Future versions of OpenShift may combine the results from the
`status` action and the value of the `.state` file to automatically
restart failed applications. For completeness, `.state` values:

| Value       | Meaning                                                      |
| -----       | -------                                                      |
| `building`  | application is currently being built                         |
| `deploying` | application is currently being deployed                      |
| `idle`      | application has been shutdown because of no activity         |
| `new`       | gear has been created, but no application has been installed |
| `started`   | application has been commanded to start                      |
| `stopped`   | application has been commanded to stop                       |

## Environment Variables

Environment variables are use to communicate information between
this cartridge and others, and to OpenShift.  The cartridge controlled
variables are stored in the env directory and will be loaded after
system provided environment variables but before your code is called.
OpenShift provided environment variables will be loaded and available
to be used for all cartridge entry points.

### System Provided Variables (Read Only) ###

| Name                  | Value                                                                                                                   |
| ----                  | -----                                                                                                                   |
| `HOME`                | alias for `OPENSHIFT_HOMEDIR`                                                                                           |
| `HISTFILE`            | bash history file                                                                                                       |
| `OPENSHIFT_APP_DNS`   | the application's fully qualified domain name that your cartridge is a part of                                          |
| `OPENSHIFT_APP_NAME`  | the validated user assigned name for the application. Black list is system dependent.                                   |
| `OPENSHIFT_APP_UUID`  | OpenShift assigned UUID for the application                                                                             |
| `OPENSHIFT_DATA_DIR`  | the directory where your cartridge may store data                                                                       |
| `OPENSHIFT_GEAR_DNS`  | the gear's fully qualified domain name that your cartridge is a part of. May or may not be equal to `OPENSHIFT_APP_DNS` |
| `OPENSHIFT_GEAR_NAME` | OpenShift assigned name for the gear. May or may not be equal to `OPENSHIFT_APP_NAME`                                   |
| `OPENSHIFT_GEAR_UUID` | OpenShift assigned UUID for the gear                                                                                    |
| `OPENSHIFT_HOMEDIR`   | OpenShift assigned directory for the gear                                                                               |
| `OPENSHIFT_REPO_DIR`  | the directory where the developer's application is "archived" to and will be run from.                                  |
| `OPENSHIFT_TMP_DIR`   | the directory where your cartridge may store temporary data                                                             |
| `TMPDIR`              | alias for `OPENSHIFT_TMP_DIR`                                                                                           |
| `TMP`                 | alias for `OPENSHIFT_TMP_DIR`                                                                                           |

### System Provided Cartridge Variables (Read Only)
  * `OPENSHIFT_{Cartridge-Short-Name}_DIR`

### Examples of Cartridge Variables  ###

These are variables you either provided to you for communicating to the application developer.  You may add
additional variables for your cartridges or the packaged software needs. You may provide these files in your
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

Some variable may be dictated by the software you are packaging:

 * `JENKINS_URL`
 * `JENKINS_USERNAME`
 * `JENKINS_PASSWORD`

Your environment variables should be prefixed with
`OPENSHIFT_{cartridge short name}_` to prevent overwriting other cartridge
variables in the packaged software's process environment space.

By convention, an environment variable whose value is a directory should have a
name that ends in `_DIR` and the value should have a trailing slash.
The software you are packaging may have environment variable requirements of it's own,
for example: `JENKINS_URL`.
Those you would add to your `env` directory or include in shim code in your `bin` scripts.

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

    export OPENSHIFT_MONGODB_DB_LOG_DIR='<% ENV['OPENSHIFT_HOMEDIR'] + "/mongodb-2.2/log/" %>'

renders as `env/OPENSHIFT_MONGODB_DB_LOG_DIR`:

    export OPENSHIFT_MONGODB_DB_LOG_DIR='/var/lib/openshift/aa9e0f66e6451791f86904eef0939e/mongodb-2.2/log/'

You may assume the `PATH` variable will be:
     PATH=/bin:/usr/bin/

when your code is executed. Any additional directories your code requires
will need to be added in your cartridge's `env` variable.

## Backing up and Restoring your cartridge

OpenShift provides a snapshot/restore feature for user applications.  This feature is meant to allow OpenShift application developers to:

1. Capture the state ('snapshot') of their application and produce an archive of that state.
1. Use a previously taken snapshot of an application to restore the application to the state in the snapshot.
1. Use a previously taken snapshot of an application to restore a new application to the state in the snapshot.  This could be merely renaming an application, or copying an application.

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
than your cartridge's directory.  See the man page for `tar` the `--transform`
and `--exclude-from` for more details.

### Understanding OpenShift Behavior: Snapshot

OpenShift creates an archive during `snapshot` as follows:

1. OpenShift stops the application by invoking `gear stop`
1. OpenShift invokes `control pre-snapshot` for each installed cartridge in the gear.  Cartridges may control their serialization in the snapshot by implementing this control action in conjunction with exclusions. (Example: cartridge authors wants to snapshot/restore to/from a database dump instead of a database file).
1. OpenShift builds a list of exclusions by reading the
   `snapshot_exclusions` list from the `metadata/managed_files.yml` file for each cartridge in the gear.
1. OpenShift creates an archive in tar.gz format and writes it to STDOUT for consumption by the client tools.  The following exclusions are used in addition to the list created from cartridges:
   1. Gear user `.tmp`, `.ssh`, `.sandbox`
   1. Application state file (`app-root/runtime/.state`)
   1. Bash history file (`$OPENSHIFT_DATA_DIR/.bash_history`)
1. OpenShift invokes `control post-snapshot` for each installed cartridge in the gear.
1. Openshift starts the application by invoking `gear start`

### Understanding OpenShift Behavior: Restore

Openshift restores an application from an archive as follows:

1. OpenShift prepares the application for restoration:
   1. If the archive contains a git repo, the platform invokes `gear prereceive`
   1. Otherwise, the platform invokes `gear stop`
1. OpenShift invokes `control pre-restore` for each installed cartridge in the gear.  This allows cartridges that control their snapshotted state to prepare their cartridges for restoration (Example: delete old database dump, if present)
1. OpenShift builds a list of transforms to apply by reading the
   `restore_transforms` entries from the `metadata/managed_files.yml` file of each cartridge installed in the gear.
1. OpenShift extracts the archive into the gear user's home directory, overwriting existing files, and applying the transformations obtained from cartridges.
1. OpenShift invokes `control post-restore` for each installed cartridge in the gear.  (Example: delete new database dump that db was restored from). 
1. OpenShift resumes the application:
   1. If the archive contains a git repo, OpenShift invokes `gear postreceive`
   1. Otherwise, OpenShift invokes `gear start` 

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

`hooks/<event name> <gear name> <namespace> <gear uuid>`

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

`hooks/<event name> <gear name> <namespace> <gear uuid> <publish output>`

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

For example, the following output from the `publish-mysql-connection-info` in the MySQL cartridge:

```
OPENSHIFT_MYSQL_DB_USERNAME=username;
OPENSHIFT_MYSQL_DB_PASSWORD=password;
OPENSHIFT_MYSQL_DB_HOST=hostname;
OPENSHIFT_MYSQL_DB_PORT=port;
OPENSHIFT_MYSQL_DB_URL=url;
```

Would be fed as input to `hooks/publish-mysql-connection-info` in the PHP cartridge:

`hooks/publish-mysql-connection-info gear_name namespace gear_uuid 'OPENSHIFT_MYSQL_DB_USERNAME=username;OPENSHIFT_MYSQL_DB_PASSWORD=password;OPENSHIFT_MYSQL_DB_HOST=hostname;OPENSHIFT_MYSQL_DB_PORT=port;OPENSHIFT_MYSQL_DB_URL=url;'`

The `publish-mysql-connection-info` is responsible for being capable of parsing the final argument
and extracting the values provided.

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
well as moving the newly committed code into `$OPENSHIFT_REPO_DIR`. All other
specific behaviors are defined by the primary cartridge as well as any user
action hooks present.

Note: User action hooks are assumed to reside in
`$OPENSHIFT_REPO_DIR/.openshift/action_hooks`.

During the `build` phase:

1. The application is stopped
1. The primary cartridge `pre-receive` control action is executed
1. The newly committed application source code is copied to `$OPENSHIFT_REPO_DIR`
   **Note**: This step is the only time the application source code is copied by 
   OpenShift during this lifecycle.
1. The primary cartridge `process-version` control action is executed
1. The primary cartridge `pre-build` control action is executed
1. The `pre-build` user action hook is executed (if present)
1. The primary cartridge `build` control action is executed
1. The `build` user action hook is executed

Next, during the `deploy` phase:

1. All secondary cartridges in the application are started
1. The primary cartridge `deploy` control action is executed
1. The `deploy` user action hook is executed (if present)
1. The primary cartridge is started (the application is now fully started)
1. The primary cartridge `post-deploy` control action is executed
1. The `post-deploy` user action hook is executed (if present)

At this point, the application has been fully built and restarted.

### Builder Cartridge Lifecycle

If a builder cartridge is present in the application, changes pushed to the
application Git repository will execute using an alternate build lifecycle which
hands over operations to the builder cartridge. In this lifecycle, OpenShift
provides no specific behavior for the build beyond giving the builder cartridge
the opportunity to perform work. The sequence of events follows:

During the Git `pre-receive` hook:

1. The builder cartridge `pre-receive` control action is executed

During the Git `post-receive` hook:

1. The builder cartridge `post-receive` control action is executed

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
