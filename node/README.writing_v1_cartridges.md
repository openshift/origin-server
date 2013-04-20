# @markup markdown
# @title Introduction to Building V1 Cartridges

# Introduction to Building V1 Cartridges

##Who this document is for

Users interested in creating cartridges or adding fundamental features to OpenShift should read this document. A “fundamental” feature is hard to define but one example would be the difference between PHP and Wordpress. Wordpress requires PHP to run. It uses the PHP cartridge and in that way, php is a fundamental feature required for wordpress to run. PHP would be a cartridge but wordpress would be an application. Wordpress also needs MySQL to run, so in that scenario PHP and MySQL would both be cartridges but Wordpress (even if one wanted to package it and provide it to others) would not be a cartridge.

Different cartridges will be provided over time, and the definition will evolve as well. But generally speaking, languages and data layer technologies (like Mongo or Mysql) will require a cartridge to function properly. Try to determine for yourself if what you want to do should be considered base infrastructure or if it can utilize existing applications.

Also, this is a new and evolving document, it's written for technical people with experience running Unix and Linux systems. Specifically those with experience with web technologies like Apache. If you are unfamiliar with these systems, this might be a dense read.

##Introduction to Cartridge Building

This document describes the basic purpose of a cartridge as well how to create one. Cartridges are how OpenShift origin adds features to the platform. Before we get too far into the low level features of a cartridge, it's important to understand some terms.

* Cartridge: Configuration templates, scripts, deps required to add a feature to OpenShift.
* Cartridge instantiation: The result of a cartridge feature addition.
* Gear: A container on a host that houses one or more cartridges. Consists of some resources like cpu, disk, etc and a unix user.
* OpenShift Node: A set of utilities used
* Node: A host (for example, a virtual machine) where OpenShift origin apps live.

The basic workflow is this:

* Using oo-app-create, create a gear
* Using the cartridge configure hook, add some feature to the gear.
* Using the cartridge start / stop hooks, start or stop the feature
* Using the cartridge deconfigure hook, remove a feature from the gear.
* Using oo-app-destroy, destroy the gear.

To look at what's going on here at a lower level, oo-app-create will create a unix user (say abcd) and put some basic file configs down in ~abcd/ including some environment variables and basic file permissions.

The configure, say php for example, would then put all of the configuration files, scripts and directory structure in ~abcd/$APP_NAME. Since we're exposing PHP via mod_php and Apache, these files would include the following (and possibly others)

