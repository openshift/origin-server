# @markup markdown
# @title How nodes act on behalf of users

# How nodes act on behalf of users

There are a few cases where a Node will actually need to contact the broker. The main cases are:

  * haproxy handling scaling events to create/destroy gears
  * jenkins starting/stopping an application

The install hook for both of those cartridges calls the add_broker_auth_key method defined in the cartridge bash sdk.

In order for this to be done securely OpenShift uses an encrypted auth token that is specific to each gear that is added when the gear is created.  There is never a case where a Node uses some sort of admin account to make calls to the Broker.

## The encrypted token

The actual token is encrypted with a key that is setup by the OpenShift administrator at install time.  The relavant settings are in ```/etc/openshift/broker.conf```.

## How the encrypted token is used

Cartridges that request this token to be create can then use it for authentication to the broker on behalf of the user (since user identifiable information in stored within).

Currently the way the Broker authentication distinguishes normal REST auth with the token auth is handled individually by each plugin.  You can grep for
invocations of ```validate_broker_key```. Right now if the user-agent is "OpenShift" the broker will check the auth token.

This is why the passthrough logic in the remote-user auth plugin works:

    plugins/auth/remote-user/conf/openshift-origin-auth-remote-user-basic.conf.sample