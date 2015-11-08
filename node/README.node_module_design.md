TODO:

- [ ] Gear log design. Think syslog fanning to gear specific logs
- [ ] Maintain .state file for gear
- [ ] Template git repo needs to be identified by cartridge setup


# How To Write An OpenShift Origin Node Platform 2.0

OpenShift node platforms provide the interface for the broker to command a gear or gear's cartridge.

## Gear Directory Structure

This is the structure to which gears are expected to conform when written
to disk.

    .../`uuid`/cartridges/
    +- `cartridge vendor`-`cartridge name`
    |   +-... (See README.writing_cartridges.md for cartridge details.)
    +- `cartridge vendor`-`cartridge name`
    |   +- see above...
    +- app-root
    |  +- data
    |  +- runtime
    |     +- repo
    |  +- log
    |     +- `uuid`.log  (OpenShift logs information that application developer may need. Not application log, gear log.)
    +- git
    +- .ssh
    +- .tmp
    +- .sandbox
    +- .env

## Cartridge Locking

Cartridge instances within a gear will be either `locked` or `unlocked`
at any given time.  Locking a cartridge allows the cartridge author scripts
to have additional access to the gear's files and directories. Other
scripts and hooks written by the application developer will not be able
to override decisions made by the cartridge author.

### Lock configuration

For the cartridge the `metadata/locked_files.txt` lists the files and
directories, one per line, that you will provide to the cartridge author
with read/write access while the cartridge is unlocked, but only read
access to the application developer while the cartridge is locked.

This is the list of reserved items in the gear's home directory:

    .ssh
    .sandbox
    .tmp
    .env
    any not hidden directory or file

When unlocking a cartridge, you will:
    1. create any non-existent entries that are included in the
       list. Entries are anchored at the gear's home directory.
    2. log a warning on any reserved entries
    3. chown entries to gear user
    4. chcon entries to set selinux context of gear user

An entry ending in slash is processed as a directory.  Entries ending
in asterisk are a list of files.  Entries ending in an other character
are considered files.  Do not attempt to change files to directories or
vice versa, log a warning if this attempted.

If the cartridge author fails to provide a `metadata/locked_files.txt`
file or the file is empty, do nothing.

When locking a cartridge, you will:
    1. chown entries to root
    2. chcon entries to root

You may assume the cartridge author has set the file and directory mode
bits correctly.

## Cartridge Operations

To install any php cartridge:

     # cp -ad ./php-5.3 ~UUID/cartridges/php-5.3 - Run as root
     # (setup ~UUID/git repository)              - Run as root
     # stickshift/unlock.rb UUID php-5.3         - Run as root
     $ ~/cartridges/php-5.3/setup --version 5.3  - Bulk of work, run as user, from ~UUID
     # stickshift/lock.rb UUID php-5.3           - Run as root
     $ ~/php-5.3/control start                   - Run as user

To remove a php cartridge:

     $ ~cartridges/php-5.3/control stop        - Run as user
     # stickshift/unlock.rb UUID php-5.3       - Run as root
     $ ~/cartridge/php-5.3/teardown            - Run as user, from ~UUID
     # stickshift/lock.rb UUID php-5.3         - Run as root


## High Level Orchestrations

Broker level orchestrations which are accomplished by the node library.


### Create Application

* Gear Create
* Cartridge Install
* Expose Endpoints
* Execute connectors


## Node Operation Summary

An overview of the higher level capabilities of the node, with information
about how lower-level operations are orchestrated / invoked.


### Gear Operations

* Create
* Delete


### Cartridge Operations

* `setup`
* `teardown`
* Expose Endpoints (implemented in node platform using manifest)
* Conceal Endpoints (implemented in node platform using manifest)
* Add / remove environment variables
* Start / Stop / Restart (Control cartridge?)

## Node Operation Details

### Gear Create

