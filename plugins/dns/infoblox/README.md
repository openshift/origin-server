# Openshift Origin Dynamic DNS plugin for Infoblox

This package is a Dynamic DNS plugin for OpenShift Origin.

It allows OpenShift Origin to use Infoblox DNS services to publish applications

* http://www.infoblox.com
* http://www.infoblox.com/community/content/getting-started-infoblox-web-api-wapi

It uses the Infoblox REST API version N.N

## Installation and Configuration

* Install package *rubygem-openshift-origin-dns-infoblox*

Requires rubygem-json and rubygem-rest-client
     
* Create config file:

  */etc/openshift/plugins.d/openshift-origin-dns-infoblox.conf*
 
<code><pre>
    # Settings related to the Amazon Web Services Route53 DNS service
    # The AWS zone identifier
    INFOBLOX_SERVER="hostname or IP address"
    #
    # AWS Access credentials
    INFOBLOX_USERNAME=""
    INFOBLOX_PASSWORD=""
</pre></code>

* Check gems using <code>cd /var/log/bundle --local</code>
* Verify service with <code>rails console</code>

## References:

* InfoBlox corporate web site.
  http://www.infoblox.com
* Introduction to Infoblox WEB/REST API 
  http://www.infoblox.com/community/content/getting-started-infoblox-web-api-wapi