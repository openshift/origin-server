# @markup markdown
# @title OpenShift Origin Documentation

# OpenShift Origin Broker And Controller

An OpenShift PaaS installation comprises two logical types of hosts: a broker and one or more nodes. The broker handles the creation and management of user applications, including authenticating users via an authentication service and communication with appropriate nodes. The nodes run the user applications in contained environments called gears. The broker queries and controls nodes using a messaging service.

In the [OpenShift Origin](https://github.com/openshift/origin-server) sources, the [Broker package](https://github.com/openshift/origin-server/tree/master/broker) is a simple Rails application which loads configuration and all the logic is provided by the [Controller](https://github.com/openshift/origin-server/tree/master/controller) Rails engine.