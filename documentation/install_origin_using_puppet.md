# @markup markdown
# @title Installing OpenShift Origin using Puppet

# Installing OpenShift Origin using Puppet

This guide will walk you through configuring a basic puppet script to install OpenShift Origin from RPMs.

The OpenShift Origin RPMs can be available from:

* Your local repository [Budinging OpenShift Origin RPMs](file.building_source.html)
* OpenShift Origin nightly mirrors repository.
  + [Fedora 18 repository](https://mirror.openshift.com/pub/origin-server/nightly/fedora-18/latest/x86_64)
  + [RHEL 6.4 repository](https://mirror.openshift.com/pub/origin-server/nightly/rhel-6/latest/x86_64/)

    Note: For OpenShift Origin broker/nodes to be configured properly you will need the host to be
    configured with a DNS resolvable hostname and static IP Address.

## Installing Puppet

You will also need to install the latest puppet and facter RPMS from [PuppetLabs](https://puppetlabs.com/).
Create the following on each host:

File: /etc/yum.repos.d/puppetlabs-products.repo

Contents:

    [puppetlabs-products]
    name=puppetlabs-products
    baseurl=http://yum.puppetlabs.com/fedora/f17/products/x86_64/
    gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
    exclude=mcollective*
    gpgcheck=1
    enabled=1

Run the following to install puppet and facter

    yum install -y puppet facter tar

Install the openshift puppet module:

    puppet module install openshift/openshift_origin

## Generating BIND TSIG Key

Install the BIND package

    yum install -y bind

Generate the TSIG Key

    #Using example.com as the cloud domain
    /usr/sbin/dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom -K /var/named example.com
    cat /var/named/Kexample.com.*.key  | awk '{print $8}'

The TSIG key should look like `CNk+wjszKi9da9nL/1gkMY7H+GuUng==`. We will use this in the following steps.

## Add /etc/hosts entry (optional)

If your machines hostname does not resolve to its public IP address, do the following:

1. Add an entry in `/etc/hosts` mapping the machines hostname to its public IP. Eg:

        127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
        ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
        10.211.55.3 thishost.thisdomain.com

2. Update the `/etc/hostname` file. Eg:

        echo "thishost.thisdomain.com" > /etc/hostname
        hostname thishost.thisdomain.com
  
## Configuring an all-in-one host

In this configuration, the host will run the broker, node, active mq, mongodb and bind servers.

Create a file `configure_origin.pp` with the following contents:

    class { 'openshift_origin' :
      #The DNS resolvable hostname of this host
      node_fqdn                  => "thishost.thisdomain.com",
      
      #The domain under which application should be created. Eg: <app>-<namespace>.example.com
      cloud_domain               => 'example.com',
      
      #Upstream DNS server.
      dns_servers                => ['8.8.8.8'],
      
      enable_network_services    => true,
      configure_firewall         => true,
      configure_ntp              => true,
      
      #Configure the required services
      configure_activemq         => true,
      configure_mongodb          => true,
      configure_named            => true,
      configure_avahi            => false,
      configure_broker           => true,
      configure_node             => true,
      
      #Enable development mode for more verbose logs
      development_mode           => true,
      
      #Update the nameserver on this host to point at Bind server
      update_network_dns_servers => true,
      
      #Use the nsupdate broker plugin to register application
      broker_dns_plugin          => 'nsupdate',
      
      #If installing from a local build, specify the path for Origin RPMs
      #install_repo               => 'file:///root/origin-rpms',
      
      #If using BIND, let the broker know what TSIG key to use
      named_tsig_priv_key         => '<tsig key>'
    }

Execute the puppet script:

    puppet apply --verbose configure_origin.pp

## Configuring seperate hosts for broker/node

### Boker host

In this configuration, the host will run the broker, active mq, mongodb and bind servers.

Create a file `configure_origin.pp` with the following contents:

    class { 'openshift_origin' :
      #The DNS resolvable hostname of this host
      node_fqdn                  => "thishost.thisdomain.com",
      
      #The domain under which application should be created. Eg: <app>-<namespace>.example.com
      cloud_domain               => 'example.com',
      
      #Set to `'nightlies'` to pull from latest nightly build
      #Or pass path of your locally built source `'file:///root/origin-rpms'`
      install_repo               => 'nightlies',
      
      #Upstream DNS server.
      dns_servers                => ['8.8.8.8'],
      
      enable_network_services    => true,
      configure_firewall         => true,
      configure_ntp              => true,
      
      #Configure the required services
      configure_activemq         => true,
      configure_mongodb          => true,
      configure_named            => true,
      configure_avahi            => false,
      configure_broker           => true,
      
      #Don't configure the node
      configure_node             => false,
      
      #Enable development mode for more verbose logs
      development_mode           => true,
      
      #Update the nameserver on this host to point at Bind server
      update_network_dns_servers => true,
      
      #Use the nsupdate broker plugin to register application
      broker_dns_plugin          => 'nsupdate',
      
      #If installing from a local build, specify the path for Origin RPMs
      #install_repo               => 'file:///root/origin-rpms',
      
      #If using BIND, let the broker know what TSIG key to use
      named_tsig_priv_key         => '<tsig key>'
    }

Execute the puppet script:

    puppet apply --verbose configure_origin.pp
    
### node host

In this configuration, the host will run only the node.

Create a file `configure_origin.pp` with the following contents:

    class { 'openshift_origin' :
      #The DNS resolvable hostname of this host
      node_fqdn                  => "thishost.thisdomain.com",
      
      #The domain under which application should be created. Eg: <app>-<namespace>.example.com
      cloud_domain               => 'example.com',
      
      #Set to `'nightlies'` to pull from latest nightly build
      #Or pass path of your locally built source `'file:///root/origin-rpms'`
      install_repo               => 'nightlies',
      
      #Upstream DNS server.
      dns_servers                => ['8.8.8.8'],
      
      enable_network_services    => true,
      configure_firewall         => true,
      configure_ntp              => true,
      
      #Don't configure the broker services
      configure_activemq         => false,
      configure_mongodb          => false,
      configure_named            => false,
      configure_avahi            => false,
      configure_broker           => false,
      
      #Configure the node
      configure_node             => true,
      named_ipaddress            => <IP address of broker machine>,
      mongodb_fqdn               => <FQDN of broker machine>,
      mq_fqdn                    => <FQDN of broker machine>,
      broker_fqdn                => <FQDN of broker machine>,
      
      #Enable development mode for more verbose logs
      development_mode           => true,
      
      #Update the nameserver on this host to point at Bind server
      update_network_dns_servers => true,
      
      #Use the nsupdate broker plugin to register application
      broker_dns_plugin          => 'nsupdate',
      
      #If installing from a local build, specify the path for Origin RPMs
      #install_repo               => 'file:///root/origin-rpms',
    }

Execute the puppet script:

    puppet apply --verbose configure_origin.pp
