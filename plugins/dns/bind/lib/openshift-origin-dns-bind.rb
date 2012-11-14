require "openshift-origin-common"

module OpenShift
  module BindDnsModule
    require 'bind_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/bind_plugin.rb"
OpenShift::DnsService.provider=OpenShift::BindPlugin
