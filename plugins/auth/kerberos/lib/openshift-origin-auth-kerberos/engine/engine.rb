require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class KerberosAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-origin-auth-kerberos/app/controllers"
    paths.lib                  << "lib/openshift-origin-auth-kerberos/lib"
    paths.config               << "lib/openshift-origin-auth-kerberos/config"
    paths.app.models           << "lib/openshift-origin-auth-kerberos/app/models"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
