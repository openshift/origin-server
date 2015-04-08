require "openshift-origin-common"

module OpenShift
  module CustomDnsModule
    require 'custom_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/custom_dns_plugin.rb"
OpenShift::DnsService.provider=OpenShift::CustomDNSPlugin
