# OpenShift Origin Administrative Console

RubyGem: openshift-origin-admin-console

The OpenShift Origin administrative console enables OpenShift administrators
an at-a-glance view of an OpenShift deployment, in order to
search and navigate OpenShift entities and make reasonable inferences about
adding new capacity.

## Running the Admin Console

The administrative console runs as a plugin to the OpenShift broker application.
The broker application should load it if the gem is installed and its configuration
file is placed at /etc/openshift/plugins.d/openshift-origin-admin-console.conf
(or -dev.conf for specifying development mode settings).

Installing the rubygem-openshift-origin-admin-console RPM should install both
the gem and its configuration file. Restart the openshift-broker service to
have the broker application load the new plugin after installation.

You can build and install the gem from source with:

    $ gem build openshift-origin-admin-console.gemspec
    
      # and then on the broker host...
    $ gem install  --local ./openshift-origin-admin-console-*.gem

You will need to ensure /etc/openshift/plugins.d/openshift-origin-admin-console.conf exists.

## Browsing to the Admin Console

Even when the admin console is included in the broker app, standard broker host
httpd proxy configuration does not allow external access to its URI
(by default /admin-console). This is a security feature to keep from exposing
the console by accident.

In order to access the console, you can either forward the server's port for
local viewing or modify the proxy configuration.

### Port forwarding

You can view the admin console without exposing it externally by forwarding
its port to your local host for viewing with a browser. For instance,

    $ ssh -f user@broker.openshift.example.com -L 8080:localhost:8080 -N

This connects via ssh to user@broker.openshift.example.com and attaches your local
port 8080 (the first number) to the remote server's local port 8080, which is
where the broker application is listening behind the host proxy.

Now just browse to http://localhost:8080/admin-console to view.

### Modifying proxy configuration

To enable external access via the broker host, you will need to configure the
broker host httpd proxy. The relevant configuration file for the broker is
/etc/httpd/conf.d/000002_openshift_origin_broker_proxy.conf inside the
<VirtualHost *:443> section. Add an extra ProxyPass for the admin console
and its static assets (images, etc.) after the existing one for the broker:

    ProxyPass /broker http://127.0.0.1:8080/broker
    ProxyPass /admin-console http://127.0.0.1:8080/admin-console
    ProxyPass /assets http://127.0.0.1:8080/assets
    ProxyPassReverse / http://127.0.0.1:8080/

Then restart the httpd service to load the new configuration.

If you have an OpenShift node installed on your broker host (not advised
for production but often done in development), some extra steps may be
necessary. You may need to add an exception for the /admin-console and
/assets paths in /var/lib/openshift/.httpd.d/nodes.txt and restart httpd.

## Developing / Contributing

We expect code contributions to follow these standards:

1. Ensure code matches the [GitHub Ruby styleguide](https://github.com/styleguide/ruby), except where the file establishes a different standard.
2. Ensure CSS and HTML match the [Bootstrap styleguide](http://mdo.github.com/code-guide/), except where explicitly identified differently.
3. We use Test::Unit with Rails extensions for all our test cases.
4. We try to maintain 100% line coverage of all newly added model and
   controller code via testing.  Coverage reports are generated if
   you have the simplecov gem installed after tests execute via 
   bundle exec rake test.

Once you've made your changes:

1. [Fork](http://help.github.com/forking/) the code
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a [Pull Request](http://help.github.com/pull-requests/) from your branch
5. That's it!

For more details about the console visit the [OpenShift Origin open source
community page](https://www.openshift.com/open-source).

Please stop by #openshift on irc.freenode.net if you have any questions or
comments.  For more information about OpenShift, visit https://www.openshift.com/
or the OpenShift forum
https://www.openshift.com/forums/openshift

