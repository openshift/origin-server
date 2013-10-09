# OpenShift Origin SNI Proxy Frontend

## Overview

The SNI proxy allows applications to provide services that are carried
directly over a TLS connection but may not be HTTP based.  For
example, AMQP over TLS as opposed to HTTP over SSL/TLS (https).

The SNI proxy presents itself as a plugin to the FrontendHttpServer
API in OpenShift and is configured via endpoint mappings in the
cartridge manifest.


## Client Requirements

The SNI proxy requires that clients use TLS with the SNI extension.

The SNI extension must contain either the FQDN of the application or
an alias which has been set for an application through the OpenShift
API.

The SNI proxy will inspect the SNI extension in the client connection.
If either TLS or SNI is not in use, or the SNI extension points to a
nonexistent application then the connection will be closed.  Clients
should deal gracefully with connections being closed before the
application protocol (ex: AMQP) has begun negotiation.

Due to limited availability, the SNI proxy is constrained to a specific
set of ports.  Clients must be able to select which port they contact
for a specific application service and must be able to handle
different applications using different ports.


## Cartridge and Application Requirements

Cartridges using the SNI proxy ultimately terminate the TLS
connection.  The cartridge software must properly accept TLSv1 or
later and will have access to all client TLS parameters, including the
SNI extension.

Cartridges must allow applications to provide their own X509 server
certificates, and should accommodate clients that expect an X509
certificate for the FQDN it contacted whether its an alias or the
primary name of the application.


## Cartridge Configuration

Cartridges request the SNI proxy through a cartridge endpoint by
specifying that the endpoint uses the TLS protocol and requesting a
mapping.

The mapping frontend path requests which SNI proxy port to be used.  It may be one of the following:

 1. A blank ("") which causes the first SNI proxy port to be selected.
 1. "TLS_PORT_1", "TLS_PORT_2", etc... which causes the first, second, etc... SNI proxy port to be selected.
 1. A port number, which will be used only if it is in the set of configured SNI proxy ports.

Specific port numbers should be avoided as they can differ between
OpenShift installations, or even be changed by the administrator after
deployment.

The SNI proxy port numbers are constrained, and are unlikely to be the
port a service is normally expected to be on.

The mapping backend path is not used.

Example:
```
Endpoints:
- Private-IP-Name: AMQPS_IP
  Private-Port-Name: AMQPS_PORT
  Private-Port: 5671
  Public-Port-Name: AMQPS_PUBLIC_PORT
  Protocols: [tls]
  Mappings:
  - Frontend: ''
    Backend: ''
```

The exposed port will be reported back as a client result.
```
  Cartridge mock exposed URL tls:foo.example.com:2303
```

The reported URL reports the protocol as "tls" instead of the
application protocol (ex: "amqps").  It is up to the cartridge
documentation to clarify client requirements.

For more information, please refer to the [OpenShift Origin Cartridge Developer's Guide](http://openshift.github.io/documentation/oo_cartridge_developers_guide.html).


## SNI Proxy Requirements and Configuration

The SNI proxy reads its configuration from the OpenShift node
configuration files.
```
/etc/openshift/node.conf
/etc/openshift/node-plugins.d/openshift-origin-frontend-haproxy-sni-proxy.conf
```

The SNI proxy is configured for ports 2303 through 2308 by default.

This list is configurable through the "PROXY_PORTS" parameter in
`openshift-origin-frontend-haproxy-sni-proxy.conf`.  Caution should be
used changing the list to ensure that there are no conflicts,
including with the gear port proxy.

The proxy ports should have a firewall policy similar to ports 80 and
443 (HTTP and HTTPS).  Typically, allowing contact.

Depending on the configuration, the port proxy will bind to loopback
(127.0.0.1) and the IP address of the public facing network interface
(eg: eth0).  If an IP address cannot be determined, then the port
proxy will bind to INADDR_ANY.

The SNI proxy requires haproxy-1.5 for SNI support.  As haproxy-1.5 is
beta, it is expected to be installed alongside the default system
version of haproxy and located at `/usr/sbin/haproxy15`.

