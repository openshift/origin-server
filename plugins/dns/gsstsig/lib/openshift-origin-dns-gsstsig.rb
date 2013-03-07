require "openshift-origin-common"

module OpenShift
  module gsstsigDnsModule
    require 'gsstsig_dns_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/gsstsig_plugin.rb"
OpenShift::DnsService.provider=OpenShift::gsstsigPlugin
