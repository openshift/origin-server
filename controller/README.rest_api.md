# @markup markdown
# @title OpenShift Origin REST API documentation

# OpenShift Origin REST API documentation

The Broker REST API architecture is based on [HATEOAS](http://en.wikipedia.org/wiki/HATEOAS). All Rest responses contain links to other actions that performed on the resource. The entry point to the API is ```http://<broker host>/broker/rest/api.```