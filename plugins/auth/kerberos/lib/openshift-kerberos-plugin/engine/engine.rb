require 'openshift-origin-controller'
require 'rails'

module OpenShift Origin
  class KerberosAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-kerberos-plugin/app/controllers"
    paths.lib                  << "lib/openshift-kerberos-plugin/lib"
    paths.config               << "lib/openshift-kerberos-plugin/config"
    paths.app.models           << "lib/openshift-kerberos-plugin/app/models"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
