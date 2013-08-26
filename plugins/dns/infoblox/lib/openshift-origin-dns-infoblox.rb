require "openshift-origin-common"

module OpenShift
  module InfobloxDnsModule
    require 'infoblox_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/infoblox_plugin.rb"
OpenShift::DnsService.provider=OpenShift::InfobloxPlugin