* Create a UNIX account representing the gear
* Create skeletal gear file system entries
* Create cgroups / mcslabels?
* Create port proxy config                           * jwh: proxy or endpoint here? *
* Create standard gear environment variable(s)
 * `HISTFILE`                 bash history file
  * Default: ~UUID/app-root/data/.bash_history
 * `OPENSHIFT_APP_DNS`        the application's fully qualified domain name maintained by the Broker
 * `OPENSHIFT_APP_NAME`       the validated user assigned name for the application. Black list is maintained by the Broker.
 * `OPENSHIFT_APP_UUID`       UUID maintained by Broker for the application that owns this gear
 * `OPENSHIFT_DATA_DIR`       the directory where a cartridge may store data
  * Default: ~UUID/app-root/data
 * `OPENSHIFT_GEAR_DNS`       the gear's fully qualified domain name that your cartridge is a part of. May or may not be equal to
                              `OPENSHIFT_APP_DNS`
 * `OPENSHIFT_GEAR_NAME`      Broker assigned name for the gear. May or may not be equal to `OPENSHIFT_APP_NAME`
 * `OPENSHIFT_GEAR_UUID`      UUID used for the gear's UNIX user's account field
 * `OPENSHIFT_HOMEDIR`        Directory for the gear
  * Default: $GEAR_BASE_DIR/UUID
 * `OPENSHIFT_INTERNAL_IP`    the private IP address for this gear
 * `OPENSHIFT_INTERNAL_PORT`  the private PORT for this gear
 * `OPENSHIFT_REPO_DIR`       the directory where the developer's application is archived to, and run from
 * `OPENSHIFT_TMP_DIR`        the directory where a cartridge may store temporary data
  * Default: /tmp
 * `OPENSHIFT_{Cartridge-Short-Name}_DIR`  `Cartridge-Short-Name` from manifest points to cartridge root directory
* Install default gear httpd conf
* Bounce node httpd

### Gear Delete

* Corral and kill all gear user processes (see pkill)
* Call cartridge teardown, if one exists
* Delete gear httpd conf
* Delete gear directories
* Delete gear user

TODO: deal with node httpd bouncing somewhere

### Cartridge Setup

* Disable cgroups
* Create the initial cart directory from the cart library/template
* Populate the gear git repository if a template provided by the cartridge
* Process env ERB templates
* Load gear + cartridge env variables
* Unlock cartridge
* Call cartridge setup
* Lock cartridge
* Load gear + cartridge env variables (This pulls in any env variables created by `setup`)
* Expose endpoint(s)
* Call cartridge control start
* Install cart-supplied node http.d confs (ERB templates)
* Bounce the node httpd
* Enable cgroups

### Cartridge Teardown

* Conceal endpoint(s)
* Disable cgroups
* Load gear + cartridge env variables
* Call cartridge control stop
* Unlock cartridge
* Call cartridge teardown, if one exists
* Uninstall cart-supplied node httpd.confs
* Lock cartridge (this may lock files/directories that are left elsewhere in the gear)
* Delete cartridge directory
* Enable cgroups
* Bounce the node httpd (performance impact?)

### Cartridge Expose Endpoints

* Read cartridge manifest
* Create .env/OPENSHIFT_${CART_NS}_PROXY_PORT
* Report OPENSHIFT_GEAR_DNS, OPENSHIFT_${CART_NS}_PROXY_PORT, OPENSHIFT_INTERNAL_IP, OPENSHIFT_INTERNAL_PORT back to broker

### Cartridge Conceal Endpoints

* Read cartridge manifest
* Delete .env/OPENSHIFT_${CART_NS}_PROXY_PORT
* remove_proxy_port $uuid "$OPENSHIFT_INTERNAL_IP:$OPENSHIFT_INTERNAL_PORT"

### Running Cartridge Scripts

#### Environment Variables

 1. Read /etc/openshift/env
 2. Read gear `.env` directory, merge into 1. overwriting duplicates
 3. Read cartridge `env` directory, merge into 2. overwriting duplicates
