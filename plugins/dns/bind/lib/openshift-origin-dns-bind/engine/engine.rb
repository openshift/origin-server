require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class BindDnsEngine < Rails::Engine
    paths.lib                  << "lib/openshift-origin-bind-dns/lib"
    paths.config               << "lib/openshift-origin-bind-dns/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end