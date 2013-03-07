Openshift Origin - DNS Plugin for GSS-TSIG
============================

This plugin extends OpenShift's ability to integrate with DNS servers that require secure updates via GSS-TSIG, e.g. Microsoft's Active Directory. It provides dynamic DNS updates securely using Kerberos. DNS updates are mandatory for external clients to access gears being instantiated on OpenShift node(s). The most difficult part of getting this plugin to work is the configuration of the Active Directory, the export of a valid Kerberos service principal and the configuration of the broker host to be integrated with the Active Directory.

TODO: Full guide on how to ingegrate plugin. Basic requirements are host with krb5 integration, service principle in AD for DNS mapped to a user and a host and that keytab available to the apache user. There's an applicable configuration file found in /etc/openshift/plugins.d for this specific plugin and is self-explanatory. More to come.


Contributing
----------------------

Visit the [OpenShift Origin Open Source page](https://openshift.redhat.com/community/open-source) for more information on the community process and how you can get involved. Also see our [Contributor Guidelines](CONTRIBUTING.md).


Copyright
----------------------

OpenShift Origin, except where otherwise noted, is released under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html). See the LICENSE file located in each component directory.


Export Control
----------------------

Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
