# OpenShift Origin Frontend HTTP Server Plugins

## Overview

The frontend HTTP server plugins control the public facing application
web servers and present a standardized API for node management
routines to access.

This guide is intended for OpenShift administrators, service
operators, and developers to understand how the plugins work and what
their choices are on deployment.


## Plugins

The frontend HTTP server plugins provide a standardized interface for
managing the application web front-ends.

More than one plugin can be in use at the same time.  When that is the
case, every method call becomes a method call in each loaded plugin
and the results are merged in a contextually sensitive manner.

For example, different plugins will typically only record and return
the connection options that they parse.  The connection options will
be merged together for reporting the connection as one setting with
all set options from all plugins.

All frontend HTTP API methods are optional for plugins; however, the
lack of API functionality may translate to lack of capabilities for
the frontend HTTP service.  For example, if no plugin supports idling
applications, then testing for idle applications will silently fail.


### apachedb

The `apachedb` plugin is a dependency of the `apache-mod-rewrite,
`apache-vhost` and `nodejs-websocket` and provides base functionality.

An additional plugin, `GearDBPlugin` is provided for common
book-keeping operations and will automatically be included when a
plugin requiring `apachedb` is in use.

    Gem: openshift-origin-frontend-apachedb
    RPM: rubygem-openshift-origin-frontend-apachedb

### apache-mod-rewrite

The `apache-mod-rewrite` plugin provides the Apache `mod_rewrite`
based gear frontend.

This frontend uses `mod_rewrite` configured by a set of Berkeley DB
files to manage proxying application web requests to their respective
gears.

The `mod_rewrite` frontend owns the default Apache virtual hosts and
has limited flexibility, but can scale to high density deployments
with thousands of gears on a node while maintaining high performance.

The `apache-mod-rewrite` frontend is incompatible with the
`apache-vhost` plugin and their RPMs may not coexist on the same node.

    Gem: openshift-origin-frontend-apache-mod-rewrite
    RPM: rubygem-openshift-origin-frontend-apache-mod-rewrite


### nodejs-websocket

The `nodejs-websocket` plugin manages the NodeJS custom gear router
with websocket support.

The `nodejs-websocket` plugin may coexist with either the
`apache-mod-rewrite` or `apache-vhost` plugins; but not both.

    Gem: openshift-origin-frontend-nodejs-websocket
    RPM: rubygem-openshift-origin-frontend-nodejs-websocket

### apache-vhost

The `apache-vhost` plugin provides the Apache Virtual Host based gear
frontend.

This plugin is used where there will typically be less than 100 gears
per node, the gears are added and removed slowly and either classic
Apache behavior or customization are a priority.

The `apache-vhost` frontend is incompatible with the
`apache-mod-rewrite` plugin and their RPMs may not coexist on the same
node.

    Gem: openshift-origin-frontend-apache-vhost
    RPM: rubygem-openshift-origin-frontend-apache-vhost


## Configuration

Configuring the set of plugins is required by the node.  This is
accomplished by installing appropriate packages and setting the
`OPENSHIFT_FRONTEND_HTTP_PLUGINS` variable in
`/etc/openshift/node.conf`.

The value is a comma separated list of names of Ruby Gems to load for
plugins.  Other plugins may be pulled in as dependencies of a plugin
or be loaded by another mechanism (ex: `apachedb`).

All plugins which have been loaded into the running environment will
be used regardless of whether they were explicitly requested in
`node.conf`.

Ex:

    # Gems for managing the frontend http server
    # NOTE: Steps must be taken both before and after these values are changed.
    #       Run "oo-frontend-plugin-modify  --help" for more information.
    OPENSHIFT_FRONTEND_HTTP_PLUGINS=openshift-origin-frontend-apache-mod-rewrite,openshift-origin-frontend-nodejs-websocket


## Changing Configuration

It is possible to change the set of plugins after applications have
been created.

This process must be done cautiously, with no other activity on the
application serving node.  Application creation, deletion or any other
change must not be allowed while this operation commences.  Further,
applications will be unreachable during this operation.

A complete, and tested backup of the node is recommended prior to
starting.

The frontend configuration must be backed up first.  The backup is
used to restore the complete state of the frontend at the end of the
operation.

    oo-frontend-plugin-modify --save > file


The frontend configuration must be wiped out.

    oo-frontend-plugin-modify --delete


Remove and install frontend plugin packages as necessary.

    rpm --nodeps -e rubygem-openshift-origin-frontend-apache-mod-rewrite
    yum -y install rubygem-openshift-origin-frontend-apache-vhost


Modify any customized http server configuration and restart the server.

    vi /etc/httpd/conf.d/000000_default.conf
    service httpd restart


Change the value of `OPENSHIFT_FRONTEND_HTTP_PLUGINS` in
`/etc/openshift/node.conf` and restart mcollective.

    vi /etc/openshift/node.conf
    service ruby193-mcollective restart


Finally, rebuild the working http frontend configuration from the
current set of installed gears.

    oo-frontend-plugin-modify --restore < file
