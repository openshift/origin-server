require "openshift-origin-common"

module OpenShift
  module AvahiDnsModule
    require 'avahi_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/avahi_plugin.rb"
OpenShift::DnsService.provider=OpenShift::AvahiPlugin
