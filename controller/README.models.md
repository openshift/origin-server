# @markup markdown
# @title OpenShift Origin Data Model

# OpenShift Origin Broker Data Models

The Broker is a stateless application and persists all the state in [MongoDB](http://www.mongodb.org/) database. It uses [MongoID](http://mongoid.org) as an ORM layer to map ruby models to Mongo documents.