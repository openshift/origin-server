Notice of Export Control Law

This software distribution includes cryptographic software that is
subject to the U.S. Export Administration Regulations (the "*EAR*")
and other U.S. and foreign laws and may not be exported, re-exported
or transferred (a) to any country listed in Country Group E:1 in
Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North
Korea, Sudan & Syria); (b) to any prohibited destination or to any end
user who has been prohibited from participating in U.S. export
transactions by any federal agency of the U.S. government; or (c) for
use in connection with the design, development or production of
nuclear, chemical or biological weapons, or rocket systems, space
launch vehicles, or sounding rockets, or unmanned air vehicle
systems.You may not download this software or technical information if
you are located in one of these countries or otherwise subject to
these restrictions. You may not provide this software or technical
information to individuals or entities located in one of these
countries or otherwise subject to these restrictions. You are also
responsible for compliance with foreign law requirements applicable to
the import, export and use of this software and technical information.

-------------------------------------------------------------------------------

This is a Dynamic DNS plugin for Openshift Origin which uses the
Dnsmasq DNS service on the back end.

One of Openshift's primary tasks is publishing the DNS records for
applications so that they will be accessable to the application
users. Dnsmasq has two aspects which make it of limited use for
Openshift:

1) No implementation of RFC2136 - DNS Updates

2) No means of establishing a secondary or proper zone delegation.

The first point means that the DNS server must reside on the same host
as the Openshift broker.  Only one broker is allowed in the Openshift
configuration. The plugin updates the Dnsmasq configuration files and
restarts the Dnsmasq process.

The second point means that all of the hosts involved in the Openshift
service, the broker, all of the nodes and any client host or user host
must all use the broker host as their first and only nameserver host.

For use in Openshift, Dnsmasq is suited to testing and development 
environments or to small closed networks behind a NAT.

=== Configuration ===

The Dnsmasq plugin is configured in the same way as the other DNS
plugins. This is a sample of the Ruby hash definition needed to
configure the Dnsmasq plugin.



        @dns = {
          # service control
          :config_file => "/etc/dnsmasq.conf",
          :hosts_dir => "/etc/dnsmasq.d",
          :pid_file => "/var/run/dnsmasq.pid"
          :system => false,  # use the system service start/stop mechanisms?

          # openshift new app zone
          :zone => "example.com",

          # query and verification
          :server => "ns1.example.com",
          :port => 2053,
        }

The Dnsmasq server must be able to bind port 53 (so it must run as
root). The Openshift broker must be allowed to modify the config file,
the contents of the hosts directory and to restart the Dnsmasq
service.

=== Unit Testing ===

The plugin unit tests are written using Rspec 2.x and can be run using
a rake target:

  rake spec

=== References ===

  RFC 2163 -  Dynamic Updates in the Domain Name System (DNS UPDATE)
    http://www.ietf.org/rfc/rfc2136.txt

  Dnsmasq - Dnsmasq is a lightweight, DNS forwarder and DHCP server
    http://www.thekelleys.org.uk/dnsmasq/doc.html