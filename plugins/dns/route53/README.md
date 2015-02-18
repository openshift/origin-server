# OpenShift Origin Dynamic DNS plugin for Amazon Web Services Route 53

This package is a Dynamic DNS plugin for OpenShift Origin.

It allows OpenShift Origin to use AWS Route53 DNS services to publish
applications

## Installation and Configuration

* Install package *rubygem-openshift-origin-dns-route53*
* Install package *rubygem-aws-sdk* (version >= 1.8.0)
* Add gem *aws-sdk* to broker <code>Gemfile</code>

  */var/www/openshift/broker/Gemfile*

     <code>gem 'aws-sdk' >= 1.8.0</code>
     
* Create config file:

  */etc/openshift/plugins.d/openshift-origin-dns-route53.conf*
 
<code><pre>
    # Settings related to the Amazon Web Services Route53 DNS service
    # The AWS zone identifier
    AWS_HOSTED_ZONE_ID="/hostedzone/YOURZONEID"
    #
    # AWS Access credentials
    AWS_ACCESS_KEY_ID="YOURKEYID"
    AWS_SECRET_KEY="YOURSECRETKEY"
</pre></code>

* Install package *rubygem-aws-sdk* (version >= 1.8.0)
* Check gems using <code>cd /var/log/bundle --local</code>
* Verify service with <code>rails console</code>

## References:

* AWS SDK for Ruby
  http://aws.amazon.com/sdkforruby/

* AWS Route 53 Developer Guide
  http://docs.aws.amazon.com/Route53/latest/DeveloperGuide

* AWS Route 53 API Reference
  http://docs.aws.amazon.com/Route53/latest/APIReference
 
