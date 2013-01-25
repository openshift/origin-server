require "openshift-origin-common"

module OpenShift
  module NsupdateDnsModule
    require 'nsupdate_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/nsupdate_plugin.rb"
OpenShift::DnsService.provider=OpenShift::NsupdatePlugin
