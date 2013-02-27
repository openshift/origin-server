# @markup markdown
# @title OpenShift Origin Documentation

# OpenShift Origin Broker Data Models

An OpenShift PaaS installation comprises two logical types of hosts: a broker and one or more nodes. The broker handles the creation and management of user applications, including authenticating users via an authentication service and communication with appropriate nodes. The nodes run the user applications in contained environments called gears. The broker queries and controls nodes using a messaging service.

The Broker is a stateless application and persists all the state in [MongoDB](http://www.mongodb.org/) database. It uses [MongoID](http://mongoid.org) as an ORM layer to map ruby models to Mongo documents.