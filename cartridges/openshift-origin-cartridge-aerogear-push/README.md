# OpenShift AeroGear Push Server Cartridge

Provides the _AeroGear UnifiedPush Server_ running on top of JBoss Application Server on OpenShift and embeds the _AeroGear SimplePush Server_ within JBoss Application Server on OpenShift. 

The [AeroGear UnifiedPush Server](https://github.com/aerogear/aerogear-unified-push-server) is a server that allows sending push notifications to different (mobile) platforms. The initial version of the server supports [Apple’s APNs](http://developer.apple.com/library/mac/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW9), [Google Cloud Messaging](http://developer.android.com/google/gcm/index.html) and [Mozilla’s SimplePush](https://wiki.mozilla.org/WebAPI/SimplePush).

The [AeroGear SimplePush Server](https://github.com/aerogear/aerogear-simplepush-server) is a Java server side implementation of Mozilla's [SimplePush Protocol](https://wiki.mozilla.org/WebAPI/SimplePush/Protocol) that describes a JavaScript API and a protocol which allows backend/application developers to send notification messages to their web applications. 

### Installation
The AeroGear Push Server cartridge defaults to using MySQL. When creating your application, you'll also want to add the MySQL cartridge:

```
rhc app create <APP> aerogear-push mysql-5.1
```

### Getting started with the AeroGear UnifiedPush Server

#### Admin UI

Once the server is running access it via ```http://{APP}-{NAMESPACE}-rhcloud.com``` From there you can use the Admin UI. 

**NOTE:** Besides the _Admin UI_, the server can be accessed over RESTful APIs, as explained in the _AeroGear UnifiedPush Server_ [README](https://github.com/aerogear/aerogear-unified-push-server/blob/master/README.md). When executing the curl commands specified, you'll need to replace all instances of ```http://localhost:8080/ag-push``` with your OpenShift application URL ```http://{APP}-{NAMESPACE}-rhcloud.com```. 

#### Login

Temporarily, there is an "admin:123" user.  On _first_ login,  you will need to change the password.

### Getting started with the AeroGear SimplePush Server

#### Client connections

For _secured_ connections, client applications should connect to the _AeroGear SimplePush Server_ via ```https://{APP}-{NAMESPACE}-rhcloud.com:8443/simplepush```.

For _unsecured_ connections, client applications can connect to the _AeroGear SimplePush Server_ via ```http://{APP}-{NAMESPACE}-rhcloud.com:8000/simplepush```.

**NOTE:** It is recommended that you always use _secured_ connections.

#### Known issue with an idled OpenShift application and WebSocket requests

Currently, if your AeroGear Push Server application is [idled by OpenShift](https://www.openshift.com/faq/what-happens-if-my-application-is-not-used-for-a-long-time), attempts to establish a WebSocket connection to the _AeroGear SimplePush Server_ will not wake up your idled application. This is a known issue (see [AEROGEAR-1296](https://issues.jboss.org/browse/AEROGEAR-1296)) and will be fixed in a future release of OpenShift Online. Note that requests to your application on port 80 (i.e., ```http://{APP}-{NAMESPACE}-rhcloud.com```) will wake up your idled application.


### Template Repository Layout

    .openshift/        Location for OpenShift specific files
      action_hooks/    See the Action Hooks documentation [1]
      markers/         See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)


### Environment Variables

The `aerogear-push` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_AEROGEAR_PUSH_IP                         The IP address used to bind JBossAS
    OPENSHIFT_AEROGEAR_PUSH_HTTP_PORT                  The JBossAS listening port
    OPENSHIFT_AEROGEAR_PUSH_TOKEN_KEY                  The token key for the SimplePush Server
    OPENSHIFT_AEROGEAR_PUSH_CLUSTER_PORT               
    OPENSHIFT_AEROGEAR_PUSH_MESSAGING_PORT             
    OPENSHIFT_AEROGEAR_PUSH_MESSAGING_THROUGHPUT_PORT  
    OPENSHIFT_AEROGEAR_PUSH_REMOTING_PORT              
    JAVA_OPTS_EXT                                      Appended to JAVA_OPTS prior to invoking the Java VM

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).

### Markers

Adding marker files to `.openshift/markers` will have the following effects:

    enable_jpda          Will enable the JPDA socket based transport on the java virtual
                         machine running the JBoss AS 7 application server. This enables
                         you to remotely debug code running inside the JBoss AS 7
                         application server.

    java7                Will run JBossAS with Java7 if present. If no marker is present
                         then the baseline Java version will be used (currently Java6)
