require "openshift-origin-common"

module OpenShift
  module FogDnsModule
    require 'fog_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/fog_plugin.rb"
OpenShift::DnsService.provider=OpenShift::FogPlugin
