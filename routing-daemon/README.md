Configuring ActiveMQ
--------------------

The ActiveMQ node routing plug-in must be enabled so that it sends routing
updates that the programs in this directory can read.  Install
`rubygem-openshift-origin-routing-activemq` and see its included `README.md` for
instructions.

Configuring the Daemon
----------------------

The daemon must be configured to connect to ActiveMQ. Edit
`/etc/openshift/routing-daemon.conf` and set `ACTIVEMQ_USER`,
`ACTIVEMQ_PASSWORD`, `ACTIVEMQ_HOST`, and `ACTIVEMQ_DESTINATION` to the
appropriate credentials, address, and ActiveMQ destination (topic or
queue).

Exactly one routing module must be enabled.  A module for F5 BIG-IP LTM, a
module for an routing implementing the LBaaS REST API, and a module that
configures nginx as a reverse proxy are included in this repository.  Edit
`/etc/openshift/routing-daemon.conf` to set the `LOAD_BALANCER` setting to "f5",
"lbaas", or "nginx" and then following the appropriate module-specific
configuration described below.

Internally, the routing daemon logic is divided into controllers, which
encompass higher-level logic, and models, which encompass the logic for
communicating with load balancers.  These controllers include a simple
controller that immediately dispatches commands to the load balancer (used for
nginx and F5), a controller that includes logic to batch configuration changes
and only dispatch commands to the load balancer at an interval (configurable
using the `UPDATE_INTERVAL` option in `routing-daemon.conf`; used if `LOAD_BALANCER` is
set to `f5_batched`), and an asynchronous controller for load balancers (such as
LBaaS) where it is necessary first to issue commands and then to poll for an
asynchronous confirmation on each command.

For testing purposes, a dummy model, which merely prints actions that
a normal model performs rather than performing actions itself, is also
included.  If you specify the "dummy" module, then you will get the
dummy model with the simple controller; if you specify the "dummy_async"
module, then you will get the dummy model with the asynchronous
controller.

Using F5 BIG-IP LTM
-------------------

Edit `/etc/openshift/routing-daemon.conf` to set the appropriate values for
`BIGIP_HOST`, `BIGIP_USERNAME`, `BIGIP_PASSWORD`, `BIGIP_MONITOR`,
`BIGIP_SSHKEY`, `VIRTUAL_SERVER`, and `VIRTUAL_HTTPS_SERVER` to match your F5
BIG-IP LTM configuration.

F5 BIG-IP LTM must be configured with two virtual servers, one for HTTP traffic
and one for HTTPS traffic. Each virtual server needs to be assigned at least
one VIP. A default client-ssl profile must also be configured as the default
SNI client-ssl profile. Although the naming of the default client-ssl profile
is unimportant, it does need to be added to the HTTPS virtual server. The LTM
admin user's 'Terminal Access' must be set to 'Advanced shell' so that remote
bash commands may be executed. Additionally, for the remote key management
commands to execute, the `BIGIP_SSHKEY` public key must be added to the LTM
admin's `.ssh/authorized_keys` file. The daemon will automatically create pools
and associated local-traffic policy rules, add these profiles to the virtual
servers, add members to the pools, delete members from the pools, and delete
empty pools and unused policy rules when appropriate. Once the LTM virtual
servers have been created, update `VIRTUAL_SERVER` and `VIRTUAL_HTTPS_SERVER`
in `/etc/openshift/routing-daemon.conf` to match the names you've used. The
daemon will name the pools after applications following the template
"/Common/ose-#{app_name}-#{namespace}" and create policy rules to forward
requests to pools comprising the gears of the named application.

Using LBaaS
-----------

After enabling the LBaaS module as described in the section on configuring the
daemon, edit `/etc/openshift/routing-daemon.conf` to set the appropriate values
for `LBAAS_HOST`, `LBAAS_TENANT`, `LBAAS_TIMEOUT`, `LBAAS_OPEN_TIMEOUT`,
`LBAAS_KEYSTONE_HOST`, `LBAAS_KEYSTONE_USERNAME`, `LBAAS_KEYSTONE_PASSWORD`, and
`LBAAS_KEYSTONE_TENANT`, to match your LBaaS configuration.

Using nginx
-----------

Edit `/etc/openshift/routing-daemon.conf` to set the appropriate values for
`NGINX_CONFDIR` and `NGINX_SERVICE`.

The daemon will automatically create and manage `server.conf` and `pool_*.conf`
files under the directory specified by `NGINX_CONFDIR`.  After each update, the
daemon will reload the service specified by `NGINX_SERVICE`.


Pool and Route Names
--------------------

By default, new pools will be created with the name
`pool_ose_{appname}_{namespace}_80` while new routes will be created with the
name `route_ose_{appname}_{namespace}.`  You can override these defaults by
setting appropriate values for the `POOL_NAME` and `ROUTE_NAME` settings,
respectively.  The values for these settings should contain the following
formats so that each application gets its own uniquely named pool and routing
rule: `%a` is expanded to the name of the application, and `%n` is expanded to
the application's namespace.

Monitors
--------

The F5 and LBaaS backends can add an existing monitor to newly created pools.
The following settings control how these monitors are created.

Set the `MONITOR_NAME` to the name of the monitor you would like to use, and set
`MONITOR_PATH` to the pathname to use for the monitor, or leave either option
unspecified to disable the monitor functionality.

Set `MONITOR_UP_CODE` to the code that indicates that a pool member is up, or
leave `MONITOR_UP_CODE` unset to use the default value of "1".

Set `MONITOR_TYPE` to either "http-ecv" or "https-ecv" depending on whether you
want to use HTTP or HTTPS for the monitor, leave `MONITOR_TYPE` unset to use the
default value of "http-ecv".

Set `MONITOR_INTERVAL` to the interval at which the monitor will send requests,
or leave `MONITOR_INTERVAL` unset to use the default value of "10".

Set `MONITOR_TIMEOUT` to the monitor's timeout for its requests, or leave
`MONITOR_TIMEOUT` unset to use the default value of "5".

As with `POOL_NAME` and `ROUTE_NAME`, `MONITOR_NAME` and `MONITOR_PATH` both can
contain `%a` and `%n` formats, which are expanded the same way.  Unlike
`POOL_NAME` and `ROUTE_NAME`, you may or may not want to re-use the same monitor
for different applications.  The daemon will automatically create a new monitor
when `MONITOR_NAME` expands a string that does not match the name of any
existing monitor.

It is expected that for each pool member, the load balancer will send a `GET`
request to the resource identified on that host by the value of `MONITOR_PATH`
for the associated monitor, and that the host will respond with the value of
`MONITOR_UP_CODE` if the host is up or some other response if the host is not
up.

##Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
