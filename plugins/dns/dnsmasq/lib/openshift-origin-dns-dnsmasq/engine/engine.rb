require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class DnsmasqDnsEngine < Rails::Engine
    paths.lib                  << "lib/openshift-origin-dns-dnsmasq/lib"
    paths.config               << "lib/openshift-origin-dns-dnsmasq/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
