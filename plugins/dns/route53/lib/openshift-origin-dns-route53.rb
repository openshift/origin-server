require "openshift-origin-common"

module OpenShift
  module Route53DnsModule
    require 'route53_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/route53_plugin.rb"
OpenShift::DnsService.provider=OpenShift::Route53Plugin
