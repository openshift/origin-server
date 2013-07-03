# @markup markdown
# @title Installing OpenShift Origin Manually

# Installing OpenShift Origin Manually

This document describes how to create a private PaaS service using OpenShift. It makes a number of simplifying assumptions about the environment of the service. In particular, we will assume that the underlying platform is Fedora 19 with Ruby 1.9. You may have to adjust the configuration for a different environment.

The document is organized into two. The first part will take the reader, step-by-step, through the process of installing and configuring a broker and one or more nodes. And, the second part will explain and demonstrate the operation of the new installation using the rhc tool.

## Part I: Installation and Configuration

The instructions in this section describe how to install and configure a basic OpenShift PaaS environment with a broker and one or more nodes. These instructions are intended for Linux administrators and developers with intermediate level experience. They are extremely detailed in order to demonstrate the variety of settings you may configure and where to do so.

    In the following steps, it is recommended that you back up any files that you change by running (for example) 
    cp foo foo.orig #before editing the file foo

### Preliminary Information

Before proceeding with the installation and configuration, this section provides some basic information and requirements for installing OpenShift PaaS.

### Supported Operating Systems

This installation relies on a current Fedora 19 installation as its base. We recommend installing the "Basic Server" configuration for a base install, though others should work too.

### Hardware Requirements

Although the instructions in this document have been primarily tested on KVM virtual machines, the instructions are applicable to other environments.

Below are the hardware requirements for all hosts, whether configured as a broker or as a node. The hardware requirements are applicable for both physical and virtual environments.

Minimum 1 GB of memory
Minimum 8 GB of hard disk space
x86_64 architecture
Network connectivity (Preferibly static IPs)

### Service Parameters
In this example of a basic OpenShift installation, the broker and node are configured with the following parameters:

Service Domain: `example.com`
Broker IP address: dynamic (from DHCP)
Broker host name: `broker.example.com`

Node 0 IP address: dynamic (from DHCP)
Node 0 host name: `node.example.com`

Data Store Service: MongoDB
Authentication Service: Basic Authentication via httpd `mod_auth_basic`
DNS Service: `BIND`
IP address: dynamic (from DHCP)
Zone: example.com (same as Service Domain)
Domain Suffix: `example.com` (same as Service Domain)

Messaging Service: MCollective using ActiveMQ

All of these parameters can be customized as necessary. As detailed in the instructions, the domain name and host names can be easily modified by editing appropriate configuration files. The selection of data-store service, authentication service, and DNS server are implemented as plug-ins to the broker.

Note that while DHCP is supported and assumed in this document, dynamic re-assignment of IP addresses is not supported and may cause problems.

### DNS Information

The OpenShift PaaS service publishes the host names of new applications to DNS. The DNS update service negotiates with the owner of a domain so that a sub domain can be allocated. It also establishes authentication credentials to allow automatic updates. The sample configuration uses a private DNS service to allow the OpenShift PaaS service to publish new host names without requiring access to an official DNS service. The application host names will only be visible on the OpenShift PaaS hosts and any workstation configured to use the configured DNS service, unless properly delegated by a public DNS service.

The creation of a private DNS service and establishing a delegation agreement with your IT department are outside the scope of this document. Each organization has its own policies and procedures for managing DNS services. If you want to make the OpenShift PaaS service available in any way, you will have to discuss the delegation requirements at your site with the appropriate personnel.

### Puppet based installation

For your convenience, a [puppet based installed](file.install_origin_using_puppet.html) script for configuring a host as a broker or as a node (or as both) is available.

The steps in this document explain the actions of the puppet recipe. The steps and the script are independent in the sense that you can obtain a complete broker or node host just by following the steps manually or just by running the kickstart script. For your convenience, we will point to the corresponding part of the puppet recipe for each section in the steps below.

### Setting up Time Synchronization

OpenShift requires NTP to synchronize the system and hardware clocks. This synchronization is necessary for communication between the broker and node hosts; if the clocks are too far out of synchronization, MCollective will drop messages. It is also helpful to have accurate timestamps on files and in log file entries.

