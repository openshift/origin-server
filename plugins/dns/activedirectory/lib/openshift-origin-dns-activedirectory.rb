require "openshift-origin-common"

module OpenShift
  module ActiveDirectoryDnsModule
    require 'activedirectory_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/activedirectory_plugin.rb"
OpenShift::DnsService.provider=OpenShift::ActiveDirectoryPlugin
