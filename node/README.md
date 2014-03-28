# @markup markdown
# @title OpenShift Origin Node

# OpenShift Origin Node

## Core Terminology

* *A Node* refers to the machine where user's applications are run. 
* *The OpenShift Origin Node module* is a library which provides the Broker with a set of APIs to manage a Gears and Cartridges running on a node.
* *A cartridge* refers to a package which provides some functionality for an application. For example, A PHP cartridge provides the runtime needed to run PHP based web applications. A MongoDB cartridge provides an instance of a MongoDB database for an application.
* *A Gear* refers to a container in which cartridges are run. Node resources are split amongst the active gears using cgroups, and quotas. Gears are isolated from each other using SELinux, PAM namespaces and bind mounts. A gear can run multiple cartridges for an application.

The [Node module design](file.README.node_module_design.html) document provides a in depth look into how the OpenShift Origin node module is designed.

## The Sources

In the [OpenShift Origin](https://github.com/openshift/origin-server) sources, the [Node package](https://github.com/openshift/origin-server/tree/master/node) contains all the code to manage gears running on the node. The [Node-Util package](https://github.com/openshift/origin-server/tree/master/node-util) contains administration scripts and other utilities that can be used to maintain the node and gears running on it.

## Supplemental documents

* [Building a V1 cartridge](file.README.writing_v1_cartridge.html)
* [Building a V2 cartridge](file.README.writing_cartridges.html)

## Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
