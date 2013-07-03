# @markup markdown
# @title Scaling in OpenShift

# Scaling in OpenShift

The first thing to know about scaling in OpenShift is that it is implemented using haproxy.  The best technical document on how this is done can be found in the [haproxy cartridge README](https://github.com/openshift/origin-server/blob/master/cartridges/openshift-origin-cartridge-haproxy/README).

You should definitely read that document before continuing further.

## Overview of the moving parts

It's important to understand that the decision to scale and application or not is made at application creation time.  This is because the haproxy cartridge is embedded into the framework cartridge you are trying to scale at application creation time.

You can take a look in ```controller/app/models/application.rb``` at how ```template_scalable_app``` is called when new applications are created. Today haproxy is configured as a proxy component for the first gear in all scalable
applications.  If you wanted to add another type of scaling to OpenShift this code would have to be modified.

Once the application is running the scale_events.log is monitored by ```haproxy_ctld```.  The details of autoscale is best covered in the haproxy cartridge README file.  However the ultimately ```haproxy_ctld```'s ```add_gear``` method is called which effectively calls the add-gear script and eventually reaches [app_events_controller.rb](https://github.com/openshift/origin-server/blob/master/controller/app/controllers/app_events_controller.rb).

In order for add-gear to work the node has to make a connection to the broker on behalf of the user.  This is done with encrypted token authentication. Whenever an haproxy cartridge is embedded a broker auth token will be created in the gear.  For more details see [How nodes act on behalf of users](file.how_nodes_act_on_behalf_of_users.html).

## Scaling up

The process of scaling up entails a few things:

* A DNS entry is created for the newly created gear.  It will be in the form of:

        $RANDOM_IDENTIFIER-$USERS_NAMESPACE.$CLOUD_DOMAIN

  For example, ```868b21e893-mydomain.example.com```.
  
  This is done in [gear.rb](https://github.com/openshift/origin-server/blob/master/controller/app/models/gear.rb#L87)
  
* The logic in [application.rb](https://github.com/openshift/origin-server/blob/master/controller/app/models/application.rb) handles copying the settings for the original gear to the newly created gear.  This includes things like the user's environment variables and the various ssh keys in OpenShift.

* The ```set-proxy``` connection hook is called when the connector-execute message is sent from the broker to update the haproxy configuration for the scaling gear.

## The gear registry

The haproxy maintains a gear registry for quickly keeping track of what gears have been created for a user as part of scaling.  One thing to note is that we use IP addresses for loadbalancing in OpenShift because we can't always depend on DNS resolving in time while scaling up.  Because of this we have to have some way to fix things when the addresses change.

```haproxy_ctld``` handles this in the ```repair_configuration``` method.  It will check the registry's hostname and do a DNS lookup to see if anything has changed.