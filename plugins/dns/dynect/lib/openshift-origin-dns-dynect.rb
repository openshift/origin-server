require "openshift-origin-common"

module OpenShift
  module DynectDnsServiceModule
    require 'dynect_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/dynect_plugin.rb"
OpenShift::DnsService.provider=OpenShift::DynectPlugin
