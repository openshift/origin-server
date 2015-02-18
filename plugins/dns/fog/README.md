# OpenShift Origin Dynamic DNS plugin using Fog

This package is a Dynamic DNS plugin for OpenShift Origin.

It allows OpenShift Origin to use cloud DNS services to publish
applications

## Installation and Configuration

* Install package *rubygem-openshift-origin-dns-fog*
* Install package *rubygem-fog* (version >= 1.7.0)
* Add gem *fog* to broker <code>Gemfile</code>

  */var/www/openshift/broker/Gemfile*

     <code>gem 'fog' >= 1.7.0</code>

* Create and update config file:

  *cp /etc/openshift/plugins.d/openshift-origin-dns-fog.conf.example /etc/openshift/plugins.d/openshift-origin-dns-fog.conf*


* Restart broker
  *systemctl restart openshift-broker.service*

## References:

* Fog
  http://fog.io/
