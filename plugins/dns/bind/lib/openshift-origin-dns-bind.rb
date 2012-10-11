require "openshift-origin-common"

module OpenShift
  module BindDnsModule
    require 'openshift-origin-dns-bind/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-dns-bind/lib/openshift/bind_plugin.rb"
OpenShift::DnsService.provider=OpenShift::BindPlugin
