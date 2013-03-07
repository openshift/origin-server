require "openshift-origin-common"

module OpenShift
  module gss-tsig-DnsModule
    require 'gss-tsig_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/gss-tsig_plugin.rb"
OpenShift::DnsService.provider=OpenShift::gss-tsig-Plugin