On the host, use the ntpdate command to set the system clock (use whatever NTP servers are appropriate for your environment):

    ntpdate clock.redhat.com

You will also want to configure ntpd via /etc/ntp.conf to keep the clock synchronized during operation.

If you get the error message "the NTP socket is in use, exiting," then ntpd is already running, but the clock may not be synchronized if it starts too far off. You should stop the service while executing this command.

    service ntpd stop
    ntpdate clock.redhat.com
    service ntpd start

If you are installing on physical hardware, use the hwclock command to synchronize the hardware clock to the system clock. If you are running on a virtual machine, such as an Amazon EC2 instance, skip this step. Otherwise, enter the following command:

    hwclock --systohc

    Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/ntpd.pp

### Enabling Remote Administration

It may be desirable to install SSH keys for the root user so that you can interact with the hosts remotely from your personal workstation. First, ensure that root's ssh configuration directory exists and has the correct permissions on the host:

    mkdir /root/.ssh
    chmod 700 /root/.ssh

On your workstation, you can either use the ssh-keygen command to generate a new keypair, or use an existing public key. In either case, edit the */root/.ssh/authorized_keys* file on the host and append the public key, or use the ssh-copy-id command to do the same. For example, on your local workstation, you can issue the following command:

    ssh-copy-id root@10.0.0.1

Replace "10.0.0.1" with the actual IP address of the broker in the above command.

### Setting up Host 1 as a Broker with Related Components

This section describes how to install and configure the first OpenShift host, which will be running the Broker, MongoDB, ActiveMQ, and BIND. Each logical component is broken out into an individual section.

You should perform all of the procedures in this section after you have installed and configured the base operating system and before you start installing and configuring any node hosts.

#### Setting up the Required Repositories

OpenShift Origin currently relies on many packages that are not in Fedora and must be retrieved from OpenShift repositories.

##### OpenShift Origin Dependencies

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/init.pp#L265

File: /etc/yum.repos.d/openshift-origin-deps.repo

Contents:

    [openshift-origin-deps]
    name=openshift-origin-deps
    baseurl=https://mirror.openshift.com/pub/openshift-origin/fedora-19/$basearch/
    gpgcheck=0
    enabled=1

##### OpenShift Origin RPMs

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/init.pp#L278

File: /etc/yum.repos.d/openshift-origin.repo

Contents:

    [openshift-origin]
    name=openshift-origin
    baseurl=https://mirror.openshift.com/pub/openshift-origin/nightly/fedora-19/latest/$basearch/
    gpgcheck=0
    enabled=1

##### Jenkins

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/node.pp#L362

File: /etc/yum.repos.d/jenkins.repo

Contents:

    [jenkins]
    name=jenkins
    baseurl=http://pkg.jenkins-ci.org/redhat
    gpgcheck=1
    enabled=1

Import repository key:

    rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

*RUNNING YUM UPDATE*

To update all of the base packages needed for these instructions, run the following command.

    yum update
    
It is important to do this to ensure at least the selinux-policy package is updated, as OpenShift relies on a recent update to this package.

#### Setting up BIND / DNS

In this section, we will configure BIND on the broker. Skip this section if you have alternative arrangements for handling DNS updates from OpenShift.
If you wish to have OpenShift update an existing BIND server in your infrastructure, it should be fairly apparent from the ensuing setup how to enable that. If you are using something different, the DNS update plugin can be swapped out.

*INSTALLING*

To install all of the packages needed for these instructions, run the following command.

    yum install bind bind-utils

*CONFIGURING*

We will be referring frequently to the domain name with which we are configuring this OpenShift installation, so let us set the $domain environment variable for easy reference:

    domain=example.com

Note: You may replace "example.com" with the domain name you have chosen for this installation of OpenShift.

Next, set the `$keyfile` environment variable to contain the filename for a new DNSSEC key for our domain (we will create this key shortly):

    keyfile=/var/named/${domain}.key

We will use the dnssec-keygen tool to generate the new DNSSEC key for the domain. Run the following commands to delete any old keys and generate a new key:

    rm -vf /var/named/K${domain}*
    pushd /var/named
    dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${domain}
    KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"
    popd

