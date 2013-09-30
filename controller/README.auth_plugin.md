# @markup markdown
# @title OpenShift Origin Controller - Authentication Plugin

# OpenShift Origin Controller - Authentication Plugin

The authentication plugin module allows you to plugin in custom authentication backends into OpenShift Origin.

OpenShift Origin currently provides 2 modes of authentication:

  * [Mongo Auth plugin](https://github.com/openshift/origin-server/tree/master/plugins/auth/mongo): A simple authentication plugin which stores usernames and hashed password in Mongo DB.
  * [Remote-user Auth plugin](https://github.com/openshift/origin-server/tree/master/plugins/auth/remote-user): A apache based authentication which allows you to use any apache authentication module with OpenShift. This supports basic user auth and Kerberos based authentication amongst other options.

## Building a new plugin

An OpenShift Authentication plugin is a [Rails Engine](http://guides.rubyonrails.org/engines.html) which includes a library class which extends [OpenShift::AuthService](http://openshift.github.com/origin/broker/OpenShift/AuthService.html). The plugin class must implement either:

  * [authenticate(login, password)](http://openshift.github.com/origin/broker/OpenShift/AuthService.html#authenticate-instance_method). Refer to the [Mongo auth plugin](https://github.com/openshift/origin-server/blob/master/plugins/auth/mongo/lib/openshift/mongo_auth_service.rb#L19) for an example.
  * [authenticate_request(controller)](http://openshift.github.com/origin/broker/OpenShift/AuthService.html#authenticate_request-instance_method). Refer to the [Remote-user plugin](https://github.com/openshift/origin-server/blob/master/plugins/auth/remote-user/lib/openshift/remote_user_auth_service.rb#L6) for an example.
