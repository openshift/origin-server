OpenShift Origin - Platform as a Service
========================================

This repository contains the core components of the OpenShift service
released under the [OpenShift Origin source
project](https://openshift.redhat.com/community/open-source).  The
components in this repository are sufficient to self host an OpenShift
instance -- [download a LiveCD image with everything
preconfigured](https://openshift.redhat.com/app/opensource/download) or
[read more about running OpenShift
locally](https://openshift.redhat.com/community/wiki/build-your-own) on
our wiki.

Architecturally OpenShift is split into the following core subsystems:

*   __Node__
    Hosted applications are run in isolated containers on each node -
the system can operate many nodes at any one time.
*   __Cartridge__
    Frameworks/components used to build an application (Ex: JBoss)
*   __Broker__
    Central service exposing a REST API for consumers and coordinating
with each node.
*   __Console__
    Web management console using the REST API to allow users to easily
create and manage applications.
*   __Admin Console__
    Web console with admin focused reporting and utilities
*   __Messaging System__
    Communication pipeline between the broker and each node.
*   __User Authentication__
    Pluggable authentication for controlling access to the broker
*   __Domain Name Management__
    Each hosted application receives a unique domain name to simplify
SSL termination and deployment

A [comprehensive architecture
overview](http://openshift.github.io/documentation/oo_system_architecture_guide.html)
can be found on our wiki.

The primary command line interface to OpenShift is [RHC](https://github.com/openshift/rhc).


Contributing
----------------------

Visit the [OpenShift Origin Open Source
page](https://openshift.redhat.com/community/open-source) for more
information on the community process and how you can get involved.
Also see our [Contributor Guidelines](CONTRIBUTING.md).


Mirrors
----------------------

The OpenShift Origin content is mirrored on
[mirror.openshift.com](http://mirror.openshift.com/). This content is also
available through other mirrors worldwide.

* http://mirror.digmia.com/openshift/ (SK, Europe)
* http://ftp.inf.utfsm.cl/pub/openshift/ (CL, South America)
* http://mirror.oss.maxcdn.com/openshift (Zlin, Czech, Europe)
* http://mirror.getupcloud.com/?prefix=openshift/ (BR, South America)

Copyright
----------------------

OpenShift Origin, except where otherwise noted, is released under the
[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
See the LICENSE file located in each component directory.


Export Control
----------------------

This software distribution includes cryptographic software that is
subject to the U.S. Export Administration Regulations (the “*EAR*”) and
other U.S. and foreign laws and may not be exported, re-exported or
transferred (a) to any country listed in Country Group E:1 in Supplement
No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan,
and Syria); (b) to any prohibited destination or to any end user who has
been prohibited from participating in U.S. export transactions by any
federal agency of the U.S. government; or (c) for use in connection with
the design, development or production of nuclear, chemical or biological
weapons, or rocket systems, space launch vehicles, or sounding rockets,
or unmanned air vehicle systems. You may not download this software or
technical information if you are located in one of these countries or
otherwise subject to these restrictions. You may not provide this
software or technical information to individuals or entities located in
one of these countries or otherwise subject to these restrictions. You
are also responsible for compliance with foreign law requirements
applicable to the import, export and use of this software and technical
information. 