Notice that we have set the $KEY environment variable to hold the newly generated key. We will use this key in a later step.

Next, we must ensure we have a key for the broker to communicate with BIND. We use the rndc-confgen command to generate the appropriate configuration files for rndc, which is the tool that the broker will use to perform this communication.

    rndc-confgen -a -r /dev/urandom

We must ensure that the ownership, permissions, and SELinux context are set appropriately for this new key:

    restorecon -v /etc/rndc.* /etc/named.*
    chown -v root:named /etc/rndc.key
    chmod -v 640 /etc/rndc.key

We are configuring the local BIND instance so that the broker and nodes will be able to resolve internal hostnames. However, the broker and node will still need to be able to handle requests to resolve hostnames on the broader Internet. To this end, we configure BIND to forward such requests to regular DNS servers. To this end, create the file `/var/named/forwarders.conf` with the following content:

    forwarders { 8.8.8.8; 8.8.4.4; } ;

Note: Change the above list of forwarders as appropriate to comply with your local network's requirements.

Again, we must ensure that the permissions and SELinux context are set appropriately for the new forwarders.conf file:

    restorecon -v /var/named/forwarders.conf
    chmod -v 755 /var/named/forwarders.conf

We need to configure BIND to perform resolution for hostnames under the domain we are using for our OpenShift installation. To that end, we must create a database for the domain. The dns-bind plug-in includes an example database, which we will use as a template. Delete and create the `/var/named/dynamic` directory:

    rm -rvf /var/named/dynamic
    mkdir -vp /var/named/dynamic

