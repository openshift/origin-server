# @markup markdown
# @title OpenShift Origin Documentation

# OpenShift Origin Broker Data Models

An OpenShift PaaS installation comprises two logical types of hosts: a broker and one or more nodes. The broker handles the creation and management of user applications, including authenticating users via an authentication service and communication with appropriate nodes. The nodes run the user applications in contained environments called gears. The broker queries and controls nodes using a messaging service.

The Broker REST API architecture is based on [HATEOAS](http://en.wikipedia.org/wiki/HATEOAS). All Rest responses contain links to other actions that performed on the resource. The entry point to the API is ```http://<broker host>/broker/rest/api.```