* logs/ for log data
* run/ for pid tracking
* runtime/ (Basically Apache's DocumentRoot)
* sessions/ for php session data
* phplib/ for php libraries and pears
* tmp/ for tmp files
* conf.d/openshift.conf (apache configuration)
* conf/php.ini (php configuration)

Not much magic here, basically the configuration script sets up a little apache “chroot”. It's not really a chroot but users familiar with a chroot can conceptually think of it that way. Apache stays running in its little home dir created by oo-app-create. The user abcd owns all of those files, apache runs as abcd.

Once it's running, the systems' apache (running on port 80) uses ProxyPass and VirtualNameHosting to pass traffic through to the abcd users apache instance.

Before moving on it's important to understand the concepts used above. If you're confused about features like ProxyPass or how a chroot works conceptually, you should google some of those terms. Alternatively you can just create an application on [http://www.openshift.com/](http://www.openshift.com/)  and ssh to your gear like this:

    ssh $UUID@$APPNAME-$DOMAIN.rhcloud.com
    
That way you can poke around yourself and see what it looks like.

##A cartridge

In this example we'll be looking at the PHP cartridge. It's one of the more simple cartridges and is a good reference when building your own. Cartridges are still in a state of flux so it's recommended to copy the PHP cartridge and then adapt it as needed. As cartridges change you can make those same changes to your new cartridge as needed.

###Cartridge Location

The PHP cartridge is stored on the filesystem in /usr/libexec/openshift/cartridges/php-5.3/. In this directory you'll see an info/ where most of the important bits are. Under that info/ directory you'll see:

* bin/ For various scripts related to the php cartridge
* configuration/ for templated configuration files
* connection-hooks/ used to connect different cartridges together
* data/ For larger data storage (a default git repo for example)
* hooks/ For creating and controlling a cartridge instantiation

### The configure hook
Remember that the configure hook assumes you've used oo-app-create to create a gear already. The name or UUID you use with oo-app-create would need to be passed to configure.

The configure hook is the most complex hook in a cartridge and it's mostly likely the first one developers will need to deal with. In it's most basic usage, it takes in three parameters.

* The domain name (the domain part of app-domain.rhcloud.com).
* The application name (the app part of app-domain.rhcloud.com).
* The gear UUID (as specified to your oo-app-create script).

        cd /usr/libexec/openshift/cartridges/php-5.3/info/hooks/
        ./configure myapp mydomain 80288d944ffd40038f17c658ffebb6b8

Once this is run, you should see several files and directories setup in ~80288d944ffd40038f17c658ffebb6b8/ and an httpd process running as that user. It runs fast so don't be surprised if it doesn't seem like it did something. Check the exit code :)

Looking inside the configure script you'll see several steps including many that have been abstracted. create_standard_env_vars for example. Many of these are provided by the abstract and abstract-httpd directories. It turns out that to create a php app or python or ruby app, many of the same steps can be taken. Certainly starting apache isn't different from one to the other. That's why many of the hooks in our php directory are symlinks. We'll get to the other hooks later.

In the case of PHP, it's the configure hook's job to take care of the following tasks.

* Create an populate the php home directory
* Create a sample “hello world” git repo and populate it.
* Put down all base files, configurations, log locations, etc required for apache to run
* Ensure permissions are correct
* Place ~/.env/ files down so new environment variables are ready to be used by processes
* Define what the different build/deploy/etc steps are for when users push new code
* Put the reverse proxy configs in place so the system apache process can contact the backend apache process
* Finally, start the application and exit.

This turns out to be a lot of work, but at the end of the day it just needs to start apache, bind on port 8080 on some loopback IP and point the system apache at the application instance via a ProxyPass. It would look like this:

Browser -> System Proxy:80 -> ProxyPass -> php application:8080

It's really that simple.

### Other Hooks

The list of hooks is evolving as well, OpenShift is fairly new and hooks are how we interact with features. As new behaviors are needed, we need to add new hooks. The below list is not exhaustive (look at the cartridge yourself for the full list) but this is a taste of what hooks are out there and what they do. Hook names tend to be the same across cartridges.

* add/remove-alias – Adds a www.example.com VirtualNameHost alias to an application
* start/stop/restart/reload – Exactly what you'd think. Starts or stops your applications
* force-stop – kill -9 all running applications for a specific user (useful if an app hangs or gets wedged)
* tidy – Runs a git garbage collection, deletes old logs, cleans up temp directories in an effort to free up disk space
* expose/conceal-port – Used to expose a cartridge port so it can be connected to by cartridges on another node.
* update-namespace – Used to change the domain part of app-domain.rhcloud.com
* preconfigure – runs before configure does to set some bits up.
* deconfigure – Destroys an application.

The cartridges can also send special messages back to the caller (normally our broker code) to make changes to other gears or send data back to the user. For example:

* ENV_VAR_ADD: key=value – This would cause all gears in a domain to get the same key set to value.
* CLIENT_ERROR: error message – This would cause the broker to pass specific error messages back to the user
* CLIENT_MESSAGE: send a message back to the user

### Connection hooks

Connection hooks are used to 'connect' two cartridges together. Really this just means make sure two different cartridges are talking to each other. For example, if you've got a php app on one gear, and a mysql app on another gear. The mysql cartridge would have a “publish-db-connection-info” connection hook and the php cartridge could have a 'set-db-connection-info' hook. Publish-db-connection-info could simply print 'mysql://user:password@mydb.rhcloud.com/mydata' and the set-db-connection-info might take that output and place it in an ~/.env/OPENSHIFT_DB_INFO to be consumed by the user.

### Template

There is an info/template directory in many cartridges. This “template” is mostly what comprises of the default git repo when configure is called. Items in this directory will get cloned onto the users machine and thus should include a working example, something like “hello world” is fine. But also some of the basic features like the .openshift/action_hooks/ directory (for builds, etc). As well as useful README files.

### Quickstart

Here are the steps to start with an existing cartridge.

    yum install tito #as root
    git clone https://github.com/openshift/origin-server.git
    cd origin-server/cartridges
    cp -r diy-0.1 customcart-0.1
    cd customcart-0.1
    mv cartridge-diy-0.1.spec cartridge-customcart-0.1.spec
    grep -r diy *
    # modify diy to customcart
    git add . and git commit -m "New cartridge"
    tito init
    tito tag
    tito build --rpm --test
    rpm -ivh /tmp/tito/noarch/cartridge-customcart-0.1-* 
    rm -rf /var/www/openshift/broker/tmp/cache/*

    # Update cartridges/openshift-origin-cartridge-abstract/abstract/info/bin/util with your cartridge
    # Update node-util/bin/oo-idler-stats with your cartridge

    # Restart mcollective
    service mcollective restart

    # Clear the broker cache
    rm -rf /var/www/openshift/broker/tmp/cache/*
    service openshift-broker restart
    
    rhc app create myapp customcart-0.1 -ladmin -padmin

Now start making changes to the hooks to make it do what you want!