Now, create an initial named database in a new file named `/var/named/dynamic/${domain}.db` (where `${domain}` is your chosen domain) using the following command (if the shell syntax is unfamiliar, see the [BASH documentation on heredocs](http://www.gnu.org/software/bash/manual/bashref.html#Here-Documents) ):

    cat <<EOF > /var/named/dynamic/${domain}.db
    \$ORIGIN .
    \$TTL 1	; 1 seconds (for testing only)
    ${domain} IN SOA ns1.${domain}. hostmaster.${domain}. (
                             2011112904 ; serial
                             60         ; refresh (1 minute)
                             15         ; retry (15 seconds)
                             1800       ; expire (30 minutes)
                             10         ; minimum (10 seconds)
                              )
                         NS ns1.${domain}.
    \$ORIGIN ${domain}.
    ns1	              A        127.0.0.1
    
    EOF

Next, we install the DNSSEC key for our domain. Create the file `/var/named/${domain}.key` (where `${domain}` is your chosen domain) using the following command:

    cat <<EOF > /var/named/${domain}.key
    key ${domain} {
      algorithm HMAC-MD5;
      secret "${KEY}";
    };
    EOF

We need to set the permissions and SELinux contexts appropriately:

    chown -Rv named:named /var/named
    restorecon -rv /var/named

We must also create a new `/etc/named.conf` file, as follows:

    cat <<EOF > /etc/named.conf
    // named.conf
    //
    // Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
    // server as a caching only nameserver (as a localhost DNS resolver only).
    //
    // See /usr/share/doc/bind*/sample/ for example named configuration files.
    //
    
    options {
        listen-on port 53 { any; };
        directory "/var/named";
        dump-file "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query { any; };
        recursion yes;
    
        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.iscdlv.key";
    
        // set forwarding to the next nearest server (from DHCP response
        forward only;
        include "forwarders.conf";
    };
    
    logging {
        channel default_debug {
            file "data/named.run";
            severity dynamic;
        };
    };
    
    // use the default rndc key
    include "/etc/rndc.key";
     
    controls {
        inet 127.0.0.1 port 953
        allow { 127.0.0.1; } keys { "rndc-key"; };
    };
    
    include "/etc/named.rfc1912.zones";
    
    include "${domain}.key";
    
    zone "${domain}" IN {
        type master;
        file "dynamic/${domain}.db";
        allow-update { key ${domain} ; } ;
    };
    EOF

Set permissions and SELinux contexts appropriately:

    chown -v root:named /etc/named.conf
    restorecon /etc/named.conf

Configuring Host 1 Name Resolution

To use the local named service to resolve host names in your domain, you now need to update the host's `/etc/resolv.conf` file. You also need to configure the firewall and start the named service in order to serve local and remote DNS requests for the domain.

To that end, edit `/etc/resolv.conf` and put the following at the top of the file, changing "10.0.0.1" to the IP address of Host 1::

    nameserver 10.0.0.1

Open the firewall rules and make the service restart on reboot with:

    lokkit --service=dns
    chkconfig named on

Use the service command to start BIND ("named") so we can perform some updates immediately:

    service named start

Tell BIND about the broker using the nsupdate command to open an interactive session. "server," "update," and "send" are commands to the nsupdate command. CTRL+D closes the interactive session.

    Note: Replace "broker.example.com" with the actual FQDN of the broker, and replace "10.0.0.1" with the actual IP address of the broker.

    nsupdate -k ${keyfile}
    server 127.0.0.1
    update delete broker.example.com A
    update add broker.example.com 180 A 10.0.0.1
    send
    quit

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/named.pp

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/init.pp#L446

*VERIFYING*

Verify that BIND is configured correctly to resolve the broker's hostname:

    dig @127.0.0.1 broker.example.com

Verify that BIND properly forwards requests for other hostnames:

    dig @127.0.0.1 icann.org a

Verify that the broker is using the local BIND instance by running the following command on the broker:

    dig broker.example.com

#### Setting up MongoDB

MongoDB requires several minor configuration changes to prepare it for use with OpenShift. These include setting up authentication, specifying the default database size, and creating an administrative user.

*INSTALLING*

To install all of the packages needed for MongoDB, run the following command:

    yum install mongodb-server

*CONFIGURING*

To configure MongoDB to require authentication:

Open the `/etc/mongodb.conf` file. Add the following line anywhere in the file:

    auth = true

If there are any other lines beginning with "auth =", delete those lines.
Save and close the file.
To configure the MongoDB default database size:

Open the `/etc/mongodb.conf` file. Add the following line anywhere in the file:

    smallfiles = true

If there are any other lines beginning with "smallfiles =", delete those lines.
Save and close the file.

Open the firewall rules and make the service restart on reboot with:

    chkconfig mongod on

Now start the mongo daemon:

    service mongod start

Ref: https://github.com/openshift/puppet-openshift_origin/blob/master/manifests/mongo.pp

*VERIFYING*

Run the mongo command to ensure that you can connect to the MongoDB database:

    mongo

The command starts an interactive session with the database. Press CTRL+D (the Control key with the "d" key) to leave this session and return to the command shell.

#### Setting up ActiveMQ

You need to install and configure ActiveMQ which will be used as the messaging platform to aid in communication between the broker and node hosts.

*INSTALLING*

To install the packages needed for ActiveMQ, run the following command:

    yum install activemq

*CONFIGURING*

You can configure ActiveMQ by editing the `/etc/activemq/activemq.xml` file. Create the file using the following command:

    cat <<EOF > /etc/activemq/activemq.xml
    <!--
        Licensed to the Apache Software Foundation (ASF) under one or more
        contributor license agreements.  See the NOTICE file distributed with
        this work for additional information regarding copyright ownership.
        The ASF licenses this file to You under the Apache License, Version 2.0
        (the "License"); you may not use this file except in compliance with
        the License.  You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
    -->
    <beans
      xmlns="http://www.springframework.org/schema/beans"
      xmlns:amq="http://activemq.apache.org/schema/core"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
      http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd">
    
        <!-- Allows us to use system properties as variables in this configuration file -->
        <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
            <property name="locations">
                <value>file:\${activemq.conf}/credentials.properties</value>
            </property>
        </bean>
    
        <!--
            The <broker> element is used to configure the ActiveMQ broker.
        -->
        <broker xmlns="http://activemq.apache.org/schema/core" brokerName="broker.example.com" dataDirectory="\${activemq.data}">
    
            <!--
                For better performances use VM cursor and small memory limit.
                For more information, see:
    
                http://activemq.apache.org/message-cursors.html
    
                Also, if your producer is "hanging", it's probably due to producer flow control.
                For more information, see:
                http://activemq.apache.org/producer-flow-control.html
            -->
    
            <destinationPolicy>
                <policyMap>
                  <policyEntries>
                    <policyEntry topic=">" producerFlowControl="true" memoryLimit="1mb">
                      <pendingSubscriberPolicy>
                        <vmCursor />
                      </pendingSubscriberPolicy>
                    </policyEntry>
                    <policyEntry queue=">" producerFlowControl="true" memoryLimit="1mb">
                      <!-- Use VM cursor for better latency
                           For more information, see:
    
                           http://activemq.apache.org/message-cursors.html
    
                      <pendingQueuePolicy>
                        <vmQueueCursor/>
                      </pendingQueuePolicy>
                      -->
                    </policyEntry>
                  </policyEntries>
                </policyMap>
            </destinationPolicy>
    
    
            <!--
                The managementContext is used to configure how ActiveMQ is exposed in
                JMX. By default, ActiveMQ uses the MBean server that is started by
                the JVM. For more information, see:
    
                http://activemq.apache.org/jmx.html
            -->
            <managementContext>
                <managementContext createConnector="false"/>
            </managementContext>
    
            <!--
                Configure message persistence for the broker. The default persistence
                mechanism is the KahaDB store (identified by the kahaDB tag).
                For more information, see:
    
                http://activemq.apache.org/persistence.html
            -->
            <persistenceAdapter>
                <kahaDB directory="\${activemq.data}/kahadb"/>
            </persistenceAdapter>
    
            <!-- add users for mcollective -->
    
            <plugins>
              <statisticsBrokerPlugin/>
              <simpleAuthenticationPlugin>
                 <users>
                   <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
                   <authenticationUser username="admin" password="secret" groups="mcollective,admin,everyone"/>
                 </users>
              </simpleAuthenticationPlugin>
              <authorizationPlugin>
                <map>
                  <authorizationMap>
                    <authorizationEntries>
                      <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
                      <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />
                      <authorizationEntry topic="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                      <authorizationEntry queue="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                      <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
                    </authorizationEntries>
                  </authorizationMap>
                </map>
              </authorizationPlugin>
            </plugins>
    
              <!--
                The systemUsage controls the maximum amount of space the broker will
                use before slowing down producers. For more information, see:
                http://activemq.apache.org/producer-flow-control.html
                If using ActiveMQ embedded - the following limits could safely be used:
    
            <systemUsage>
                <systemUsage>
                    <memoryUsage>
                        <memoryUsage limit="20 mb"/>
                    </memoryUsage>
                    <storeUsage>
                        <storeUsage limit="1 gb"/>
                    </storeUsage>
                    <tempUsage>
                        <tempUsage limit="100 mb"/>
                    </tempUsage>
                </systemUsage>
            </systemUsage>
            -->
              <systemUsage>
                <systemUsage>
                    <memoryUsage>
                        <memoryUsage limit="64 mb"/>
                    </memoryUsage>
                    <storeUsage>
                        <storeUsage limit="100 gb"/>
                    </storeUsage>
                    <tempUsage>
                        <tempUsage limit="50 gb"/>
                    </tempUsage>
                </systemUsage>
            </systemUsage>
    
            <!--
                The transport connectors expose ActiveMQ over a given protocol to
                clients and other brokers. For more information, see:
    
                http://activemq.apache.org/configuring-transports.html
            -->
            <transportConnectors>
                <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
                <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>
            </transportConnectors>
    
        </broker>
    
        <!--
            Enable web consoles, REST and Ajax APIs and demos
    
            Take a look at \${ACTIVEMQ_HOME}/conf/jetty.xml for more details
        -->
        <import resource="jetty.xml"/>
    
    </beans>
    <!-- END SNIPPET: example -->
    EOF

Note: Replace "broker.example.com" with the actual FQDN of the broker. You are also encouraged to substitute your own passwords (and use the same in the MCollective configuration that follows).

Open the firewall rules and make the service restart on reboot with:

    lokkit --port=61613:tcp
    chkconfig activemq on
    
Now start the activemq service with:

    service activemq start