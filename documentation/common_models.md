# @markup markdown
# @title OpenShift Origin Documentation

# OpenShift Origin Common Models

An OpenShift PaaS installation comprises two logical types of hosts: a broker and one or more nodes. The broker handles the creation and management of user applications, including authenticating users via an authentication service and communication with appropriate nodes. The nodes run the user applications in contained environments called gears. The broker queries and controls nodes using a messaging service.

The [Common package](https://github.com/openshift/origin-server/tree/master/common) contains models and utility classes which are used by both the Broker/Controller and Node packages. This inlcudes models to represent an OpenShift Cartridge.