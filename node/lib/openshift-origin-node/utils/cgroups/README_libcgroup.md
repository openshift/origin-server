# @markup markdown
# @title OpenShift Libcgroup implementation

# OpenShift Libcgroup implementation


## Summary

The ::OpenShift::Runtime::Utils::Cgroups::LibCgroup class provides the
low level Cgroups interface via libcgroups.


## Description

The LibCgroup class is used to call commands and edit configuration
files to drive cgroups through the libcgroup interface.

This class is used as an implementation for the Cgroups class and is
intended to be driven through that class.


## Implementation Info

The libcgroup interface assumes that the name of a cgroup is derived
from the Unix username of the gear user.  This symmetry is true of the
selinux application container type but may not be true of other
container types.

Libcgroup settings other than the default are ephemeral.  Gear cgroups
will revert back to the default on a reboot of the node.

