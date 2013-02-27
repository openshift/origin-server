# @markup markdown
# @title OpenShift Origin Documentation

# OpenShift Origin Node

To enable us to share resources, multiple gears run on a single physical or virtual machine. We refer to this machine as a node. Gears are generally over-allocated on nodes since not all applications are active at the same time.

In the [OpenShift Origin](https://github.com/openshift/origin-server) sources, the [Node package](https://github.com/openshift/origin-server/tree/master/node) contains all the code to manage gears running on the node. The [Node-Util package](https://github.com/openshift/origin-server/tree/master/node-util) contains administration scripts and other utilities that can be used to maintain the node and gears running on it.